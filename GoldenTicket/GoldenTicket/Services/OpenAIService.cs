using OpenAI;
using OpenAI.Chat;
using System.ClientModel;
using TiktokenSharp;
using GoldenTicket.Services;
using GoldenTicket.Models;
using GoldenTicket.Database;
using GoldenTicket.Utilities;
using GoldenTicket.Entities;
using Microsoft.EntityFrameworkCore;

namespace OpenAIApp.Services;

public class OpenAIService
{
    private ChatClient? _client;
    private ApiKeyCredential? _apiCredential;
    private OpenAIClientOptions _options;
    private APIKeyDTO? _currentKey;
    private Dictionary<string, int> _apiKeyIndex = new();
    private Dictionary<string, int> _loopAmount = new();
    private readonly Dictionary<string, List<ChatMessage>> clientMessages = new(); // Per-client storage
    private readonly ILogger<OpenAIService> _logger;
    private readonly ApiConfig _apiConfig;
    private readonly Dictionary<string, int> clientTokenUsage = new();
    private readonly float _temperature;
    private readonly int _maxOutputTokenCount;
    public static bool debug = false;
    public static int TokenCountUsed { get; private set; } = 0;
    public static int TotalCharactersUsed { get; private set; } = 0;

    public OpenAIService(ConfigService config, ILogger<OpenAIService> logger, ApiConfig apiConfig)
    {
        _logger = logger;
        _apiConfig = apiConfig;
        string baseUrl = config.OpenAISettings.BaseUrl;

        _temperature = config.OpenAISettings.Temperature;
        _maxOutputTokenCount = config.OpenAISettings.MaxOutputTokenCount;

        _options = new OpenAIClientOptions()
        {
            Endpoint = new Uri(baseUrl)
        };

        _logger.LogInformation("[OpenAIService] Using Base URL: {BaseUrl}", baseUrl);
        Initialize();
        PopulateMessages();
    }

    public async void Initialize()
    {
        if (_client == null || _apiCredential == null)
        {
            _currentKey = await _apiConfig.GetLeastUsedAPI() ?? null;
            _apiCredential = new ApiKeyCredential("Bearer " + _currentKey?.APIKey);
            _client = new ChatClient("gpt-4o", _apiCredential, _options);
        }
    }

    public async Task<string> GetAIResponse(string chatroomID, string userInput, string Prompt, bool isDirect = false)
    {
        
        if (!clientMessages.ContainsKey(chatroomID))
        {
            clientMessages[chatroomID] = new List<ChatMessage>(); // Initialize storage for this client
        }
        if (!_loopAmount.ContainsKey(chatroomID))
        {
            _loopAmount[chatroomID] = 0;
        }
        if (!_apiKeyIndex.ContainsKey(chatroomID))
        {
            _apiKeyIndex[chatroomID] = 0;
        }

        List<ChatMessage> messages = clientMessages[chatroomID];
        List<ChatMessage> directMsg = new();

        if (!isDirect)
        {
            messages = await CheckHistoryAsync(chatroomID, Prompt);
            if(_loopAmount[chatroomID] == 0)
                messages.Add(new UserChatMessage(userInput));
        }
        else
        {
            directMsg = new()
            {
                new SystemChatMessage(Prompt),
                new UserChatMessage(userInput)
            };
        }

        var requestOptions = new ChatCompletionOptions()
        {
            Temperature = _temperature,
            MaxOutputTokenCount = _maxOutputTokenCount,
        };

        var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));

        try
        {
            if(userInput.Contains("-commit") && debug == false)
            {
                string cmdMessage = "";
                debug = true;
                cmdMessage += "Debugging mode activated.\n";

                if(userInput.Contains("-commit ClientResultException"))
                {
                    throw new ClientResultException("--[ Client result exception for debugging. ]--");
                }
                else if(userInput.Contains("-commit OperationCanceledException"))
                {
                    throw new OperationCanceledException("--[ Timeout exception for debugging. ]--");
                }
                else if(userInput.Contains("-commit HttpRequestException"))
                {
                    throw new HttpRequestException("--[ Rate Limit exception for debugging. ]--", null, System.Net.HttpStatusCode.TooManyRequests);
                }
                else if(userInput.Contains("-commit Exception"))
                {
                    throw new Exception("--[ General exception for debugging. ]--");
                }
            }
            var response = await _client!.CompleteChatAsync(!isDirect ? messages : directMsg, requestOptions, cts.Token);

            // DEBUG
            // if(debug) foreach (var message in messages)
            // {
            //     Console.WriteLine($"Message Type: {message.GetType()}\nContent Type: {message.Content.FirstOrDefault()!.Text}");
            // }

            if (response == null || response.Value == null || response.Value.Content.Count == 0)
            {
                _logger.LogWarning("[OpenAIService] OpenAI API returned an empty or invalid response.");
                return "OpenAI API returned an empty or invalid response.";
            }

            string content = response.Value.Content[0].Text;
            TotalCharactersUsed += content.Length;
            messages.Add(new AssistantChatMessage(content));

            // DEBUG
            if(debug)
            {
                Console.WriteLine($"Message Type: {messages.LastOrDefault()!.GetType()}");
                Console.WriteLine($"Content Type: {messages.LastOrDefault()!.Content.LastOrDefault()!.Text}");
            }

            GetTotalTokenUsed(chatroomID);
            _loopAmount[chatroomID] = 0;
            _apiKeyIndex[chatroomID] = 0;
            await DBUtil.APIKeyIncrementUsage(_currentKey!.APIKeyID!.Value);
            debug = false;
            return content;
        }
        catch (ClientResultException ex) when (ex.Message.Contains("content_filter"))
        {
            _logger.LogWarning("[OpenAIService][catch 1] Prompt was blocked by content filter: {Message}", ex.Message);
            string content = AIResponse.AssistantCM(AIResponse.FilteredMessage());
            messages.Add(new AssistantChatMessage(content));
            return content;
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogWarning($"[OpenAIService][catch 2] {ex.Message}");
            _logger.LogWarning("[OpenAIService] Request timeout detected. Possible rate limit reached. Trying to change API key...");
            return await HandleRateLimit(chatroomID, userInput, Prompt, isDirect);
        }
        catch (HttpRequestException httpEx) when (httpEx.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
        {
            _logger.LogWarning($"[OpenAIService][catch 3] {httpEx.Message}");
            _logger.LogWarning("[OpenAIService] Rate Limit Exceeded: Too many requests. Trying to change API key...");
            return await HandleRateLimit(chatroomID, userInput, Prompt, isDirect, true);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, $"[OpenAIService][default] {ex.Message}");
            _logger.LogError(ex, "[OpenAIService] Error processing OpenAI request. Trying to change API key...");
            return await HandleRateLimit(chatroomID, userInput, Prompt, isDirect);
        }
    }

    // AAAAAAAAAAAAAAAAAAAAKWADKAJWDOA
    private async Task<string> HandleRateLimit(string chatroomID, string userInput, string Prompt, bool isDirect, bool LimitReached = false)
    {
        //var expireDate = new DateTime();
        if(ApiConfig.AvailableKeys == null || ApiConfig.AvailableKeys.Count == 0)
        {
            _currentKey = await _apiConfig.GetLeastUsedAPI();
            _logger.LogInformation("[OpenAIService] No available keys. Using the least used key: {Key}", _currentKey?.APIKey);
        }
        
        if (_loopAmount[chatroomID] < ApiConfig.AvailableKeys!.Count * 2)
        {
            _loopAmount[chatroomID]++;
            int oldID = _currentKey!.APIKeyID!.Value;
            if(LimitReached) await DBUtil.APIKeyLimitReach(oldID);
            _apiKeyIndex[chatroomID]++;
            if(_apiKeyIndex[chatroomID] > ApiConfig.AvailableKeys?.Count - 1)
                _apiKeyIndex[chatroomID] = 0;
            _currentKey = await _apiConfig.GetLeastUsedAPI(_currentKey.APIKeyID.Value, _apiKeyIndex[chatroomID]);

            _logger.LogWarning("[OpenAIService] Switching API key from API_{OldID} to API_{NewID}", oldID, _currentKey!.APIKeyID!.Value);
            
            _apiCredential = new ApiKeyCredential("Bearer " + _currentKey.APIKey);
            _client = new ChatClient("gpt-4o", _apiCredential, _options);
            return await GetAIResponse(chatroomID, userInput, Prompt, isDirect);
        }
        else
        {
            _logger.LogError("[OpenAIService] All API keys exhausted. Delays expected.");
            return "";
        }
    }

    private void GetTotalTokenUsed(string chatroomID)
    {
        if (!clientMessages.ContainsKey(chatroomID)) return;

        var encoding = TikToken.EncodingForModel("gpt-4");
        string allMessagesText = string.Join("\n", clientMessages[chatroomID]
            .Select(m => string.Join("", m.Content.Select(c => c.Text))));

        int tokensUsed = encoding.Encode(allMessagesText).Count;

        // Update per-client token usage
        if (!clientTokenUsage.ContainsKey(chatroomID))
        {
            clientTokenUsage[chatroomID] = 0;
        }
        clientTokenUsage[chatroomID] += tokensUsed;

        // Update global token count
        TokenCountUsed += tokensUsed;

        _logger.LogInformation("[OpenAIService] Total Tokens Used for {ClientId}: {ClientTokenCount}", chatroomID, clientTokenUsage[chatroomID]);
        _logger.LogInformation("[OpenAIService] Total Tokens Used Across All Clients: {TotalTokenCount}", TokenCountUsed);
    }

    private async Task<string> SummarizeMessages(string chatroomID, List<ChatMessage> oldMessages)
    {
        if (!oldMessages.Any())
        {
            _logger.LogWarning("[OpenAIService] oldMessages in SummarizeMessages() is empty.");
            return string.Empty;
        }

        string combinedText = string.Join("\n", oldMessages.Select(m => m.Content.FirstOrDefault()?.Text ?? ""));
        string prompt = "Summarize this conversation briefly, keeping key details:";
        string response = await GetAIResponse(chatroomID, combinedText, prompt, true);

        _logger.LogDebug("[OpenAIService] Summary Generated for {ClientId}: {Summary}", chatroomID, response);
        return $"\nChat History Summary: {response}";
    }

    private async Task<List<ChatMessage>> CheckHistoryAsync(string chatroomID, string Prompt)
    {
        if (!clientMessages.ContainsKey(chatroomID))
        {
            clientMessages[chatroomID] = new List<ChatMessage>();
        }

        List<ChatMessage> messages = clientMessages[chatroomID];

        if (messages.Count == 0 || !(messages[0] is SystemChatMessage))
        {
            messages.Insert(0, new SystemChatMessage(Prompt));
            messages.Insert(1, new AssistantChatMessage(AIResponse.FirstAssistantCM()));
        }
        else
        {
            if (((SystemChatMessage)messages[0]).Content.First().Text != Prompt)
            {
                _logger.LogInformation($"[OpenAIService] Changing prompt for {chatroomID} to {Prompt} ...");
                messages[0] = new SystemChatMessage(Prompt);
            }
        }

        if (messages.Count > 30)
        {
            var systemMessages = messages.Where(m => m is SystemChatMessage).ToList();
            string summary = await SummarizeMessages(chatroomID, messages.GetRange(systemMessages.Count, 10).ToList());
            messages.RemoveRange(systemMessages.Count, 20);

            string newPrompt = string.Join("\n", Prompt, summary);
            messages[0] = new SystemChatMessage(newPrompt);
        }
        return messages;
    }

    public void PopulateMessages() 
    {
        var populatedMessages = AIUtil.PopulateID();
        if (populatedMessages != null)
        {
            foreach (var kvp in populatedMessages)
            {
                clientMessages[kvp.Key] = kvp.Value;
            }
        }
        Console.WriteLine("[OpenAIService] Past AI Messages Restored");
    }
}

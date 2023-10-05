using GoldenTicket.Models;

namespace GoldenTicket.Services;

public class PromptService
{
    private readonly Dictionary<string, PromptData> _prompts = new();
    private readonly ILogger<PromptService> _logger;

    public PromptService(IConfiguration configuration, ILogger<PromptService> logger)
    {
        _logger = logger;
        LoadPromptConfig(configuration);
    }

    private void LoadPromptConfig(IConfiguration configuration)
    {
        try
        {
            var promptData = configuration.GetSection("Prompt").Get<Dictionary<string, PromptData>>();

            if (promptData != null)
            {
                _prompts.Clear();
                foreach (var kvp in promptData)
                {
                    _prompts[kvp.Key] = kvp.Value;
                }

                _logger.LogInformation("[PromptService] Loaded {Count} prompt types successfully.", _prompts.Count);
            }
            else
            {
                _logger.LogError("[PromptService] Failed to load prompts from configuration.");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[PromptService] Error loading config: {Message}", ex.Message);
        }
    }

    public string GetPrompt(string promptType, string additional = "")
    {
        if (_prompts.TryGetValue(promptType, out var promptData))
        {
            return FormatPrompt(promptData, additional);
        }

        return _prompts.TryGetValue("default", out var defaultPrompt)
            ? FormatPrompt(defaultPrompt, additional) : DefaultPrompt();
    }

    private string FormatPrompt(PromptData promptData, string additional)
    {
        string attributes = string.Join(", ", promptData.Attribute);
        string formatted = $"Your name: {promptData.Name}\nAttribute: {attributes}\nPrompt: {promptData.Prompt}";

        if (!string.IsNullOrEmpty(additional))
            formatted += $"\n----Additional Info(NOT PART OF FORMAT)---- {additional}";

        return formatted;
    }
    private string DefaultPrompt()
    {
        _logger.LogWarning("[PromptService] Warning: No prompt found. Using default.");
        return "You are a helpful AI.";
    }
}

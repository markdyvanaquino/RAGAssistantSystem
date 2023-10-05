using System.Text.RegularExpressions;
using Newtonsoft.Json;

namespace GoldenTicket.Models;

public class AIResponse
{
    public string Title { get; set; } = "";
    public string Message { get; set; } = "";
    public string MainTag { get; set; } = "";
    public string SubTags  { get; set; } = "";
    public string Priority { get; set; } = "Medium";
    public bool CallAgent { get; set; } = false;
    public static int FirstResponse { get; set; } = 0;

    private const string TimeBasedGreetingKey = "TIME_BASED_GREETING";

    private static string GetTimeBasedGreeting()
    {
        int hour = DateTime.Now.Hour;
        if (hour >= 5 && hour < 12)
        {
            return "A happy Golden Morning! How can I help you?";
        }
        else if (hour >= 12 && hour < 17)
        {
            return "A Golden afternoon! How can I assist you?";
        }
        else if (hour >= 17 && hour < 21)
        {
            return "A happy Golden evening! How can I help you today?";
        }
        else
        {
            return "Hello! Burning the midnight oil? How can I assist?";
        }
    }

    public static string FirstMessage(bool Randomize = false) 
    {
        List<string> firstMessages = new List<string> 
        {
            "Hello! How can I assist you today?",
            "Hi there! What can I do for you today?",
            TimeBasedGreetingKey,
            "Erm... Hello? What do you need?",
        };
        Random random = new Random();
        int index = random.Next(0, firstMessages.Count);
        if(Randomize) {
            FirstResponse = index;
        }
        string message = Randomize ? firstMessages[index] : firstMessages[FirstResponse];
        if (message == TimeBasedGreetingKey)
        {
            message = GetTimeBasedGreeting();
        }
        return message;
    }

    public static AIResponse Parse(string rawResponse)
    {
        var response = new AIResponse();

        // Regular expressions to match each field
        var titleMatch = Regex.Match(rawResponse, @"TITLE:\s*(.+)");
        var tagMatch = Regex.Match(rawResponse, @"PTAG:\s*(.+)");
        var subTagMatch = Regex.Match(rawResponse, @"PSUBTAG:\s*(.+)");
        var priorityMatch = Regex.Match(rawResponse, @"PRIORITY:\s*(.+)");
        var callAgentMatch = Regex.Match(rawResponse, @"SendToLiveAgent:\s*(true|false)", RegexOptions.IgnoreCase);
        var messageMatch = Regex.Match(rawResponse, @"Response:\s*(.+)", RegexOptions.Singleline); // Capture everything after "Response:"

        // Assign values if found
        if (titleMatch.Success) response.Title = titleMatch.Groups[1].Value.Trim();
        if (tagMatch.Success) response.MainTag = tagMatch.Groups[1].Value.Trim();
        if (subTagMatch.Success) response.SubTags = subTagMatch.Groups[1].Value.Trim();
        if (priorityMatch.Success) response.Priority = priorityMatch.Groups[1].Value.Trim();
        if (callAgentMatch.Success) response.CallAgent = bool.Parse(callAgentMatch.Groups[1].Value.Trim());
        if (messageMatch.Success) response.Message = messageMatch.Groups[1].Value.Trim(); // This will now capture multi-line responses (i hope please :<)

        return response;
    }
    public string ToJson()
    {
        return JsonConvert.SerializeObject(this, Formatting.Indented);
    }
    public static AIResponse Unavailable() {
        return new AIResponse() {
            Title = "AI Unavailable, need live agent",
            Message = "Sorry, Chatbot service is currently down at the moment. Sending a live agent...",
            MainTag = "null",
            SubTags = "null",
            Priority = "Medium",
            CallAgent = true
        };
    }
    public static string FilteredMessage(bool Randomize = false)
    {
        List<string> filteredMessages = new List<string> {
            "Oww couldn't process that.. 😅. Please try again.",
            "Oops can't process that message.. Mind trying again?😅",
            "Ah sorry, can't handle that one..😅 Could you try rephrasing it?", 
            "Hmm that's a bit tricky for me.. 😅 Could you try again?",
            "That message is a bit unclear to me.",
            "I can't help you with that. 😅",
            "Sorry, I'm not sure what you mean. 😅",
            "I'm not programmed to handle that. 😅",
            "I'm not sure how to respond to that. 😅",
            "I'm not sure how to handle that. 😅",
        };
        Random random = new Random();
        int index = random.Next(0, filteredMessages.Count);
        string message = Randomize ? filteredMessages[index] : filteredMessages[0];
        return message;
    }

    public static string FirstAssistantCM(){
        return $"TITLE: No Title yet  \nPTAG: null  \nPSUBTAG: null  \nPRIORITY: Normal  \nSendToLiveAgent: false  \nResponse: {FirstMessage()}";
    }
    public static string AssistantCM(string message){
        return $"TITLE: No Title yet  \nPTAG: null  \nPSUBTAG: null  \nPRIORITY: Normal  \nSendToLiveAgent: false  \nResponse: {message}";
    }
}

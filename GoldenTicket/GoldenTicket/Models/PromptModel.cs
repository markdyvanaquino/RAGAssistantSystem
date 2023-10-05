namespace GoldenTicket.Models;

public class PromptConfig
{
    public Dictionary<string, PromptData> Prompts { get; set; } = new();
}

public class PromptData
{
    public List<string> Attribute { get; set; } = new();
    public string Name { get; set; } = "AR-AI";
    public string Prompt { get; set; } = "You are a helpful AI.";
}

namespace GoldenTicket.Models;

public class AppConfig
{
    public OpenAISettings OpenAISettings { get; set; } = new();
}

public class OpenAISettings
{
    public string BaseUrl { get; set; } = "https://models.inference.ai.azure.com/";
    public int ChatbotID { get; set; } = 100000001;
    public float Temperature { get; set; } = 0.4f;
    public int MaxOutputTokenCount { get; set; } = 2000;
}

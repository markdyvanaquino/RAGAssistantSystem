namespace GoldenTicket.Models
{
    public class AIRequest
    {
        public required string Message { get; set; }
        public string? PromptType { get; set; }
        public required string id { get; set; }
        public string? Additional { get; set; } = "";
        public int userID { get; set; }
    }
}

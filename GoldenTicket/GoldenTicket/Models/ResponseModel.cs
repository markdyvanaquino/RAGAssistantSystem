namespace GoldenTicket.Models
{
    public class ResponseModel
    {
        public required string Message { get; set; }
        public required string PromptType { get; set; }
        public string? Additional { get; set; }
    }
}

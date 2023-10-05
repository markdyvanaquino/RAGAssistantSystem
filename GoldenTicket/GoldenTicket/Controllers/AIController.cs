using Microsoft.AspNetCore.Mvc;
using GoldenTicket.Services;
using GoldenTicket.Models;
using OpenAIApp.Services;
using GoldenTicket.Utilities;

namespace GoldenTicket.Controllers
{
    [ApiController]
    [Route("api/[controller]")] // URL: /api/ai
    public class AIController : ControllerBase
    {
        [HttpPost("Response")]
        public async Task<IActionResult> ProcessRequestAsync([FromBody] AIRequest requestData)
        {
            if (requestData?.Message == null || requestData.PromptType == null || requestData.id == null)
                return BadRequest(new {status = 400, message = "Invalid JSON", errorType = "message and/or promptType not found."});
            
            string id = requestData.id;
            string message = requestData.Message;
            string promptType = requestData.PromptType;
            string additional = requestData.Additional ?? "";

            string aiResponse = await AIUtil.GetAIResponseAsync(id, message, promptType, additional);
            return Ok(new { response = aiResponse });
        }
        [HttpPost("JsonResponse")]
        public async Task<IActionResult> ProcessJsonResponseAsync([FromBody] AIRequest requestData)
        {
            var unavailableResponse = AIResponse.Unavailable();

            string id = requestData.id;
            string message = requestData.Message;
            string promptType = requestData.PromptType ?? "GoldenTicket";
            string? additional = requestData.Additional ?? "";
            int userID = requestData.userID;

            if (requestData?.Message == null || requestData.id == null)
            {
                return BadRequest(new {status = 400, message = "Invalid JSON", errorType = "message and/or promptType not found."});
            }

            var parsedResponse = await AIUtil.GetJsonResponseAsync(id, message, userID, promptType, additional) ?? null;

            if (!string.IsNullOrWhiteSpace(parsedResponse?.Message))
                return Ok(new {status = 200, message = "Request Response successfully", body = new {parsedResponse}}); 
            else
                return StatusCode(202, new {status = 202, message = "OpenAI is currently having trouble.", body = new {unavailableResponse}});
        }
    }
}

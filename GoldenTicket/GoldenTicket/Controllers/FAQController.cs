using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Controllers
{
     [Route("api/[controller]")]
    public class FAQController : Controller
    {
        [HttpGet("GetFAQs")]
        public IActionResult GetFAQs()
        {
            using (var _context = new ApplicationDbContext())
            {
                var faqs = DBUtil.GetFAQs();
                if (faqs.Count == 0)
                    return NotFound(new { status = 404, message = "No FAQs found", errorType = "faq is empty" });

                return Ok(new { status = 200, message = "Retrieved successfully!", body = new { faqs } });
            }
        }
        [HttpPost("AddFAQ")]
        public IActionResult AddFAQ([FromBody] AddFAQRequest faq)
        {
            if (faq == null || !ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errors });
            }
            try
            {
                // DBUtil.AddFAQ(faq.Title!, faq.Description!, faq.Solution!, faq.MainTagID!, faq.SubTagID!);
                return Ok(new {status = 200, message = "FAQ added successfully!"});
            }
            catch (Exception err)
            {
                Console.WriteLine(err);
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errorType = "invalid" });
            }

        }
    }
}
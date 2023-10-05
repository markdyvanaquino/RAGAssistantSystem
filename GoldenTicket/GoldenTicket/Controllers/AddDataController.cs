using GoldenTicket.Models;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace GoldenTicket.Controllers
{
     [Route("api/[controller]")]
    public class AddDataController : Controller
    {
        [HttpPost("AddMainTag")]
        public IActionResult AddMainTag([FromBody] AddMainTagRequest mainTag)
        {
            if (mainTag == null || !ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errors });
            }
            try
            {
                DBUtil.AddMainTag(mainTag.TagName!);
                return Ok(new {status = 200, message = "Main Tag added successfully!"});
            }
            catch (Exception err)
            {
                Console.WriteLine(err);
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errorType = "invalid" });
            }
        }
        [HttpPost("AddSubTag")]
        public IActionResult AddSubTag([FromBody] AddSubTagRequest subTag)
        {
            if (subTag == null || !ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errors });
            }
            try
            {
                DBUtil.AddSubTag(subTag.TagName!, subTag.MainTagName!);
                return Ok(new {status = 200, message = "Sub Tag added successfully!"});
            }
            catch (Exception err)
            {
                Console.WriteLine(err);
                return BadRequest(new {status = 400, message = "Invalid request, check your body format.", errorType = "invalid" });
            }
        }
    }
}
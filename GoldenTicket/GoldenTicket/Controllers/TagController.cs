using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Controllers
{
     [Route("api/[controller]")]
    public class TagController : Controller
    {
        [HttpGet("GetTags")]
        public IActionResult GetTags()
        {
            using(var context = new ApplicationDbContext()){
                
                var maintags = context.MainTag.Include(m => m.ChildTags).Select(m => new {
                    mainTagID = m.TagID,
                    mainTagName = m.TagName,
                    subTags = m.ChildTags.Select(c => new 
                    {
                        subTagID = c.TagID,
                        subTagName = c.TagName,
                        mainTagName = m.TagName
                    }).ToList()
                }).ToList();

                return Ok(new {status = 200, message = "Processed successfully.", body = new { tags =  maintags}}); 
            }
        }
    }
}
using GoldenTicket.Entities;
using GoldenTicket.Models;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;

namespace GoldenTicket.Controllers
{
     [Route("api/[controller]")]
    public class GTAuthController : Controller
    {
        [HttpPost("Register")]
        public IActionResult Register([FromBody] RegisterRequest request)
        {
            if (request == null || !ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
                return BadRequest(new { status = "400", message = "Invalid client request", errors });
            }

            if (DBUtil.IsUserExisting(request.username!))
            {
                return BadRequest(new { status = "400", message = "Username taken", errorType = "userTaken" });
            }

            try
            {
                DBUtil.RegisterAccount(request.username!, request.password!, request.firstName!, request.middleInitial, request.lastName!, request.roleID!);
                return Ok(new { status = 200, message = "Registration is Successful!" });
            }
            catch (Exception err)
            {
                Console.WriteLine(err);
                return BadRequest(new { status = "400", message = "Invalid request, check your body format.", errorType = "invalid" });
            }
        }
        [HttpPost("Login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            if (request == null) return BadRequest(new { message = "Invalid client request" });
            var user = DBUtil.FindUser(request.username!) ?? null;

            // Validate credentials (replace with your own authentication logic)
            if (user != null)
            {
                if (AuthUtils.VerifyPassword(request.password!, user.Password!))
                {
                    // Simulate token generation (in a real app, generate a JWT or similar token)

                    UserDTO User = new UserDTO(user);
                    DateTime sessionExpiry = DateTime.UtcNow.AddHours(24);
                    if(user.IsDisabled) return Unauthorized(new {status = 401,  message = "Unauthorized access Account is disabled!", errorType = "unauthorized" });
                    return Ok(new {status = 200, message = "Login Successfully", body = new { user = User, sessionExpiry }});
                }
                else
                {
                    return Unauthorized(new {status = 401,  message = "Username/Password is incorrect.", errorType = "incorrectPassword" });
                }
            }
            else
            {
                return NotFound(new { status = 400, message = "User does not exist!", errorType = "unregistered" });
            }
        }
        [HttpPost("Verify")]
        public IActionResult Verify([FromBody] VerifyRequest request)
        {
            if (request == null) return BadRequest(new { message = "Invalid client request" });

            if (request == null || !ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
                return BadRequest(new { status = "400", message = "Invalid client request", errors });
            }
            
            int userID = request.userID!.Value;
            var user = DBUtil.FindUser(userID);
            
            if(user != null)
            {
                string message = user.IsDisabled ? "Disabled" : "Enabled";
                return Ok(new {status = 200, message = $"Account is {message}", body = new { isDisabled = user.IsDisabled }});
            }
            else
            {
                return Unauthorized(new {status = 401,  message = "user not found.", errorType = "notFound" });
            }
        }
    }
}
using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Models
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Username is required")]
        public string? username { get; set; }

        [Required(ErrorMessage = "Password is required")]
        public string? password { get; set; }

        [Required(ErrorMessage = "First name is required")]
        public string? firstName { get; set; }

        public string? middleInitial { get; set; } = ""; // Optional

        [Required(ErrorMessage = "Last name is required")]
        public string? lastName { get; set; }

        [Required(ErrorMessage = "Role ID is required")]
        public int? roleID { get; set; }
    }
    public class LoginRequest {
        [Required(ErrorMessage = "username is required")]
        public string? username {get;set;}
        [Required(ErrorMessage = "password is required")]
        public string? password {get;set;}
    }
    public class VerifyRequest {
        [Required(ErrorMessage = "userID is required")]
        public int? userID {get; set;}
    }
    public class AddFAQRequest {
        [Required(ErrorMessage = "Ticket Title is required")]
        public string? Title {get;set;}

        [Required(ErrorMessage = "Description is required")]
        public string? Description {get;set;}
        [Required(ErrorMessage = "Solution is required")]
        public string? Solution { get; set; }

        [Required(ErrorMessage = "Main Tag is required")]
        public int MainTagID {get;set;}

        [Required(ErrorMessage = "Sub Tag is required")]
        public int SubTagID {get;set;}
    }
    public class AddMainTagRequest {
        [Required(ErrorMessage = "Tag Name is required")]
        public string? TagName {get;set;}
    }
    public class AddSubTagRequest {
        [Required(ErrorMessage = "Tag Name is required")]
        public string? TagName {get;set;}
        [Required(ErrorMessage = "Main Tag ID is required")]
        public string? MainTagName {get;set;}
    }
}
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GoldenTicket.Entities
{
    [Table("tblUsers")]
    public class User {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int UserID { get; set; }
        [Required]
        public string? Username { get; set; }
        [Required]
        public string? Password { get; set; }
        [Required]
        public string? FirstName { get; set; }
        public string? MiddleName { get; set; } = "";
        [Required]
        public string? LastName { get; set; }
        [Required]
        public int RoleID { get; set; }
        [ForeignKey("RoleID")]
        public Roles? Role { get; set; } = null;
        public string Email { get; set; } = "None Provided";
        public string PhoneNumber { get; set; } = "None Provided";
        public bool IsDisabled { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? lastOnlineAt { get;set; }

        public ICollection<Chatroom> Chatrooms { get; set; } = new List<Chatroom>();
        public ICollection<Tickets> Tickets { get; set; } = new List<Tickets>();
        public ICollection<AssignedTag> AssignedTags { get; set; } = new List<AssignedTag>();
    }
    public class UserDTO { 
        public int UserID { get; set; }
        public string? Username { get; set; }
        public string? FirstName { get; set; }
        public string? MiddleName { get; set; }
        public string? LastName { get; set; }
        public string? Role {get;set;}
        public bool IsDisabled {get;set;}
        public List<string>? AssignedTags { get; set; } = new List<string>();
        public DateTime? LastOnlineAt { get; set; }
        public DateTime CreatedAt {get;set;}
        public UserDTO(User user){
            this.UserID = user.UserID;
            this.Username = user.Username;
            this.FirstName = user.FirstName;
            this.MiddleName = user.MiddleName;
            this.LastName = user.LastName;
            this.Role = user.Role!.RoleName;
            this.LastOnlineAt = user.lastOnlineAt;
            this.CreatedAt = user.CreatedAt;
            this.IsDisabled = user.IsDisabled;
            this.AssignedTags = [];
            foreach(var assignedTag in user.AssignedTags){
                this.AssignedTags.Add(assignedTag.MainTag!.TagName!);
            }

        }
    }
}
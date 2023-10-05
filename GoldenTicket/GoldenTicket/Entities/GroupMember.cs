using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Entities
{

    [Table("tblMember")]
    public class GroupMember
    {
        [Key] 
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ChatMemberID { get; set; }

        [Required]
        public int ChatroomID { get; set; }
        [ForeignKey("ChatroomID")]
        public Chatroom Channel { get; set; } = null!;

        [Required]
        public int MemberID { get; set; }

        [ForeignKey("MemberID")]
        public User? Member { get; set; }
        public DateTime JoinedAt {get;set;} = DateTime.Now;
        public DateTime? LastSeenAt { get; set; }
    }

    public class GroupMemberDTO { 
        public UserDTO User { get; set; }
        public DateTime? JoinedAt { get; set; }
        public DateTime? LastSeenAt { get; set; }
        public GroupMemberDTO(GroupMember groupMember){
            this.User = new UserDTO(groupMember.Member!);
            this.JoinedAt = groupMember.JoinedAt;
            this.LastSeenAt = groupMember.LastSeenAt ?? null;
        }
    }
}
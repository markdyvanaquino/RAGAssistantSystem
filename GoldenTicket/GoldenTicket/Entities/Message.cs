using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblMessage")]
    public class Message
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int MessageID { get; set; }
        [Required]
        public int ChatroomID { get; set; }

        [ForeignKey("ChatroomID")]
        public Chatroom? Chatroom;

        [Required]
        public int SenderID { get; set; }

        [ForeignKey("SenderID")]
        public User? Sender { get; set; }

        [Required]
        public string? MessageContent { get;set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }

    public class MessageDTO{
        public int? MessageID { get; set; }
        public string? MessageContent { get; set; } = "";
        public UserDTO? Sender { get; set; }
        public DateTime? CreatedAt { get; set; }
        public MessageDTO(Message message){
            this.MessageID = message.MessageID;
            this.MessageContent = message.MessageContent;
            this.Sender = new UserDTO(message.Sender!);
            this.CreatedAt = message.CreatedAt;
        }
    }
}

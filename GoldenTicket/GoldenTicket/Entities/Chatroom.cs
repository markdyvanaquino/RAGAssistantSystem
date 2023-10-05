using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;
using GoldenTicket.Utilities;

namespace GoldenTicket.Entities
{
    [Table("tblChatroom")]
    public class Chatroom
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ChatroomID { get; set; }
        
        [Required]
        public string? ChatroomName { get; set; } = "New Chatroom";
        [Required]
        public int AuthorID { get; set; }

        [ForeignKey("AuthorID")]
        public User? Author { get; set; } = null;
        public int? TicketID { get; set; }

        [ForeignKey("TicketID")]
        public Tickets? Ticket { get; set; } = null;
        public bool IsClosed { get; set; }= false;
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();

        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
    public class ChatroomDTO {
        public int? ChatroomID { get; set; }
        public string? ChatroomName { get; set; }
        public UserDTO? Author { get; set; }
        public TicketDTO? Ticket { get; set; }
        public bool IsClosed { get; set; }
        public List<MessageDTO>? Messages { get; set; } = [];
        public List<GroupMemberDTO> GroupMembers  { get; set; } = [];
        public LastMessageDTO? LastMessage { get; set; } = null;
        public int Unread { get; set; } = 0;
        public DateTime? CreatedAt  { get; set; }

        public ChatroomDTO(Chatroom chatroom, bool IncludeMessages = false, bool IncludeUnread = false, int userID = 0)
        {
            this.ChatroomID = chatroom.ChatroomID;
            this.ChatroomName = chatroom.ChatroomName;
            this.Author = chatroom.Author != null ? new UserDTO(chatroom.Author) : null;
            this.IsClosed = chatroom.IsClosed;
            this.Ticket = chatroom.Ticket != null ? new TicketDTO(chatroom.Ticket) : null;

            if (IncludeMessages && IncludeUnread && userID != 0)
            {
                this.Unread = chatroom.Messages.Count(m => m.SenderID != userID && m.CreatedAt > chatroom.Members.FirstOrDefault(m => m.MemberID == userID)?.LastSeenAt);
            }

            // Sort messages from latest to earliest
            
            this.Messages = chatroom.Messages
                .OrderBy(m => m.CreatedAt)
                .Select(m => new MessageDTO(m))
                .ToList();
            // Assign the last message if available
            var lastMessage = chatroom.Messages.OrderByDescending(m => m.CreatedAt).FirstOrDefault();
            this.LastMessage = lastMessage != null ? new LastMessageDTO(lastMessage) : null;
            if(!IncludeMessages) this.Messages = [];
            this.GroupMembers = chatroom.Members
                .Select(member => new GroupMemberDTO(member))
                .ToList();

            this.CreatedAt = chatroom.CreatedAt;
        }
    }

    public class LastMessageDTO{
        public string? LastMessage { get; set; } = "";
        public UserDTO? Sender { get; set; }
        public DateTime CreatedAt { get; set;}

        public LastMessageDTO(Message message){
            this.LastMessage = message.MessageContent;
            this.Sender = new UserDTO(message.Sender!);
            this.CreatedAt = message.CreatedAt;
        }
    }
}

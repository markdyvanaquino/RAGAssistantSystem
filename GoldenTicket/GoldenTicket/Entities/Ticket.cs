using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblTickets")]
    public class Tickets
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TicketID { get; set; }
        
        [Required]
        public string? TicketTitle { get; set; }
        [Required]
        public int AuthorID { get; set; }

        [ForeignKey("AuthorID")]
        public User? Author { get; set; } = null;
        public int? AssignedID { get; set; }

        [ForeignKey("AssignedID")]
        public User? Assigned { get; set; } = null;
        public int? StatusID { get; set; }
        [ForeignKey("StatusID")]
        public Status? Status { get; set; } = null;
        public int? MainTagID { get; set; }

        [ForeignKey("MainTagID")]
        public MainTag? MainTag { get; set; } = null;
        public int? SubTagID { get; set; }

        [ForeignKey("SubTagID")]
        public SubTag? SubTag { get; set; } = null;
        [Required]
        public int PriorityID { get; set; }

        [ForeignKey("PriorityID")]
        public Priority? Priority { get; set; } = null;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? DeadlineAt {get;set;}
        public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();
        public ICollection<TicketHistory> ticketHistories { get; set;} = new List<TicketHistory>();
        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
    public class TicketDTO {
        public int? TicketID { get; set; }
        public string? TicketTitle { get; set; }
        public string? Status { get; set; }
        public string Priority { get; set; }
        public UserDTO? Author { get; set; }
        public UserDTO? Assigned { get; set; }
        public MainTagDTO? MainTag { get; set; }
        public SubTagDTO? SubTag { get; set; }
        public List<TicketHistoryDTO> TicketHistory {get; set;} = [];
        public DateTime? CreatedAt { get; set; }
        public DateTime? DeadlineAt { get; set; }
        public TicketDTO(Tickets ticket){
            this.TicketID = ticket.TicketID;
            this.TicketTitle = ticket.TicketTitle;
            this.Author = ticket.Author != null ? new UserDTO(ticket.Author) : null;
            this.Assigned = ticket.Assigned != null ? new UserDTO(ticket.Assigned) : null;
            this.Priority = ticket.Priority!.PriorityName!;
            foreach(var history in ticket.ticketHistories){
                TicketHistory.Add(new TicketHistoryDTO(history));
            }
            this.CreatedAt = ticket.CreatedAt;
            this.Status = ticket.Status!.StatusName;
            this.MainTag = ticket.MainTag != null ? new MainTagDTO(ticket.MainTag) : null;
            this.SubTag = ticket.SubTag != null ? new SubTagDTO(ticket.SubTag) : null;
        }

    }
}

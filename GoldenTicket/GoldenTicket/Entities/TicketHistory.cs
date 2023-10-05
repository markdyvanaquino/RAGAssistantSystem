using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Entities
{
    [Table("tblTicketHistory")]
    public class TicketHistory
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TicketHistoryID { get; set; }
        
        [Required]
        public int TicketID { get; set; }

        [ForeignKey("TicketID")]
        public Tickets? Ticket { get; set; } = null;
        [Required]
        public int ActionID { get; set; }

        [ForeignKey("ActionID")]
        public Action? Action { get; set; } = null;
        [Required]
        public string? ActionMessage { get; set; } = "";
        [Required]
        public DateTime? ActionDate { get; set; } = DateTime.Now;
    }

    public class TicketHistoryDTO {
        public string? Action { get; set;} = "";
        public string? ActionMessage { get; set;} = "";
        public DateTime? ActionDate { get; set;}
        
        public TicketHistoryDTO (TicketHistory ticketHistory){
            this.Action = ticketHistory.Action!.ActionName;
            this.ActionMessage = ticketHistory.ActionMessage;
            this.ActionDate = ticketHistory.ActionDate;
        }
    }
}

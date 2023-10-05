using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblStatus")]
    public class Status
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int StatusID { get; set; }
        
        [Required]
        public string? StatusName { get; set; } = "";
        public ICollection<Tickets> TicketList { get; set; } = new List<Tickets>();
    }
}

using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Entities
{
    [Table("tblActions")]
    public class Action
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ActionID { get; set; }
        
        [Required]
        public string? ActionName { get; set; } = "";
    }
}

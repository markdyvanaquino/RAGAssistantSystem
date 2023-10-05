using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
namespace GoldenTicket.Entities
{
    [Table("tblAssignedTag")]
    public class AssignedTag
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int AssignedTagID { get; set; }
        
        [Required]
        public int? UserID { get; set; }

        [ForeignKey("UserID")]
        public User? User { get; set; }
        
        [Required]
        public int? MainTagID { get; set; }
        [ForeignKey("MainTagID")]
        public MainTag? MainTag { get; set; }
    }

}

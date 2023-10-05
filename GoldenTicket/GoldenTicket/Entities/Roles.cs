using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblRoles")]
    public class Roles
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int RoleID { get; set; }
        
        [Required]
        public string? RoleName { get; set; } = "";
    }
}

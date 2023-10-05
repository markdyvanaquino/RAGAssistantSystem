using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblSubTags")]
    public class SubTag
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TagID { get; set; }
        [Required]
        public string? TagName { get; set; }
        [Required]
        public int MainTagID { get; set; }
        [ForeignKey("MainTagID")]
        public MainTag? MainTag { get; set; } = null;
    }
    public class SubTagDTO
    {
        public int SubTagID { get; set; }
        public string? SubTagName { get; set; }
        public SubTagDTO(SubTag subTag){
            this.SubTagID = subTag.TagID;
            this.SubTagName = subTag.TagName;
        }
    }

}

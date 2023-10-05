using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
namespace GoldenTicket.Entities
{
    [Table("tblMainTag")]
    public class MainTag
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TagID { get; set; }
        [Required]
        public string? TagName { get; set; }
        public ICollection<SubTag> ChildTags { get; set; } = new List<SubTag>();
    }

    public class MainTagDTO
    {
        public int MainTagID { get; set; }
        public string? MainTagName { get; set; }
        public List<SubTagDTO>? SubTags { get; set; }

        public MainTagDTO(MainTag mainTag){
            this.MainTagID = mainTag.TagID;
            this.MainTagName = mainTag.TagName;
            this.SubTags = [];
            foreach(var subTag in mainTag.ChildTags){
                this.SubTags.Add(new SubTagDTO(subTag));
            }
        }
    }

}

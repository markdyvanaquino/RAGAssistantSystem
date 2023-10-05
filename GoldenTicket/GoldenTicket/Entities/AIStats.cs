using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("AIStats")]
    public class AIStats
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int AIStatsID { get; set; }
        public ICollection<Rating> Ratings { get; set; } = new List<Rating>();
    }

    public class AIStatsDTO{
        public List<RatingDTO> ratings { get; set;} = [];

        public AIStatsDTO(AIStats stats){
            if(stats.Ratings.Count > 0){
                foreach(Rating rating in stats.Ratings){
                    ratings.Add(new RatingDTO(rating));
                }
            }
        }
    }
}

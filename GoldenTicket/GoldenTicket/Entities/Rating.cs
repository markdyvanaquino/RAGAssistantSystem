using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblRating")]
    public class Rating
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int RatingID { get; set; }
        [Required]
        public int ChatroomID { get; set; }
        [ForeignKey("ChatroomID")]
        public Chatroom? Chatroom { get; set; } = null;
        [Required]
        public DateTime CreatedAt { get; set;}
        [Required]
        public int Score { get; set; }
        public string? Feedback { get; set; } = "None provided";
    }

    public class RatingDTO {
        public int RatingID { get; set; }
        public ChatroomDTO Chatroom { get; set; }
        public int Score { get; set; }
        public string? Feedback { get; set; } = "None Provided";
        public DateTime CreatedAt { get; set; } 

        public RatingDTO(Rating rating){
            this.RatingID = rating.RatingID;
            this.Chatroom = new ChatroomDTO(rating.Chatroom!);
            this.Score = rating.Score;
            this.Feedback = rating.Feedback;
            this.CreatedAt = rating.CreatedAt;
        }
    }
}

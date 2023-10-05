using GoldenTicket.Entities;
using GoldenTicket.Utilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace GoldenTicket.Database {
    /// <summary>
    ///     Database Context for MySQL
    /// </summary>
    /// <param name="configuration">Configuraion JSON files</param>
    
    public class ApplicationDbContext() : DbContext{
        public IConfiguration config = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("Config/secret.json", optional: false, reloadOnChange: true).AddJsonFile("Config/database.json", optional: false, reloadOnChange: true).Build();
        public static string? ConnectionString {get; private set;}

        public DbSet<User> Users { get; set; }
        public DbSet<Chatroom> Chatrooms { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<GroupMember> GroupMembers { get; set; }
        public DbSet<Tickets> Tickets { get; set; }
        public DbSet<TicketHistory> TicketHistory { get; set; }
        public DbSet<FAQ> Faq { get; set; }
        public DbSet<MainTag> MainTag { get; set; }
        public DbSet<SubTag> SubTag { get; set; }
        public DbSet<Status> Status { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<NotificationType> NotificationTypes { get; set; }
        public DbSet<Roles> Roles { get; set; }
        public DbSet<Entities.Action> Actions { get; set; }
        public DbSet<AIStats> AIStats { get; set; }
        public DbSet<Rating> Rating { get; set; }
        public DbSet<Priority> Priorities { get; set;}
        public DbSet<AssignedTag> AssignedTags { get; set; }
        public DbSet<APIKeys> ApiKeys { get; set; }
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            ConnectionString = config["ConnectionString"] ?? throw new Exception("Connection String is Invalid");

            optionsBuilder.UseMySql(ConnectionString, ServerVersion.Parse("8.0.37-mysql"),
                options => options.EnableRetryOnFailure());                
        }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().Property(e => e.UserID).HasAnnotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn);
            modelBuilder.Entity<Tickets>().Property(e => e.TicketID).UseMySqlIdentityColumn();
            modelBuilder.Entity<TicketHistory>().Property(e => e.TicketHistoryID).UseMySqlIdentityColumn();
            modelBuilder.Entity<Chatroom>().Property(e => e.ChatroomID).UseMySqlIdentityColumn();

            modelBuilder.Entity<Tickets>()
            .HasOne(c => c.Author)
            .WithMany()  // No navigation property in User
            .HasForeignKey(c => c.AuthorID)
            .OnDelete(DeleteBehavior.Restrict); // Prevent cascade delete if needed

            modelBuilder.Entity<Tickets>()
            .HasOne(c => c.Assigned)
            .WithMany()  // No navigation property in User
            .HasForeignKey(c => c.AssignedID)
            .OnDelete(DeleteBehavior.Restrict); // Prevent cascade delete if needed

            base.OnModelCreating(modelBuilder);

            // Run SQL command when migrating
            
            var hashedPassword = AuthUtils.HashPassword(config["AdminPassword"] ?? throw new Exception("AdminPassword does not exist in Config"), out string salt);
            
            // Initialize Admin
            modelBuilder.Entity<User>().HasData(
                new User { UserID = 100000000, Username = config["AdminUsername"], Password = $"{salt}:{hashedPassword}", FirstName = config["AdminFirstName"] ?? "Admin", MiddleName = config["AdminMiddleName"] ?? "", LastName = config["AdminLastName"] ?? "Admin", RoleID = 1},
                new User { UserID = 100000001, Username = "Golden AI", Password = $"{salt}:{hashedPassword}", FirstName = "Golden", LastName = "AI", RoleID = 1}
            );
            List<string>? mainTags = config.GetSection("Tags:MainTags").Get<List<string>>();
            List<SubTagConfig>? subTags = config.GetSection("Tags:SubTags").Get<List<SubTagConfig>>();
            List<string>? actions = config.GetSection("Tags:Actions").Get<List<string>>();
            List<string>? status = config.GetSection("Tags:Status").Get<List<string>>();
            List<string>? priority = config.GetSection("Tags:Priority").Get<List<string>>();
            List<string>? roles = config.GetSection("Tags:Roles").Get<List<string>>();
            List<string>? notification = config.GetSection("Tags:Notification").Get<List<string>>();
           
            if(mainTags != null){
                for(int i = 0; i < mainTags.Count; i++){
                    modelBuilder.Entity<MainTag>().HasData(
                        new MainTag {TagID = i + 1, TagName = mainTags[i]}
                    );
                }
            }
            if(subTags != null){
                for(int i = 0; i < subTags.Count; i++){
                    modelBuilder.Entity<SubTag>().HasData(
                        new SubTag {TagID = i + 1, TagName = subTags[i].Name, MainTagID = subTags[i].Parent}
                    );
                }
            }
            if(actions != null){
                for(int i = 0; i < actions.Count; i++){
                    modelBuilder.Entity<Entities.Action>().HasData(
                        new  Entities.Action{ActionID = i + 1, ActionName = actions[i]}
                    );
                }
            }
            if(status != null){
                for(int i = 0; i < status.Count; i++){
                    modelBuilder.Entity<Status>().HasData(
                        new  Status{StatusID = i + 1, StatusName = status[i]}
                    );
                }
            }
            if(priority != null){
                for(int i = 0; i < priority.Count; i++){
                    modelBuilder.Entity<Priority>().HasData(
                        new  Priority{PriorityID = i + 1, PriorityName = priority[i]}
                    );
                }
            }
            if(notification != null){
                for(int i = 0; i < notification.Count; i++){
                    modelBuilder.Entity<NotificationType>().HasData(
                        new  NotificationType{NotificationID = i + 1, NotificationName = notification[i]}
                    );
                }
            }
            if(roles != null){
                for(int i = 0; i < roles.Count; i++){
                    modelBuilder.Entity<Roles>().HasData(
                        new  Roles{RoleID = i + 1, RoleName = roles[i]}
                    );
                }
            }
        }
        
    }
}
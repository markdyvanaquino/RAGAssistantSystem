using GoldenTicket.Database;
using GoldenTicket.Hubs;
using GoldenTicket.Utilities;
using Hangfire;
using Microsoft.EntityFrameworkCore;
namespace GoldenTicket.Extensions
{
    public class HangFireService
    {
        private readonly IRecurringJobManager _recurringJobManager;
        private readonly IServiceScopeFactory _serviceScopeFactory;
        private readonly GTHub _hub;

        public HangFireService(IRecurringJobManager recurringJobManager, IServiceScopeFactory serviceScopeFactory, GTHub hub)
        {
            _recurringJobManager = recurringJobManager;
            _serviceScopeFactory = serviceScopeFactory;
            _hub = hub;
        }
        public void InitializeRecurringJobs()
        {
            RecurringJob.AddOrUpdate(
                "Resolve-Chats",
                () => ExecuteChatResolveAsync(),
                Cron.Daily // Runs once per day
            );
            RecurringJob.AddOrUpdate(
                "Update-API-Keys",
                () => ExecuteAPIKeysUpdayeAsync(),
                Cron.Minutely // Runs once per minute
            );
            RecurringJob.AddOrUpdate(
                "Reset-API-Keys-Usage",
                () => ExecuteAPIResetUsageAsync(),
                Cron.Daily // Runs once per day
            );
        }
        public async Task ExecuteChatResolveAsync()
        {
            DateTime threeDaysAgo = DateTime.UtcNow.AddDays(-3);
            using (var context = new ApplicationDbContext())
            {
                var filter = await DBUtil.GetChatrooms(true);
                var chatrooms = filter
                    .Where(c => c.LastMessage != null && c.IsClosed == false && c.LastMessage.CreatedAt <= threeDaysAgo && c.Ticket == null)
                    .ToList();

                await _hub.ResolveTickets(chatrooms);
            }
        }
        public async Task ExecuteAPIKeysUpdayeAsync()
        {
            Console.WriteLine("[HangFireService] [INFO] Updating API Keys...");

            await _hub.GetApiKeys();
        }
        public async Task ExecuteAPIResetUsageAsync()
        {
            Console.WriteLine("[HangFireService] [INFO] Resetting API Keys Usage...");

            await _hub.ResetUsage();
        }
    }
}

public static class HangfireExtensions
{
    public static IApplicationBuilder UseHangfire(this IApplicationBuilder app)
    {
        ArgumentNullException.ThrowIfNull(app, nameof(app));
        var gc = app.ApplicationServices.GetService<IGlobalConfiguration>();
        ArgumentNullException.ThrowIfNull(gc, nameof(gc));
        ArgumentNullException.ThrowIfNull(JobStorage.Current, nameof(JobStorage.Current));

        return app;
    }
}
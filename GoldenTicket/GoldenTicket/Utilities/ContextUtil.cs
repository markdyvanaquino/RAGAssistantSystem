using System.Diagnostics;
using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Utilities
{
    public class ContextUtil 
    {
        public async static Task<List<Chatroom>> Chatrooms(ApplicationDbContext context, bool includeMessages = false)
        {
            return await context.Chatrooms
                .BuildBaseChatroomQuery(includeMessages)
                .ToListAsync();
        }
        public static async Task<Chatroom?> Chatroom(int ChatroomID, ApplicationDbContext context, bool includeMessages = false)
        {
            return await context.Chatrooms
                .BuildBaseChatroomQuery(includeMessages)
                .Where(c => c.ChatroomID == ChatroomID)
                .FirstOrDefaultAsync();
        }
        public static Chatroom? ChatroomByTicketID(int? ticketID, ApplicationDbContext context, bool includeMessages = false)
        {
            return context.Chatrooms
                .BuildBaseChatroomQuery(includeMessages)
                .Where(c => ticketID == null ? c.TicketID == null : c.TicketID == ticketID)
                .FirstOrDefault();
        }
        public async static Task<Message?> Message (int MessageID, ApplicationDbContext context) 
        {
            return await context.Messages
                    .BuildBaseMessageQuery()
                    .Where(m => m.MessageID == MessageID)
                    .FirstOrDefaultAsync();
        }
        public async static Task<List<Rating>> Ratings(ApplicationDbContext context)
        {
            return await context.Rating
                .BuildBaseRatingQuery()
                .ToListAsync();
        }

        public static Rating? Rating(int ChatroomID, ApplicationDbContext context)
        {
            return context.Rating
                .BuildBaseRatingQuery()
                .Where(r => r.ChatroomID == ChatroomID)
                .FirstOrDefault();
        }

        public async static Task<List<Notification>> Notifications (int userID, ApplicationDbContext context)
        {
            return await context.Notifications
                .BuildBaseNotificationQuery()
                .Where(n => n.UserID == userID)
                .ToListAsync();
        }
        public async static Task<List<Notification>> Notifications (List<int> userIDs, ApplicationDbContext context)
        {
            return await context.Notifications
            .BuildBaseNotificationQuery()
            .Where(n => userIDs.Contains(n.UserID))
            .ToListAsync();
        }
        public async static Task<Notification?> Notification (int notificationID, ApplicationDbContext context)
        {
            return await context.Notifications
                .BuildBaseNotificationQuery()
                .Where(n => n.NotificationID == notificationID)
                .FirstOrDefaultAsync();
        }
        public async static Task<List<Notification>> Notification (List<int> notificationIDs, ApplicationDbContext context)
        {
            return await context.Notifications
                .BuildBaseNotificationQuery()
                .Where(n => notificationIDs.Contains(n.NotificationID))
                .ToListAsync();
        }
        public async static Task<int> Unread (int userID, int chatroomID, ApplicationDbContext context)
        {
            var chatroom = await context.Chatrooms
                .Where(c => c.IsClosed == false && c.ChatroomID == chatroomID)
                .AsNoTracking()
                .Include(c => c.Members)
                    .ThenInclude(m => m.Member)
                .Include(c => c.Messages)
                    .ThenInclude(m => m.Sender)
                .FirstOrDefaultAsync();
            int count = chatroom!.Messages.Count(m => m.SenderID != userID && m.CreatedAt > chatroom.Members.FirstOrDefault(m => m.MemberID == userID)?.LastSeenAt);
            return count;
        }
        public async static Task<List<APIKeys>> APIKeys (ApplicationDbContext context)
        {
            var APIKeys = await context.ApiKeys
                .AsNoTracking()
                .ToListAsync();
            return APIKeys;

        }public async static Task<APIKeys?> APIKey (int APIKeyID, ApplicationDbContext context)
        {
            var APIKeys = await context.ApiKeys
                .Where(a => a.APIKeyID == APIKeyID)
                .AsNoTracking()
                .FirstOrDefaultAsync();
            return APIKeys;
        }
    }
}
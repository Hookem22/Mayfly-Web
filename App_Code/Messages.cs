using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Message
/// </summary>
public class Messages : Base<Messages>
{
    public Messages() : base("Message")
    {

    }

    #region Properties

    public string EventId { get; set; }

    public string Name { get; set; }

    public string Message { get; set; }

    [NonSave]
    public DateTime? SentDate { get; set; }

    public string UserId { get; set; }

    public string FacebookId { get; set; }

    [NonSave]
    public int? Seconds { get; set; }

    [NonSave]
    public string SinceSent { get; set; }

    public string ViewedBy { get; set; }

    #endregion

    public static List<Messages> GetByEvent(string eventId)
    {
        List<Messages> messages = GetByProc("getmessages", string.Format("eventid={0}", eventId));
        AddHelperProperties(messages);
        return messages.OrderByDescending(m => m.Seconds).ToList();
    }

    private static void AddHelperProperties(List<Messages> messages)
    {
        try
        {
            foreach (Messages message in messages)
            {
                if (message.Seconds < 60)
                    message.SinceSent = "Just Now";
                else if (message.Seconds < 120)
                    message.SinceSent = "1 minute ago";
                else if (message.Seconds < 60 * 60)
                    message.SinceSent = (message.Seconds / 60).ToString() + " minutes ago";
                else if (message.Seconds < 60 * 120)
                    message.SinceSent = "1 hour ago";
                else if (message.Seconds < 60 * 60 * 24)
                    message.SinceSent = (message.Seconds / (60 * 60)).ToString() + " hours ago";
                else
                {
                    DateTime timeUtc = DateTime.SpecifyKind(Convert.ToDateTime(message.SentDate), DateTimeKind.Utc);
                    TimeZoneInfo cstZone = TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time");
                    DateTime cstTime = TimeZoneInfo.ConvertTimeFromUtc(timeUtc, cstZone);

                    message.SinceSent = cstTime.ToString("ddd h:mm tt");
                }
            }
        }
        catch (Exception ex) { }
    }

    public static void UpdateCheckedMessages(string eventId, string userId)
    {
        List<Messages> messages = GetByProc("getmessages", string.Format("eventid={0}", eventId));
        foreach (Messages message in messages)
        {
            if(string.IsNullOrEmpty(message.ViewedBy))
            {
                message.ViewedBy = userId;
                message.Save();
            }
            else if(!message.ViewedBy.Contains(userId))
            {
                message.ViewedBy += "|" + userId;
                message.Save();
            }
        }
    }


    public static bool CheckNewMessages(string eventId, string userId)
    {
        List<Messages> messages = GetByProc("getmessages", string.Format("eventid={0}", eventId));
        if (messages.Count == 0)
            return false;

        if (string.IsNullOrEmpty(messages[0].ViewedBy))
            return true;

        return !messages[0].ViewedBy.Contains(userId);
    }

    public static void SendPushMessageToEvent(Messages message)
    {
        Event evt = Event.Get(message.EventId);
        foreach (EventGoing person in evt.Going)
        {
            if (person.UserId == message.UserId)
                continue;

            string alert = evt.Name + ": " + message.Message;
            string messageText = "New Message|" + evt.Id;
            AzureMessagingService.Send(alert, messageText, person.UserId);
        }
    }

}
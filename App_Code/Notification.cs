using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Notification
/// </summary>
public class Notification : Base<Notification>
{
    public Notification() : base("Notification")
    {

    }

    #region Properties

    public string EventId { get; set; }

    public string Message { get; set; }

    public string FacebookId { get; set; }

    [NonSave]
    public int? Seconds { get; set; }

    [NonSave]
    public string SinceSent { get; set; }

    #endregion

    public static List<Notification> GetByFacebookId(string facebookId)
    {
        List<Notification> notifications = GetByProc("getnotifications", string.Format("facebookid={0}", facebookId));
        AddHelperProperties(notifications);
        return notifications;
    }

    public static Notification ReferredEvent(string referenceId, string facebookId)
    {
        List<Event> events = Event.GetByWhere(string.Format("(referenceid%20eq%20{0})", referenceId));
        if (events.Count == 1)
        {
            Event evt = events[0];
            List<Notification> notifications = Notification.GetByWhere(string.Format("(eventid%20eq%20'{0}')%20and%20(facebookid%20eq%20'{1}')", evt.Id, facebookId));
            if (notifications.Count > 0)
                return notifications[0];
            else
            {
                Notification notification = new Notification();
                notification.EventId = evt.Id;
                notification.FacebookId = facebookId;
                notification.Message = "Invited: " + evt.Name;
                notification.Save();

                return notification;
            }
        }
        return null;
    }

    private static void AddHelperProperties(List<Notification> notifications)
    {
        try
        {
            foreach (Notification notification in notifications)
            {
                if (notification.Seconds < 60)
                    notification.SinceSent = "Just Now";
                else if (notification.Seconds < 120)
                    notification.SinceSent = "1 minute ago";
                else if (notification.Seconds < 60 * 60)
                    notification.SinceSent = (notification.Seconds / 60).ToString() + " minutes ago";
                else if (notification.Seconds < 60 * 120)
                    notification.SinceSent = "1 hour ago";
                else if (notification.Seconds < 60 * 60 * 24)
                    notification.SinceSent = (notification.Seconds / (60 * 60)).ToString() + " hours ago";
                else
                    notification.SinceSent = "Yesterday";
            }
        }
        catch (Exception ex) { }
    }

}
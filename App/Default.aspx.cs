using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using Facebook;

public partial class App_Default : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            FacebookId.Value = HttpContext.Current.Session["FacebookId"].ToString();
        }
        catch { }
    }

    [WebMethod]
    public static Users GetUser(string facebookAccessToken)
    {
        var client = new FacebookClient(facebookAccessToken);
        dynamic me = client.Get("me");

        Users user = null;
        if (me != null)
            user = Users.Login(me);

        return user;
    }

    [WebMethod]
    public static Event GetEvent(string id)
    {
        return Event.Get(id);
    }

    [WebMethod]
    public static List<Event> GetEvents(string latitude, string longitude)
    {
        return Event.GetCurrent(latitude, longitude);
    }

    [WebMethod]
    public static Notification GetReferredNotification(string referenceId, string facebookId)
    {
        return Notification.ReferredEvent(referenceId, facebookId);
    }

    [WebMethod]
    public static List<Notification> GetNotifications(string facebookId)
    {
        return Notification.GetByFacebookId(facebookId);
    }

    [WebMethod]
    public static List<Location> GetLocations(string searchName, string latitude, string longitude)
    {
        return Location.SearchGooglePlaces(searchName, latitude, longitude);
    }

    [WebMethod]
    public static List<Messages> GetMessages(string eventId)
    {
        return Messages.GetByEvent(eventId);
    }

    [WebMethod]
    public static List<Users> GetFriends(string facebookAccessToken)
    {
        var client = new FacebookClient(facebookAccessToken);
        dynamic result = client.Get("me/friends");
        
        List<Users> users = new List<Users>();
        if (result != null)
        {
            foreach (var item in result.data)
            {
                Users user = new Users();
                user.Name = item.name;
                user.FacebookId = item.id;
                users.Add(user);
            }
        }
        return users.OrderBy(u => u.Name).ToList();
        
    }

    [WebMethod]
    public static Event SaveEvent(Event evt)
    {
        evt.Save();

        if(!string.IsNullOrEmpty(evt.NotificationMessage))
        {
            Notification notification = new Notification();
            notification.Message = evt.NotificationMessage;
            notification.EventId = evt.Id;
            notification.FacebookId = evt.FacebookId;
            notification.Save();
        }

        return evt;
    }

    [WebMethod]
    public static void SendInvites(Event evt)
    {
        evt.Save();
        
        string[] people = evt.FacebookId.Split('|');
        foreach (string person in people)
        {
            string[] data = person.Split(':');
            if (data.Length < 2 || string.IsNullOrEmpty(data[0]))
                continue;

            Notification.Invite(evt, data[0]);
        }
    }

    [WebMethod]
    public static void SendMessage(Messages message)
    {
        message.Save();

        Messages.SendPushMessageToEvent(message);
    }

    [WebMethod]
    public static void SendJoinMessage(string alert, string message, string facebookId, Event evt)
    {
        if(evt.Going.Contains(":"))
        {
            string organizingFbId = evt.Going.Substring(0, evt.Going.IndexOf(":"));
            if(organizingFbId != facebookId)
            {
                AzureMessagingService.Send(alert, message, organizingFbId);
            }
        }
    }

}
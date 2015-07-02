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
        string[] fbIds = evt.Invited.Split('|');
        foreach(string fbId in fbIds)
        {
            if (string.IsNullOrEmpty(fbId))
                continue;

            Notification notification = new Notification();
            notification.Message = evt.NotificationMessage;
            notification.EventId = evt.Id;
            notification.FacebookId = fbId;
            notification.Save();

            //TODO: Send push message
        }
    }

    [WebMethod]
    public static void SendMessage(Messages message)
    {
        message.Save();

        //TODO: Send push message
    }

}
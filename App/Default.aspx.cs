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

    }

    [WebMethod]
    public static string InitEvents(string pushDeviceToken, string latitude, string longitude)
    {
        Users user = Users.InitialLogin(pushDeviceToken);

        string html = "";
        double lat, lng;
        double.TryParse(latitude, out lat);
        double.TryParse(longitude, out lng);

        if (lat == 0 && lng == 0 && user != null && user.Latitude != null && user.Longitude != null)
        {
            lat = (double)user.Latitude;
            lng = (double)user.Longitude;
        }
        if (lat != 0 && lng != 0)
        {
            html = Event.GetHome(user, lat.ToString(), lng.ToString());
        }
        return html;
    }

    [WebMethod]
    public static Users LoginUser(string facebookAccessToken, string deviceId, string pushDeviceToken, string email, string password)
    {
        dynamic me = null;
        if (!string.IsNullOrEmpty(facebookAccessToken))
        {
            var client = new FacebookClient(facebookAccessToken);
            me = client.Get("me");
        }
        return Users.Login(me, deviceId, pushDeviceToken, email, password);
    }

    [WebMethod]
    public static Users SignUpUser(Users user)
    {
        return user.SignUpUser();
    }

    [WebMethod]
    public static string ForgotPassword(string email)
    {
        return Users.ForgotPassword(email);
    }

    [WebMethod]
    public static Event GetEvent(string id)
    {
        return Event.Get(id);
    }

    [WebMethod]
    public static Event GetEventByReference(int referenceId)
    {
        return Event.GetByRefernce(referenceId);
    }

    [WebMethod]
    public static string GetEvents(string latitude, string longitude, Users user)
    {
        return Event.GetHome(user, latitude, longitude);
    }

    [WebMethod]
    public static Notification GetReferredNotification(string referenceId, string userId)
    {
        return Notification.ReferredEvent(referenceId, userId);
    }

    [WebMethod]
    public static List<Group> GetGroupsByUser(string userId)
    {
        return Group.GetByUserId(userId);
    }

    [WebMethod]
    public static List<Group> GetGroups(string latitude, string longitude)
    {
        return Group.Get(latitude, longitude);
    }

    [WebMethod]
    public static Group GetGroup(string groupId, string latitude, string longitude, Users user)
    {
        return Group.Get(groupId, latitude, longitude, user);
    }

    [WebMethod]
    public static List<Notification> GetNotifications(string userId)
    {
        return Notification.GetByUserId(userId);
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
        return evt;
    }

    [WebMethod]
    public static Event SaveInvites(Event evt)
    {
        evt.SaveInvites();
        return evt;
    }

    [WebMethod]
    public static void JoinEvent(Event evt)
    {
        evt.Join();
    }

    [WebMethod]
    public static void UnjoinEvent(Event evt)
    {
        evt.Unjoin();
    }

    [WebMethod]
    public static Group SaveGroup(Group group)
    {
        group.Save();
        return group;
    }

    [WebMethod]
    public static void JoinGroup(Group group)
    {
        group.Join();
    }

    [WebMethod]
    public static void UnjoinGroup(Group group)
    {
        group.Unjoin();
    }

    [WebMethod]
    public static Users SaveUser(Users user)
    {
        user.Save();
        return user;
    }

    [WebMethod]
    public static void SendMessage(Messages message)
    {
        message.Save();
        Messages.SendPushMessageToEvent(message);
    }

    [WebMethod]
    public static void DeleteEvent(Event evt)
    {
        evt.Delete();
    }

    [WebMethod]
    public static void SendMessageToGroup(string groupId, string alert, string messageText, string userId)
    {
        Group.SendPushMessageToGroup(groupId, alert, messageText, userId);
    }

    [WebMethod]
    public static void SaveNotificationToGroup(string groupId, string message, string userId, string eventId)
    {
        Group.SaveNotificationToGroup(groupId, message, userId, eventId);
    }

}
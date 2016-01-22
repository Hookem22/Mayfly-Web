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
        if (user == null || string.IsNullOrEmpty(user.SchoolId))
        {
            user = new Users();
            double lat;
            double lng;
            if (double.TryParse(latitude, out lat))
                user.Latitude = lat;
            if (double.TryParse(longitude, out lng))
                user.Longitude = lng;

            School school = Math.Abs(lat) < 10 ? School.StEds : School.GetClosest(latitude, longitude);
            user.SchoolId = school.Id;
        }
        html = Event.GetHome(user);
        return html;
    }

    [WebMethod]
    public static Users LoginUser(string facebookAccessToken, string deviceId, string pushDeviceToken, string email, bool isiOS)
    {
        dynamic me = null;
        if (!string.IsNullOrEmpty(facebookAccessToken))
        {
            try
            {
                var client = new FacebookClient(facebookAccessToken);
                me = client.Get("me");

            }
            catch { }
        }
        return Users.Login(me, deviceId, pushDeviceToken, email, isiOS);
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
        return Event.GetByReference(referenceId);
    }

    [WebMethod]
    public static string GetEvents(Users user, string latitude, string longitude)
    {
        return Event.GetHome(user);
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
    public static List<Group> GetGroups(string schoolId)
    {
        return Group.GetBySchoolId(schoolId);
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
    public static School GetSchool(Users user)
    {
        School school = School.GetClosest(user.Latitude.ToString(), user.Longitude.ToString());
        if(!string.IsNullOrEmpty(user.SchoolId) && school != null && user.SchoolId != school.Id)
        {
            user.SchoolId = school.Id;
            user.Save();
        }
        return school;
    }

    [WebMethod]
    public static List<Users> GetFriends(string facebookAccessToken)
    {
        try
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
        catch { }
        return null;
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
    public static void SaveGroupInvites(List<EventInvited> invites, string message)
    {
        Group.SaveGroupInvites(invites, message);
    }

    [WebMethod]
    public static Event AddGroupsToEvent(Event evt)
    {
        evt.SaveGroups();
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
    public static void UpdateCheckedMessages(string eventId, string userId)
    {
        Messages.UpdateCheckedMessages(eventId, userId);
    }

    [WebMethod]
    public static bool CheckNewMessages(string eventId, string userId)
    {
        return Messages.CheckNewMessages(eventId, userId);
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
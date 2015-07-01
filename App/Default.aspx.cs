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
    public static void SaveEvent(Event evt)
    {
        evt.Save();
        Notification notification = new Notification();
        notification.Message = "Created: " + evt.Name;
        notification.EventId = evt.Id;
        notification.FacebookId = evt.Going;
        notification.Save();
    }
}
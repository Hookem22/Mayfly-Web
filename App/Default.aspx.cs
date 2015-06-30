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
    public static List<Event> GetEvents(string latitude, string longitude)
    {
        return Event.GetCurrent(latitude, longitude);
    }

    [WebMethod]
    public static Users GetUser(string facebookAccessToken)
    {
        var client = new FacebookClient(facebookAccessToken);
        dynamic me = client.Get("me");
        //Image = https://graph.facebook.com/id/picture?type=large

        Users user = null;
        if (me != null)
            user = Users.Login(me);

        return user;
    }
}
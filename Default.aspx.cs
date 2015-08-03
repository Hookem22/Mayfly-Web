using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class _Default : System.Web.UI.Page
{
    protected void Page_PreInit(object sender, EventArgs e)
    {
        if (Request.Url.Host.StartsWith("www") && !Request.Url.IsLoopback)
        {
            UriBuilder builder = new UriBuilder(Request.Url);
            builder.Host = Request.Url.Host.Substring(Request.Url.Host.IndexOf("www.") + 4);
            Response.Redirect(builder.ToString(), true);
        }
    }
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    [WebMethod]
    public static void Login(string facebookId)
    {
        HttpContext.Current.Session["FacebookId"] = facebookId;
    }
}
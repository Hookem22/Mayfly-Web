using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Interns_Default : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    [WebMethod]
    public static string GetInternHtml()
    {
        return Users.GetInternHtml("E1668987-C219-484C-B5BB-1ACACDCADE17");
    }
}
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Meetup_Default : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    [WebMethod]
    public static MeetupService.Meetup AuthorizeMeetup(string code)
    {
        MeetupService.Meetup meet = MeetupService.Authorize(code);
        MeetupService.GetMember(meet);
        MeetupService.GetGroups(meet);
        MeetupService.GetEvents(meet);
        return meet;
    }
}
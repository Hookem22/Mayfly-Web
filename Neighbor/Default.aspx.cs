using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Admin_Default : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    [WebMethod]
    public static void AddGroupAdmin(string groupId, string userId)
    {
        GroupUsers user = GroupUsers.Get(groupId, userId);
        if (user == null)
            user = new GroupUsers(groupId, userId, true);
        else
            user.IsAdmin = true;

        user.Save();
    }

}
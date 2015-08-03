using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Users
/// </summary>
public class Users : Base<Users>
{
    public Users() : base("Users")
    {

    }

    #region Properties

    public string Name { get; set; }

    [NonSave]
    public string FirstName { get; set; }

    public string DeviceId { get; set; }

    public string PushDeviceToken { get; set; }

    public string FacebookId { get; set; }

    public string Email { get; set; }

    #endregion

    public static Users Login(dynamic me)
    {
        Users user = GetByFacebookId(me.id);
        if(user == null)
        {
            user = new Users();
            user.FacebookId = me.id;
            user.Name = me.name;
            user.FirstName = me.first_name;
            user.Email = me.email;
            user.Save();
        }
        user.FirstName = me.first_name;
        return user;
    }

    public static Users GetByFacebookId(string facebookId)
    {
        List<Users> users = GetByWhere(string.Format("(facebookid%20eq%20{0})", facebookId));
        if (users.Count > 0)
            return users[0];
        else
            return null;
    }
}
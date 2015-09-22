using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Group
/// </summary>
public class Group : Base<Group>
{
    public Group() : base("Group")
    {

    }

    #region Properties

    public string Name { get; set; }

    public string Description { get; set; }

    public string PictureUrl { get; set; }

    public double Latitude { get; set; }

    public double Longitude { get; set; }

    public string City { get; set; }

    public bool IsPublic { get; set; }

    public string Password { get; set; }

    [NonSave]
    public List<GroupUsers> Members { get; set; }

    [NonSave]
    public string UserId { get; set; }

    [NonSave]
    public string EventsHtml { get; set; }

    #endregion

    public static Group Get(string id, string latitude, string longitude, Users user)
    {
        Group group = Base<Group>.Get(id);
        group.Members = GroupUsers.GetByGroup(id);
        group.EventsHtml = Event.GetByGroup(id, latitude, longitude, user);
        return group;
    }

    public static List<Group> GetByUserId(string userId)
    {
        return GetByProc("getgroupsbyuser", string.Format("userid={0}", userId));
    }

    public static List<Group> Get(string latitude, string longitude)
    {
        return GetByProc("getgroups", string.Format("latitude={0}&longitude={1}", latitude, longitude));
    }

    public new void Save()
    {
        base.Save();

        if (!string.IsNullOrEmpty(this.UserId))
        {
            GroupUsers going = new GroupUsers(this.Id, this.UserId, true);
            going.Save();
        }
    }

    public void Join()
    {
        GroupUsers users = GroupUsers.Get(this.Id, this.UserId, true);
        if (users != null)
        {
            users.Undelete();
        }
        else
        {
            users = new GroupUsers(this.Id, this.UserId, false);
            users.Save();
        }
    }

    public void Unjoin()
    {
        GroupUsers users = GroupUsers.Get(this.Id, this.UserId);
        users.Delete();
    }

    public static void SendPushMessageToGroup(string groupId, string alert, string messageText, string userId)
    {
        foreach (GroupUsers user in GroupUsers.GetByGroup(groupId))
        {
            if (user.UserId == userId)
                continue;

            AzureMessagingService.Send(alert, messageText, user.UserId);
        }
    }
}
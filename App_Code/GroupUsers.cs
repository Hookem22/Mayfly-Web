using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for GroupUsers
/// </summary>
public class GroupUsers : Base<GroupUsers>
{
    public GroupUsers() : base("GroupUsers")
    {
    }
    public GroupUsers(string groupId, string userId, bool isAdmin) : base("GroupUsers")
    {
        GroupId = groupId;
        UserId = userId;
        IsAdmin = isAdmin;
    }
    #region Properties

    public string GroupId { get; set; }

    public string UserId { get; set; }

    public bool IsAdmin { get; set; }

    [NonSave]
    public string FirstName { get; set; }

    [NonSave]
    public string FacebookId { get; set; }

    #endregion

    public static List<GroupUsers> GetByGroup(string groupId)
    {
        List<GroupUsers> users = GetByProc("getgroupusers", string.Format("groupid={0}", groupId));
        return users;
    }

    public static GroupUsers Get(string groupId, string userId, bool includeDeleted = false)
    {
        if (!includeDeleted)
        {
            List<GroupUsers> users = GetByWhere(string.Format("(groupid%20eq%20'{0}')%20and%20(userid%20eq%20'{1}')", groupId, userId));
            if (users.Count > 0)
                return users[0];
        }
        else
        {
            List<GroupUsers> users = GetByProc("getgroupusersdeleted", string.Format("groupid={0}&userid={1}", groupId, userId));
            if (users.Count > 0)
                return users[0];
        }

        return null;
    }

    public void Undelete()
    {
        GetByProc("undeletegroupusers", string.Format("groupid={0}&userid={1}", this.GroupId, this.UserId));
    }
}
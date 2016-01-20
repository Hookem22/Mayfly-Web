using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for EventInvited
/// </summary>
public class EventInvited : UsersPartial<EventInvited>
{
    static string _tableName = "EventInvited";

    public EventInvited()
        : base(_tableName)
    {
    }
    public EventInvited(string eventId, string facebookId, string name, string invitedBy)
        : base(eventId, "", _tableName)
    {
        FacebookId = facebookId;
        Name = name;
        InvitedBy = invitedBy;
    }

    public new string FacebookId { get; set; }

    public string Name { get; set; }

    public string InvitedBy { get; set; }

    public static List<EventInvited> GetByEvent(string eventId)
    {
        return GetByEvent(eventId, "getinvitedbyevent");
    }

    public static List<string> GetByUser(string facebookId)
    {
        List<EventInvited> users = GetByProcFast("getinvitedbyuser", string.Format("userid={0}", facebookId));
        List<string> ids = new List<string>();
        foreach (EventInvited u in users)
            ids.Add(u.EventId);

        return ids;
    }

    public static EventInvited Get(string eventId, string userId, bool includeDeleted = false)
    {
        string procName = includeDeleted ? "getinviteddeleted" : "";
        return Get(eventId, userId, procName);
    }

    public static List<EventInvited> GetByInvitedBy(string invitedById)
    {
        List<EventInvited> invited = GetByWhere(string.Format("(invitedby%20eq%20'{0}')", invitedById));
        return invited;
    }

    public void Undelete()
    {
        Undelete("undeleteinvited");
    }

}
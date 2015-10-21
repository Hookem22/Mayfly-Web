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
    public EventInvited(string eventId, string facebookId, string name)
        : base(eventId, "", _tableName)
    {
        FacebookId = facebookId;
        Name = name;
    }

    public new string FacebookId { get; set; }

    public string Name { get; set; }

    public static List<EventInvited> GetByEvent(string eventId)
    {
        return GetByEvent(eventId, "getinvitedbyevent");
    }

    public static List<string> GetByUser(string facebookId)
    {
        return GetByUser(facebookId, "getinvitedbyuser");
    }

    public static EventInvited Get(string eventId, string userId, bool includeDeleted = false)
    {
        string procName = includeDeleted ? "getinviteddeleted" : "";
        return Get(eventId, userId, procName);
    }

    public void Undelete()
    {
        Undelete("undeleteinvited");
    }

}
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for EventGoing
/// </summary>
public class EventGoing : UsersPartial<EventGoing>
{
    static string _tableName = "EventGoing";

    public EventGoing()
        : base(_tableName)
    {
    }
    public EventGoing(string eventId, string userId, bool isAdmin)
        : base(eventId, userId, _tableName)    
    {
        IsAdmin = isAdmin;
    }

    public bool IsAdmin { get; set; }

    public static List<EventGoing> GetByEvent(string eventId)
    {
        return GetByEvent(eventId, "getgoingbyevent");
    }

    public static List<string> GetByUser(string userId)
    {
        return GetByUser(userId, "getgoingbyuser");
    }

    public static EventGoing Get(string eventId, string userId, bool includeDeleted = false)
    {
        string procName = includeDeleted ? "getgoingdeleted" : "";
        return Get(eventId, userId, procName);
    }

    public void Undelete()
    {
        Undelete("undeletegoing");
    }

}
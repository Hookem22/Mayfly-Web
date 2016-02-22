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
    public EventGoing(string eventId, string userId, bool isAdmin, bool isMuted)
        : base(eventId, userId, _tableName)    
    {
        IsAdmin = isAdmin;
        isMuted = isMuted;
    }

    public bool IsAdmin { get; set; }

    public bool IsMuted { get; set; }

    public DateTime? CheckedMessagesAt { get; set; }

    public static List<EventGoing> GetByEvent(string eventId)
    {
        return GetByEvent(eventId, "getgoingbyevent");
    }

    public static List<string> GetByUser(string userId)
    {
        List<EventGoing> users = GetByProcFast("getgoingbyuser", string.Format("userid={0}", userId));
        List<string> ids = new List<string>();
        foreach (EventGoing u in users)
            ids.Add(u.EventId);

        return ids;
    }

    public static List<EventGoing> GetEventGoingByUser(string userId)
    {
        List<EventGoing> going = GetByProcFast("getgoingbyuser", string.Format("userid={0}", userId));
        return going;
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
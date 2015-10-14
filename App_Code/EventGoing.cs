using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for EventGoing
/// </summary>
public class EventGoing : Base<EventGoing>
{
    public EventGoing() : base("EventGoing")
    {
    }
    public EventGoing(string eventId, string userId, bool isAdmin) : base("EventGoing")
    {
        EventId = eventId;
        UserId = userId;
        IsAdmin = isAdmin;
    }

    #region Properties

    public string EventId { get; set; }

    public string UserId { get; set; }

    [NonSave]
    public string FirstName { get; set; }

    [NonSave]
    public string FacebookId { get; set; }

    public bool IsAdmin { get; set; }

    #endregion

    public static List<EventGoing> GetByEvent(string eventId)
    {
        return GetByProcFast("getgoingbyevent", string.Format("eventid={0}", eventId));
    }

    public static List<string> GetByUser(string userId)
    {
        List<EventGoing> going = GetByProcFast("getgoingbyuser", string.Format("userid={0}", userId));
        List<string> goingIds = new List<string>();
        foreach (EventGoing eg in going)
            goingIds.Add(eg.EventId);

        return goingIds;
    }

    public static EventGoing Get(string eventId, string userId, bool includeDeleted = false)
    {
        if (!includeDeleted)
        {
            List<EventGoing> going = GetByWhere(string.Format("(eventid%20eq%20'{0}')%20and%20(userid%20eq%20'{1}')", eventId, userId));
            if (going.Count > 0)
                return going[0];
        }
        else
        {
            List<EventGoing> going = GetByProc("getgoingdeleted", string.Format("eventid={0}&userid={1}", eventId, userId));
            if (going.Count > 0)
                return going[0];
        }

        return null;
    }

    public void Undelete()
    {
        GetByProc("undeletegoing", string.Format("eventid={0}&userid={1}", this.EventId, this.UserId));
    }

}
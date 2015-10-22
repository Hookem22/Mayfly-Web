using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for UsersPartial
/// </summary>
public abstract class UsersPartial<T> : Base<T>
{
	public UsersPartial(string tableName) : base(tableName)
	{
	}

    public UsersPartial(string eventId, string userId, string tableName)
        : base(tableName)
    {
        EventId = eventId;
        UserId = userId;
    }

    #region Properties

    public string EventId { get; set; }

    public string UserId { get; set; }

    [NonSave]
    public string FirstName { get; set; }

    [NonSave]
    public string FacebookId { get; set; }

    #endregion

    public static List<T> GetByEvent(string eventId, string procName)
    {
        return GetByProcFast(procName, string.Format("eventid={0}", eventId));
    }

    public static T Get(string eventId, string userId, string includeDeletedProc = "")
    {
        if (string.IsNullOrEmpty(includeDeletedProc))
        {
            List<T> users = GetByWhere(string.Format("(eventid%20eq%20'{0}')%20and%20(userid%20eq%20'{1}')", eventId, userId));
            if (users.Count > 0)
                return users[0];
        }
        else
        {
            List<T> users = GetByProc(includeDeletedProc, string.Format("eventid={0}&userid={1}", eventId, userId));
            if (users.Count > 0)
                return users[0];
        }

        return default(T);
    }

    public void Undelete(string procName)
    {
        GetByProc(procName, string.Format("eventid={0}&userid={1}", this.EventId, this.UserId));
    }
}
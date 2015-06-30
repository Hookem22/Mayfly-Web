using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Message
/// </summary>
public class Messages : Base<Messages>
{
    public Messages() : base("Message")
    {

    }

    #region Properties

    public string EventId { get; set; }

    public string Name { get; set; }

    public string Message { get; set; }

    public DateTime SentDate { get; set; }

    public string FacebookId { get; set; }

    public int? Seconds { get; set; }

    #endregion

    public static List<Messages> GetByEvent(string eventId)
    {
        return GetByProc("getmessages", string.Format("eventid={0}", eventId));
    }

}
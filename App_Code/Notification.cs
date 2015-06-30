using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Notification
/// </summary>
public class Notification : Base<Notification>
{
    public Notification() : base("Notification")
    {

    }

    #region Properties

    public string EventId { get; set; }

    public string Message { get; set; }

    public string FacebookId { get; set; }

    #endregion

    public static List<Notification> GetByFacebookId(string facebookId)
    {
        return GetByProc("getnotifications", string.Format("facebookid={0}", facebookId));
    }

}
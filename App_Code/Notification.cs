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

    //public int Seconds { get; set; }

    //public string SinceSent
    //{
    //    get
    //    {
    //        if (Seconds < 60)
    //            return "Just Now";
    //        if (Seconds < 120)
    //            return "1 minute ago";
    //        if (Seconds < 60 * 60)
    //            return (Seconds / 60).ToString() + " minutes ago";
    //        if (Seconds < 60 * 120)
    //            return "1 hour ago";
    //        if(Seconds < 60 * 60 * 24)
    //            return (Seconds / (60 * 60)).ToString() + " hours ago";
            
    //        return "Yesterday";
    //    }
    //}

    #endregion

    public static List<Notification> GetByFacebookId(string facebookId)
    {
        return GetByProc("getnotifications", string.Format("facebookid={0}", facebookId));
    }

}
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Device.Location;

/// <summary>
/// Summary description for Event
/// </summary>
public class Event : Base<Event>
{
    public Event() : base("Event")
    {

    }

    #region Properties

    public string Name { get; set; }

    public string Description { get; set; }

    public string GroupId { get; set; }

    public string GroupName { get; set; }

    public string GroupPictureUrl { get; set; }

    public bool? GroupIsPublic { get; set; }

    public string LocationName { get; set; }

    public string LocationAddress { get; set; }

    public double LocationLatitude { get; set; }

    public double LocationLongitude { get; set; }

    public string SchoolId { get; set; }

    public int MinParticipants { get; set; }

    public int MaxParticipants { get; set; }

    public string StartTime { get; set; }

    public int? DayOfWeek { get; set; } /* Sunday = 0, Monday = 1, etc. */

    public string LocalTime { get; set; }

    [NonSave]
    public bool? IsGoing { get; set; }

    [NonSave]
    public List<EventGoing> Going { get; set; }

    [NonSave]
    public bool? IsInvited { get; set; }

    [NonSave]
    public List<EventInvited> Invited { get; set; }

    [NonSave]
    public bool? IsAdmin { get; set; }

    [NonSave]
    public int? ReferenceId { get; set; }

    [NonSave]
    public string Distance { get; set; }

    [NonSave]
    public string NotificationMessage { get; set; }

    [NonSave]
    public string UserId { get; set; }

    [NonSave]
    public string LocalDayTime { get; set; }
    
    [NonSave]
    public string DayLabel { get; set; }

    [NonSave]
    public string ShortDayLabel { get; set; }

    [NonSave]
    public string LocalDate { get; set; }

    #endregion

    public static new Event Get(string id)
    {
        Event evt = Base<Event>.Get(id);
        evt.Description = evt.Description.Replace("\n", "<br/>");
        evt.Going = EventGoing.GetByEvent(evt.Id);
        evt.Invited = EventInvited.GetByEvent(evt.Id);

        return evt;
    }

    public static string GetHome(Users user)
    {
        List<Event> events = GetByProcFast("geteventsbyschoolid", string.Format("schoolid={0}", user.SchoolId));
        if (events.Count == 0)
            return defaultHomeHtml;
        AddHelperProperties(events);
        return GetHomeHtml(events, user);
    }

    public static string GetByGroup(string groupId, string latitude, string longitude, Users user)
    {
        List<Event> events = GetByProc("geteventsbygroup", string.Format("groupid={0}", groupId));
        if(events.Count > 0)
        {
            AddHelperProperties(events);
            return GetGroupEventsHtml(events, user);
        }
        return "";
    }

    public static List<Event> GetByUser(string userId)
    {
        return GetByProc("geteventsbyuser", string.Format("userid={0}", userId));
    }

    public new void Save()
    {
        //TODO: hack to create events
        bool saveParticipants = true;
        if(this.MinParticipants < 0)
        {
            this.MinParticipants = 0;
            saveParticipants = false;
        }
        
        base.Save();

        if(!string.IsNullOrEmpty(this.UserId) && saveParticipants)
        {
            EventGoing going = new EventGoing(this.Id, this.UserId, true);
            going.Save();

            //Users user = Users.Get(this.UserId);
            //if(user != null)
            //{
            //    EventInvited invited = new EventInvited(this.Id, user.FacebookId, user.FirstName, "");
            //    invited.UserId = null;
            //    invited.Save();
            //}
        }

        if (!string.IsNullOrEmpty(this.NotificationMessage))
        {
            Notification notification = new Notification(this.Id, this.UserId, this.NotificationMessage);
            notification.Save();
        }

        if(!string.IsNullOrEmpty(this.GroupId))
        {
            string[] ids = this.GroupId.Split('|');
            foreach (string id in ids)
            {
                SendToGroup(id);
            }
        }
    }

    public void SaveGroups()
    {
        Event evt = Event.Get(this.Id);
        string[] ids = this.GroupId.Split('|');
        foreach (string id in ids)
        {
            if (!string.IsNullOrEmpty(evt.GroupId) && evt.GroupId.Contains(id))
            {
                SendToGroup(id);
            }
        }

        base.Save();
    }

    public void SendToGroup(string groupId)
    {
        Group group = Group.Get(groupId);
        foreach (GroupUsers user in GroupUsers.GetByGroup(groupId))
        {
            if (user.UserId == this.UserId)
                continue;

            string msg = "New event in your group " + group.Name;
            AzureMessagingService.Send(msg, "", user.UserId);

            msg = "New: " + this.Name;
            Notification notification = new Notification(this.Id, user.UserId, msg);
            notification.Save();
        }
    }

    public void SaveInvites()
    {
        foreach (EventInvited invite in this.Invited)
        {
            if (string.IsNullOrEmpty(invite.Id))
            {
                EventInvited invited = new EventInvited(this.Id, invite.FacebookId, invite.Name, invite.InvitedBy);
                if (string.IsNullOrEmpty(invite.FacebookId))
                {
                    invited.UserId = "";
                    invited.Save();
                }
                else
                {
                    Users user = Users.GetByFacebookId(invite.FacebookId);
                    if(user != null)
                    {
                        invited.UserId = user.Id;
                        invited.Save();
                        
                        Notification notification = new Notification(this.Id, user.Id, this.NotificationMessage);
                        notification.Save();

                        string messageText = "New Message|" + this.Id;
                        AzureMessagingService.Send(this.NotificationMessage, messageText, user.Id);
                    }
                }
            }
        }
    }

    public void Join()
    {
        EventGoing going = EventGoing.Get(this.Id, this.UserId, true);
        if(going != null)
        {
            going.Undelete();
        }
        else
        {
            going = new EventGoing(this.Id, this.UserId, false);
            going.Save();
        }

        if (!string.IsNullOrEmpty(this.NotificationMessage))
        {
            Notification notification = new Notification(this.Id, this.UserId, this.NotificationMessage);
            notification.Save();
        }

        //TODO Send messages that someone joined your event
    }

    public void Unjoin()
    {
        EventGoing going = EventGoing.Get(this.Id, this.UserId);
        going.Delete();

        if (!string.IsNullOrEmpty(this.NotificationMessage))
        {
            Notification notification = new Notification(this.Id, this.UserId, this.NotificationMessage);
            notification.Save();
        }
    }

    public static Event GetByReference(int referenceId)
    {
        List<Event> events = GetByWhere(string.Format("(referenceid%20eq%20{0})", referenceId));
        if (events.Count > 0)
            return events[0];

        return null;
    }

    private static void AddHelperProperties(List<Event> events)
    {
        TimeZoneInfo cstZone = TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time");
        DateTime today = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, cstZone);

        foreach (Event evt in events)
        {
            evt.Going = EventGoing.GetByEvent(evt.Id);
            if (evt.DayOfWeek != null)
            {
                string[] daysShort = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
                //evt.LocalDayTime = daysShort[(int)evt.DayOfWeek] + " " + evt.LocalTime;

                string[] days = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };
                //evt.DayLabel = days[(int)evt.DayOfWeek];

                DateTime timeUtc = DateTime.SpecifyKind(Convert.ToDateTime(evt.StartTime), DateTimeKind.Utc);
                DateTime cstTime = TimeZoneInfo.ConvertTimeFromUtc(timeUtc, cstZone);
                evt.DayLabel = string.Format("{0}, {1}", days[(int)evt.DayOfWeek], cstTime.ToString("MMM d"));
                evt.ShortDayLabel = string.Format("{0}, {1}", daysShort[(int)evt.DayOfWeek], cstTime.ToString("MMM d"));

                if (today.ToString("MM/d") == cstTime.ToString("MM/d"))
                    evt.DayLabel = "Today";
                else if (today.AddDays(1).ToString("MM/d") == cstTime.ToString("MM/d"))
                    evt.DayLabel = "Tomorrow";
            }
            if (evt.GroupIsPublic == null)
                evt.GroupIsPublic = true;
        }
        
    }

    private static string DistanceLabel(double meters)
    {
        double miles = meters * 0.000621371;
        if (miles < 1)
            return "< 1 mile away";
        else if (miles < 1.5)
            return "1 mile away";
        else
            return string.Format("{0} miles away", Math.Round(miles));
    }

    private static string GetHomeHtml(List<Event> events, Users user)
    {

        if (user != null)
            events = ReorderEvents(events, user);

        string html = string.Format("<div class='dayHeader'><div></div><div>{0}</div></div>", events[0].DayLabel);

        Random rnd = new Random();
        int i = 0;
        foreach (Event evt in events)
        {            
            if (i > 0 && events[i - 1].DayLabel != events[i].DayLabel)
                html += string.Format("<div class='dayHeader'><div></div><div>{0}</div></div>", events[i].DayLabel);
            string addClass = "";
            if(i == 0 || events[i - 1].DayOfWeek != events[i].DayOfWeek)
                addClass = "first";
            if (i == events.Count - 1 || events[i].DayOfWeek != events[i + 1].DayOfWeek)
                addClass += " last";

            string groupHtml = "<div eventid='{EventId}' class='homeList event {Class}'>{img}<div class='name'>{Name}</div>{Group}<div class='details'>{Details}</div><div class='day'>{StartDay}</div><div class='lit'>{Lit}</div></div>";
            string details = ""; //AddGoing(evt);
            //details += ge.Events.Count > 1 ? ", and " + (ge.Events.Count - 1).ToString() + " more..." : " " + evt.Distance;

            groupHtml = groupHtml.Replace("{EventId}", evt.Id).Replace("{Class}", addClass).Replace("{Name}", evt.Name).Replace("{Details}", details).Replace("{StartDay}", evt.LocalTime).Replace("{Group}", AddGroups(evt));
            string img = "<img src='../Img/group.png' />";
            if (!string.IsNullOrEmpty(evt.GroupPictureUrl))
            {
                if(evt.GroupPictureUrl.Contains(".com"))
                    img = string.Format("<img src='{0}' onerror=\"this.src='../Img/group.png';\" />", evt.GroupPictureUrl);
                else
                    img = string.Format("<img src='../Img/Event Icons/{0}.png' onerror=\"this.src='../Img/group.png';\" />", evt.GroupPictureUrl);
            }

            if (evt.IsGoing != null && evt.IsGoing == true)
                img += "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            else if (evt.IsInvited != null && evt.IsInvited == true)
                img += "<div class='invitedIcon icon'><img src='/Img/invited.png'></div>";

            groupHtml = groupHtml.Replace("{img}", img);

            string lit = "";
            if (evt.Going.Count > 4)
                lit += "<img src='../Img/match.png' style='position: absolute;right: 20px;top: 35px;height: 35px;' />";
            if (evt.Going.Count > 9)
                lit += "<img src='../Img/match.png' style='position: absolute;right: 40px;top: 35px;height: 35px;' />";
            if (evt.Going.Count > 19)
                lit += "<img src='../Img/match.png' style='position: absolute;right: 60px;top: 35px;height: 35px;' />";
            if (evt.Going.Count > 39)
                lit += "<img src='../Img/match.png' style='position: absolute;right: 80px;top: 35px;height: 35px;' />";

            groupHtml = groupHtml.Replace("{Lit}", lit);
           
            html += groupHtml;
            //string img = "<img src='../Img/face" + rnd.Next(8) + ".png' />";
            //if (!string.IsNullOrEmpty(evt.GroupId))
            //    img = string.Format("<img src='{0}' onerror=\"this.src='../Img/group.png';\" />", evt.GroupPictureUrl);
            //if (evt.IsGoing != null && (bool)evt.IsGoing && !string.IsNullOrEmpty(user.FacebookId))
            //    img = "<img class='fbPic' src='https://graph.facebook.com/" + user.FacebookId + "/picture' />" + "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            //else if (evt.IsGoing != null && (bool)evt.IsGoing)
            //    img = "<img src='../Img/face" + rnd.Next(8) + ".png' /><div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            //else if (evt.IsInvited != null && (bool)evt.IsInvited)
            //    img = "<img src='../Img/invited.png' />";


            i++;
        }

        return html;
    }

    private static string GetGroupEventsHtml(List<Event> events, Users user)
    {
        if (user != null)
            events = ReorderEvents(events, user);

        string html = "";
        Random rnd = new Random();
        foreach (Event evt in events)
        {
            string eventHtml = "<div eventid='{EventId}' class='homeList event'>{img}<div class='name'>{Name}</div><div class='details'>{Details}</div><div class='day'>{StartDay}</div><div class='time'>{StartTime}</div></div>";
            eventHtml = eventHtml.Replace("{EventId}", evt.Id).Replace("{Name}", evt.Name).Replace("{Details}", evt.Distance).Replace("{StartDay}", string.Format("{0}<br/>{1}", evt.ShortDayLabel, evt.LocalTime)).Replace("{StartTime}", "" /*"{{" + evt.StartTime.ToString() + "}}"*/);
            
            string img = "<img src='../Img/group.png' />";
            if (!string.IsNullOrEmpty(evt.GroupPictureUrl))
            {
                if (evt.GroupPictureUrl.Contains(".com"))
                    img = string.Format("<img src='{0}' onerror=\"this.src='../Img/group.png';\" />", evt.GroupPictureUrl);
                else
                    img = string.Format("<img src='../Img/Event Icons/{0}.png' onerror=\"this.src='../Img/group.png';\" />", evt.GroupPictureUrl);
            }

            if (evt.IsGoing != null && (bool)evt.IsGoing)
                img += "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            else if (evt.IsInvited != null && (bool)evt.IsInvited)
                img += "<div class='invitedIcon icon'><img src='/Img/invited.png'></div>";

            eventHtml = eventHtml.Replace("{img}", img);
            html += eventHtml;
        }

        return html;
    }

    private static List<Event> ReorderEvents(List<Event> events, Users user)
    {
        List<Event> publicEvents = new List<Event>();
        if (user == null || user.Id == null)
        {
            foreach (Event evt in events)
            {
                evt.IsGoing = false;
                evt.IsInvited = false;
                if (evt.GroupIsPublic == true)
                    publicEvents.Add(evt);
            }
            return publicEvents;
        }
        
        List<string> goingIds = EventGoing.GetByUser(user.Id);
        List<string> invitedIds = EventInvited.GetByUser(user.FacebookId);
        foreach(Event evt in events)
        {
            if (goingIds.Contains(evt.Id))
                evt.IsGoing = true;
            if (invitedIds.Contains(evt.Id))
                evt.IsInvited = true;
            if (evt.GroupIsPublic == true || evt.IsGoing == true || evt.IsInvited == true)
                publicEvents.Add(evt);
        }
        return publicEvents;

        //List<Event> eventGoing = new List<Event>();
        //List<Event> eventInvited = new List<Event>();
        //List<Event> eventOther = new List<Event>();

        //foreach(Event evt in events)
        //{
        //    bool isGoing = false;
        //    foreach (EventGoing going in evt.Going)
        //    {
        //        if (user.Id == going.UserId)
        //        {
        //            isGoing = true;
        //            break;
        //        }
        //    }
        //    if (isGoing)
        //    {
        //        evt.IsGoing = true;
        //        eventGoing.Add(evt);
        //    }
        //    else
        //    {
        //        evt.IsGoing = false;
        //        eventOther.Add(evt);
        //    }
        //    bool isInvited = false;
        //    foreach (EventInvited invited in evt.Invited)
        //    {
        //        if (user.FacebookId == invited.FacebookId)
        //        {
        //            isInvited = true;
        //            break;
        //        }
        //    }
        //    if (isInvited)
        //    {
        //        evt.IsInvited = true;
        //        eventInvited.Add(evt);
        //    }
        //    else
        //    {
        //        evt.IsInvited = false;
        //        eventOther.Add(evt);
        //    } 
        //}

        ////events = eventGoing;
        ////events.AddRange(eventOther);
        //return events;
    }

    private static string AddGroups(Event evt)
    {
        //Remove hashtags
        return "";
        
        if (string.IsNullOrEmpty(evt.GroupId))
            return "";

        string html = evt.GroupIsPublic == false ? "<div class='groupList private'>" : "<div class='groupList'>";
        if(!string.IsNullOrEmpty(evt.GroupId) && !evt.GroupId.Contains('|') && !string.IsNullOrEmpty(evt.GroupName))
        {
            html += evt.GroupIsPublic == true ? "<a class='group' groupid='{GroupId}' >#{Group}</a></div>" : "<a class='group private' groupid='{GroupId}' >#{Group}</a></div>";
            html = html.Replace("{GroupId}", evt.GroupId).Replace("{Group}", evt.GroupName);
            return html;
        }

        try
        {
            string[] groupIds = evt.GroupId.Split('|');
            string[] groupNames = evt.GroupName.Split('|');
            for (int i = 0; i < groupIds.Length; i++)
            {
                html += evt.GroupIsPublic == true ? "<a class='group' groupid='{GroupId}' >#{Group}</a>" : "<a class='group private' groupid='{GroupId}' >#{Group}</a>";
                html = html.Replace("{GroupId}", groupIds[i]).Replace("{Group}", groupNames[i]);
            }
        }
        catch { }

        html += "</div>";
        return html;
    }

    private static string AddGoing(Event evt)
    {
        string html = "<div class='homeGoing'>";
        Random rnd = new Random();
        foreach (EventGoing going in evt.Going)
        {
            if (!string.IsNullOrEmpty(going.FacebookId))
                html += "<img src='https://graph.facebook.com/" + going.FacebookId + "/picture' />";
            else
                html += "<img style='height: 25px;margin: -3px 0;' src='../Img/face" + rnd.Next(8) + ".png' />";
        }
        html += "</div>";
        return html;
    }

    private static string defaultHomeHtml = "<div style='background-color: white;margin: 15px 12px;padding: 34px 24px;box-shadow: 0 1px 2px 0 rgba(0,0,0,0.22);border-radius: 6px;'><div style='text-align: center;color: #555;'><div style='font-size: 1.5em;'>Welcome to Pow Wow!</div><div style='font-size: 1.1em;margin: .8em 32px;line-height: 1.4em;'>The place to find events near you today</div><div style='font-size: 1.25em;line-height: 1.8em;'><a style='color: #4285F4;' onclick='OpenAdd();'>Create an Event</a><br/>or<br/><a style='color: #4285F4;' onclick='OpenGroups();'>Join a Group</a></div></div></div>";

}
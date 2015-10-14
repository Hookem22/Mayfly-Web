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

    public string LocationName { get; set; }

    public string LocationAddress { get; set; }

    public double LocationLatitude { get; set; }

    public double LocationLongitude { get; set; }

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
    public int? ReferenceId { get; set; }

    [NonSave]
    public string Distance { get; set; }

    [NonSave]
    public string NotificationMessage { get; set; }

    [NonSave]
    public string UserId { get; set; }

    [NonSave]
    public string GroupName { get; set; }

    [NonSave]
    public string GroupPictureUrl { get; set; }

    [NonSave]
    public string LocalDayTime { get; set; }
    
    [NonSave]
    public string DayLabel { get; set; }

    #endregion

    public static new Event Get(string id)
    {
        Event evt = Base<Event>.Get(id);
        evt.Description = evt.Description.Replace("\n", "<br/>");
        evt.Going = EventGoing.GetByEvent(evt.Id);
        //if(!string.IsNullOrEmpty(evt.GroupId))
        //{
        //    Group group = Group.Get(evt.GroupId);
        //    if (group != null)
        //        evt.GroupName = group.Name;
        //}
        return evt;
    }

    public static string GetHome(Users user, string latitude, string longitude)
    {
        List<Event> events = GetByProcFast("geteventswithgroups", string.Format("latitude={0}&longitude={1}", latitude, longitude));
        if (events.Count == 0)
            return defaultHomeHtml;
        AddHelperProperties(events, latitude, longitude);
        return GetHomeHtml(events, user);
    }

    public static string GetByGroup(string groupId, string latitude, string longitude, Users user)
    {
        List<Event> events = GetByProc("geteventsbygroup", string.Format("groupid={0}", groupId));
        if(events.Count > 0)
        {
            AddHelperProperties(events, latitude, longitude);
            return GetGroupEventsHtml(events, user);
        }
        return "";
    }

    public new void Save()
    {
        base.Save();

        if(!string.IsNullOrEmpty(this.UserId))
        {
            EventGoing going = new EventGoing(this.Id, this.UserId, true);
            going.Save();
        }

        if (!string.IsNullOrEmpty(this.NotificationMessage))
        {
            Notification notification = new Notification(this.Id, this.UserId, this.NotificationMessage);
            notification.Save();
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

    public static Event GetByRefernce(int referenceId)
    {
        List<Event> events = GetByWhere(string.Format("(referenceid%20eq%20{0})", referenceId));
        if (events.Count > 0)
            return events[0];

        return null;
    }

    private static void AddHelperProperties(List<Event> events, string latitude, string longitude)
    {
        foreach (Event evt in events)
        {
            evt.Going = EventGoing.GetByEvent(evt.Id);

            if (evt.DayOfWeek != null)
            {
                string[] daysShort = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
                evt.LocalDayTime = daysShort[(int)evt.DayOfWeek] + " " + evt.LocalTime;

                string[] days = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };
                evt.DayLabel = days[(int)evt.DayOfWeek];
            }
        }
        
        //double lat = double.Parse(latitude);
        //double lng = double.Parse(longitude);
        
        //foreach (Event evt in events)
        //{
        //    DateTime localTime = GoogleMapsService.GetLocalDateTime(evt.StartTime, lat, lng);
        //    evt.LocalDayTime = localTime.ToString("ddd h:mm tt");
        //    evt.LocalTime = localTime.ToString("h:mm tt");
        //    evt.DayOfWeek = (int?)localTime.DayOfWeek;
        //}

        //try
        //{
        //    double lat = double.Parse(latitude);
        //    double lng = double.Parse(longitude);
        //    var sCoord = new GeoCoordinate(lat, lng);

        //    foreach (Event evt in events)
        //    {
        //        if(!string.IsNullOrEmpty(evt.GroupId))
        //        {
        //            Group group = Group.Get(evt.GroupId);
        //            if(!string.IsNullOrEmpty(group.Locations))
        //            {
        //                evt.Distance = evt.LocationName;
        //                continue;
        //            }
        //        }
        //        var eCoord = new GeoCoordinate(evt.LocationLatitude, evt.LocationLongitude);
        //        evt.Distance = DistanceLabel(sCoord.GetDistanceTo(eCoord));
        //    }
        //}
        //catch (Exception ex) { }
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

        string html = string.Format("<div class='dayHeader' dayofweek='{0}'><div></div><div>{1}</div></div>", events[0].DayOfWeek, events[0].DayLabel);

        Random rnd = new Random();
        int i = 0;
        foreach (Event evt in events)
        {
            if(i > 0 && events[i - 1].DayOfWeek != events[i].DayOfWeek)
                html += string.Format("<div class='dayHeader' dayofweek='{0}'><div></div><div>{1}</div></div>", events[i].DayOfWeek, events[i].DayLabel);
            string addClass = "";
            if(i == 0 || events[i - 1].DayOfWeek != events[i].DayOfWeek)
                addClass = "first";
            if (i == events.Count - 1 || events[i].DayOfWeek != events[i + 1].DayOfWeek)
                addClass += " last";

            //if (string.IsNullOrEmpty(evt.GroupId))
            //{
            //    string eventHtml = "<div eventid='{EventId}' class='homeList event {Class}'>{img}<div class='name'>{Name}</div><div class='details'>{Details}</div><div class='day'>{StartDay}</div></div>";
            //    eventHtml = eventHtml.Replace("{EventId}", evt.Id).Replace("{Class}", addClass).Replace("{Name}", evt.Name).Replace("{Details}", evt.Distance).Replace("{StartDay}", evt.LocalTime);
            //    string img = "<img src='../Img/face" + rnd.Next(8) + ".png' />";
            //    if (evt.IsGoing == true)
            //    {
            //        string checkMark = "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            //        if (!string.IsNullOrEmpty(user.FacebookId))
            //            img = "<img class='fbPic' src='https://graph.facebook.com/" + user.FacebookId + "/picture' />" + checkMark;
            //        else
            //            img = "<img src='../Img/face" + rnd.Next(8) + ".png' />" + checkMark;
            //    }
            //    eventHtml = eventHtml.Replace("{img}", img);
            //    html += eventHtml;
            //}
            //else
            //{
            string groupHtml = "<div eventid='{EventId}' class='homeList event {Class}'>{img}<div class='name'>{Name}</div><div class='details'>{Details}</div><div class='day'>{StartDay}</div><div class='group' groupid='{GroupId}'>{Group}</div></div>";
            string details = AddGoing(evt);
            //details += ge.Events.Count > 1 ? ", and " + (ge.Events.Count - 1).ToString() + " more..." : " " + evt.Distance;

            groupHtml = groupHtml.Replace("{EventId}", evt.Id).Replace("{Class}", addClass).Replace("{Name}", evt.Name).Replace("{Details}", details).Replace("{StartDay}", evt.LocalTime).Replace("{GroupId}", evt.GroupId).Replace("{Group}", evt.GroupName);
            string img = "<img src='../Img/face" + rnd.Next(8) + ".png' />";
            if (!string.IsNullOrEmpty(evt.GroupId))
                img = string.Format("<img src='{0}' onerror=\"this.src='../Img/group.png';\" />", evt.GroupPictureUrl);
            if (evt.IsGoing != null && (bool)evt.IsGoing && !string.IsNullOrEmpty(user.FacebookId))
                img = "<img class='fbPic' src='https://graph.facebook.com/" + user.FacebookId + "/picture' />" + "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            else if (evt.IsGoing != null && (bool)evt.IsGoing)
                img = "<img src='../Img/face" + rnd.Next(8) + ".png' /><div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
            groupHtml = groupHtml.Replace("{img}", img);
            html += groupHtml;
            //}
            i++;
        }

        return html;
        
        
        
        
        //if(user != null)
        //    events = ReorderEvents(events, user);

        //List<GroupEvent> groupEvents = new List<GroupEvent>();
        //foreach(Event evt in events)
        //{
        //    if(string.IsNullOrEmpty(evt.GroupId))
        //    {
        //        groupEvents.Add(new GroupEvent(null, evt));
        //    }
        //    else
        //    {
        //        GroupEvent groupEvent = groupEvents.Find(delegate(GroupEvent g)
        //        {
        //            return g.Group != null && g.Group.Id == evt.GroupId;
        //        });
        //        if(groupEvent != null)
        //        {
        //            groupEvent.Events.Add(evt);
        //        }
        //        else
        //        {
        //            Group group = new Group();
        //            group.Id = evt.GroupId;
        //            group.Name = evt.GroupName;
        //            group.PictureUrl = evt.GroupPictureUrl;
        //            groupEvents.Add(new GroupEvent(group, evt));
        //        }
        //    }
        //}

        //string html = "";
        //Random rnd = new Random();
        //foreach(GroupEvent ge in groupEvents)
        //{
        //    if(ge.Group == null)
        //    {
        //        string eventHtml = "<div eventid='{EventId}' class='homeList event'>{img}<div class='name'>{Name}</div><div class='details'>{Details}</div><div class='day'>{StartDay}</div></div>";
        //        eventHtml = eventHtml.Replace("{EventId}", ge.Events[0].Id).Replace("{Name}", ge.Events[0].Name).Replace("{Details}", ge.Events[0].Distance).Replace("{StartDay}", ge.Events[0].LocalTime);
        //        string img = "<img src='../Img/grayface" + rnd.Next(8) + ".png' />";
        //        if(ge.Events[0].IsGoing == true)
        //        {
        //            string checkMark = "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
        //            if (!string.IsNullOrEmpty(user.FacebookId))
        //                img = "<img class='fbPic' src='https://graph.facebook.com/" + user.FacebookId + "/picture' />" + checkMark;
        //            else
        //                img = "<img src='../Img/face" + rnd.Next(8) + ".png' />" + checkMark;
        //        }
        //        eventHtml = eventHtml.Replace("{img}", img);
        //        html += eventHtml;
        //    }
        //    else
        //    {
        //        string groupHtml = "<div eventid='{EventId}' class='homeList event'>{img}<div class='name'>{Name}</div><div class='details'>{Details}</div><div class='day'>{StartDay}</div></div>";
        //        string details = ge.Events[0].Name;
        //        bool isGoing = false;
        //        foreach(Event evt in ge.Events)
        //        {
        //            if (evt.IsGoing == true)
        //                isGoing = true;
        //        }
        //        //details += ge.Events.Count > 1 ? ", and " + (ge.Events.Count - 1).ToString() + " more..." : " " + ge.Events[0].Distance;
        //        groupHtml = groupHtml.Replace("{EventId}", ge.Events[0].Id).Replace("{Name}", details).Replace("{Details}", ge.Group.Name).Replace("{StartDay}", ge.Events[0].LocalTime);
        //        string img = string.Format("<img src='{0}' onerror=\"this.src='../Img/group.png';\" />", ge.Group.PictureUrl);
        //        if (isGoing && !string.IsNullOrEmpty(user.FacebookId))
        //            img = "<img class='fbPic' src='https://graph.facebook.com/" + user.FacebookId + "/picture' />" + "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
        //        groupHtml = groupHtml.Replace("{img}", img);
        //        html += groupHtml;
        //    }
        //}

        //return html;
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
            eventHtml = eventHtml.Replace("{EventId}", evt.Id).Replace("{Name}", evt.Name).Replace("{Details}", evt.Distance).Replace("{StartDay}", evt.LocalDayTime).Replace("{StartTime}", "" /*"{{" + evt.StartTime.ToString() + "}}"*/);
            string img = "<img src='../Img/face" + rnd.Next(8) + ".png' />";
            if (evt.IsGoing == true)
            {
                string checkMark = "<div class='goingIcon icon'><img src='/Img/greenCheck.png'></div>";
                if (!string.IsNullOrEmpty(user.FacebookId))
                    img = "<img class='fbPic' src='https://graph.facebook.com/" + user.FacebookId + "/picture' />" + checkMark;
                else
                    img = "<img src='../Img/face" + rnd.Next(8) + ".png' />" + checkMark;
            }
            eventHtml = eventHtml.Replace("{img}", img);
            html += eventHtml;
        }

        return html;
    }

    private static List<Event> ReorderEvents(List<Event> events, Users user)
    {
        //List<string> goingIds = EventGoing.GetByUser(user.Id);

        List<Event> eventGoing = new List<Event>();
        List<Event> eventOther = new List<Event>();

        foreach(Event evt in events)
        {
            bool isGoing = false;
            foreach(EventGoing going in evt.Going)
            {
                if(user.Id == going.UserId)
                {
                    isGoing = true;
                    break;
                }
            }
            if (isGoing)
            {
                evt.IsGoing = true;
                eventGoing.Add(evt);
            }
            else
            {
                evt.IsGoing = false;
                eventOther.Add(evt);
            }   
        }

        //events = eventGoing;
        //events.AddRange(eventOther);
        return events;
    }

    private static string AddGoing(Event evt)
    {
        string html = "<div class='homeGoing'>";
        Random rnd = new Random();
        foreach(EventGoing going in evt.Going)
        {
            if (!string.IsNullOrEmpty(going.FacebookId))
                html += "<img src='https://graph.facebook.com/" + going.FacebookId + "/picture' />";
            else
                html += "<img style='height: 25px;margin: -3px 0;' src='../Img/face" + rnd.Next(8) + ".png' />";
        }
        html += "</div>";
        return html;
    }

    private class GroupEvent
    {
        public GroupEvent()
        {

        }
        public GroupEvent(Group group, Event evt)
        {
            Group = group;
            Events = new List<Event>() { evt };
        }

        public List<Event> Events { get; set; }

        public Group Group { get; set; }
    }

    private static string defaultHomeHtml = "<div style='background-color: white;margin: 15px 12px;padding: 34px 24px;box-shadow: 0 1px 2px 0 rgba(0,0,0,0.22);border-radius: 6px;'><div style='text-align: center;color: #555;'><div style='font-size: 1.5em;'>Welcome to Pow Wow!</div><div style='font-size: 1.1em;margin: .8em 32px;line-height: 1.4em;'>The place to find events near you today</div><div style='font-size: 1.25em;line-height: 1.8em;'><a style='color: #4285F4;' onclick='OpenAdd();'>Create an Event</a><br/>or<br/><a style='color: #4285F4;' onclick='OpenGroups();'>Join a Group</a></div></div></div>";

}
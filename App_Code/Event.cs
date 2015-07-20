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

    public string EventDescription { get; set; }

    public string LocationName { get; set; }

    public string LocationAddress { get; set; }

    public double LocationLatitude { get; set; }

    public double LocationLongitude { get; set; }

    public bool IsPrivate { get; set; }

    public int MinParticipants { get; set; }

    public int MaxParticipants { get; set; }

    public string CutoffTime { get; set; }

    public string StartTime { get; set; }

    public string Invited { get; set; }

    public string Going { get; set; }

    [NonSave]
    public int? ReferenceId { get; set; }

    [NonSave]
    public string Distance { get; set; }

    [NonSave]
    public string HowManyGoing { get; set; }

    [NonSave]
    public string NotificationMessage { get; set; }

    [NonSave]
    public string FacebookId { get; set; }

    #endregion

    public static List<Event> GetCurrent(string latitude, string longitude)
    {
        List<Event> events = GetByProc("getevents", string.Format("latitude={0}&longitude={1}", latitude, longitude));
        AddHelperProperties(events, latitude, longitude);
        return events;
    }

    private static void AddHelperProperties(List<Event> events, string latitude, string longitude)
    {
        try
        {
            double lat = double.Parse(latitude);
            double lng = double.Parse(longitude);
            var sCoord = new GeoCoordinate(lat, lng);

            foreach (Event evt in events)
            {
                var eCoord = new GeoCoordinate(evt.LocationLatitude, evt.LocationLongitude);
                evt.Distance = DistanceLabel(sCoord.GetDistanceTo(eCoord));

                //string[] going = evt.Going.Split('|');
                //int goingCt = going.Length == 1 && string.IsNullOrEmpty(going[0]) ? 0 : going.Length;
                evt.HowManyGoing = "";
                if(evt.MinParticipants > 1 && evt.MaxParticipants > 0)
                    evt.HowManyGoing = string.Format("Min: {0} Max: {1}", evt.MinParticipants.ToString(), evt.MaxParticipants.ToString());
                else if(evt.MinParticipants > 1)
                    evt.HowManyGoing = string.Format("Min: {0}", evt.MinParticipants.ToString());
                else if(evt.MaxParticipants > 0)
                    evt.HowManyGoing = string.Format("Max: {0}", evt.MaxParticipants.ToString());
            }
        }
        catch (Exception ex) { }
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

}
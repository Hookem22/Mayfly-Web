using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

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

    public int? ReferenceId { get; set; }

    public string Distance { get; set; }

    public string HowManyGoing
    {
        get
        {
            string[] going = Going.Split('|');
            return string.Format("{0} of {1}", going.Length.ToString(), MinParticipants.ToString());
        }
    }

    #endregion

    public static List<Event> GetCurrent(string latitude, string longitude)
    {
        List<Event> events = GetByProc("getevents", string.Format("latitude={0}&longitude={1}", latitude, longitude));
        try
        {
            double lat = double.Parse(latitude);
            double lng = double.Parse(longitude);

            foreach(Event ev in events)
            {
                ev.Distance = DistanceLabel(DistanceTo(lat, lng, ev.LocationLatitude, ev.LocationLongitude));
            }
        }
        catch(Exception ex) { }

        return events;
    }

    private static double DistanceTo(double lat1, double lon1, double lat2, double lon2, char unit = 'M')
    {
        double rlat1 = Math.PI * lat1 / 180;
        double rlat2 = Math.PI * lat2 / 180;
        double theta = lon1 - lon2;
        double rtheta = Math.PI * theta / 180;
        double dist =
            Math.Sin(rlat1) * Math.Sin(rlat2) + Math.Cos(rlat1) *
            Math.Cos(rlat2) * Math.Cos(rtheta);
        dist = Math.Acos(dist);
        dist = dist * 180 / Math.PI;
        dist = dist * 60 * 1.1515;

        switch (unit)
        {
            case 'K': //Kilometers -> default
                return dist * 1.609344;
            case 'N': //Nautical Miles 
                return dist * 0.8684;
            case 'M': //Miles
                return dist;
        }

        return dist;
    }

    private static string DistanceLabel(double distance)
    {
        if (distance < 1)
            return "< 1 mile away";
        else if (distance < 1.5)
            return "1 mile away";
        else
            return string.Format("{0} miles away", Math.Round(distance));
    }

}
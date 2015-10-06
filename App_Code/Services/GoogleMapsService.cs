using RestSharp;
using System;
using System.Globalization;


/// <summary>
/// Summary description for GoogleMapsService
/// </summary>
public static class GoogleMapsService
{
    private static GoogleTimeZone m_GoogleTimeZone;
    private static DateTime? m_Today;

    public static DateTime GetLocalDateTime(string utcDate, double latitude, double longitude)
    {
        DateTime date;
        DateTime.TryParse(utcDate, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal, out date);
        
        if (m_GoogleTimeZone == null)
            m_GoogleTimeZone = GetGoogleTimeZone(latitude, longitude);

        return date.AddSeconds(m_GoogleTimeZone.rawOffset + m_GoogleTimeZone.dstOffset);
    }

    public static DateTime GetToday(double latitude, double longitude)
    {
        if (m_Today != null)
            return (DateTime)m_Today;

        m_Today = GetLocalDateTime(DateTime.UtcNow.ToString(), latitude, longitude);
        return (DateTime)m_Today;
    }

    public static GoogleTimeZone GetGoogleTimeZone(double latitude, double longitude)
    {
        DateTime utcDate = DateTime.UtcNow;
        
        var client = new RestClient("https://maps.googleapis.com");
        var request = new RestRequest("maps/api/timezone/json", Method.GET);
        request.AddParameter("location", latitude + "," + longitude);
        request.AddParameter("timestamp", utcDate.ToTimestamp());
        request.AddParameter("sensor", "false");
        var response = client.Execute<GoogleTimeZone>(request);

        return (GoogleTimeZone)response.Data;
    }

    public static double ToTimestamp(this DateTime date)
    {
        DateTime origin = new DateTime(1970, 1, 1, 0, 0, 0, 0);
        TimeSpan diff = date.ToUniversalTime() - origin;
        return Math.Floor(diff.TotalSeconds);
    }

    public class GoogleTimeZone
    {
        public double dstOffset { get; set; }
        public double rawOffset { get; set; }
        public string status { get; set; }
        public string timeZoneId { get; set; }
        public string timeZoneName { get; set; }
    }

}
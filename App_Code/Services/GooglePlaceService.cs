using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Web;

/// <summary>
/// Summary description for GooglePlaceService
/// </summary>
public class GooglePlaceService
{
	public GooglePlaceService()
	{
	}

    public static List<Location> GoogleSearchCity(string placeName, string latitude, string longitude)
    {
        List<Location> locations = GooglePlaceSearch(placeName, latitude, longitude, "30000", "", 15);
        if(locations.Count <= 0)
            locations.Add(new Location() { Name = "", Address = GetCityName(latitude, longitude) });

        return locations;
    }

    private static List<Location> GooglePlaceSearch(string placeName, string latitude, string longitude, string radius, string googleType, int numberToReturn)
    {
        placeName = placeName.Replace(" ", "%22");
        string url = string.Format("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location={0},{1}&radius={2}{3}&name={4}&sensor=false&key=AIzaSyA1Viw-vy8_HSZmS02R9MBMoyNsYi5y2ME", latitude, longitude, radius, googleType, placeName);

        return Deserialize(GetResponse(url), numberToReturn);
    }

    private static string GetCityName(string latitude, string longitude)
    {
        string url = string.Format("https://maps.googleapis.com/maps/api/geocode/json?latlng={0},{1}&key=AIzaSyA1Viw-vy8_HSZmS02R9MBMoyNsYi5y2ME", latitude, longitude);
        string r = GetResponse(url);

        string city = "";
        if (r.Contains("\"formatted_address\" : "))
        {
            r = r.Remove(0, r.IndexOf("\"formatted_address\" : "));
            r = r.Remove(0, r.IndexOf(",") + 1);
            city = r.Substring(0, r.IndexOf("\"")).Trim();
        }

        return city;
    }

    private static List<Location> Deserialize(string r, int numberToReturn)
    {
        List<Location> locations = new List<Location>();
        for (int i = 0; i < numberToReturn; i++)
        {
            if (!r.Contains("\"id\" : \"") || !r.Contains("\"lat\" : "))
                break;


            Location location = new Location();
            locations.Add(location);


            if (r.Contains("\"lat\" : "))
            {
                r = r.Remove(0, r.IndexOf("\"lat\" : ") + 8);
                string lat = r.Substring(0, r.IndexOf(",")).Trim();
                double d_lat;
                if (double.TryParse(lat, out d_lat))
                    location.Latitude = d_lat;
            }

            if (r.Contains("\"lng\" : "))
            {
                r = r.Remove(0, r.IndexOf("\"lng\" : ") + 8);
                string lng = r.Substring(0, r.IndexOf("}")).Trim();
                double d_lng;
                if (double.TryParse(lng, out d_lng))
                    location.Longitude = d_lng;
            }
            if (r.Contains("\"id\" : \""))
            {
                r = r.Remove(0, r.IndexOf("\"id\" : \"") + 8);
                //place.GoogleId = r.Substring(0, r.IndexOf("\","));
            }
            if (r.Contains("\"name\" : \""))
            {
                r = r.Remove(0, r.IndexOf("\"name\" : \"") + 10);
                location.Name = r.Substring(0, r.IndexOf("\","));
            }

            if (r.Contains("\"reference\" : \""))
            {
                r = r.Remove(0, r.IndexOf("\"reference\" : \"") + 15);
                //place.GoogleReferenceId = r.Substring(0, r.IndexOf("\","));
            }
            if (r.Contains("\"vicinity\" : \""))
            {
                r = r.Remove(0, r.IndexOf("\"vicinity\" : \"") + 14);
                location.Address = r.Substring(0, r.IndexOf("\""));
                if (location.Address.Contains(","))
                    location.Address = location.Address.Substring(0, location.Address.IndexOf(","));
            }

            if (r.Contains("\"geometry\" : "))
            {
                r = r.Remove(0, r.IndexOf("\"geometry\" : ") + 10);
            }
            else
                break;
        }

        return locations;
    }

    private static string GetResponse(string url)
    {
        HttpWebRequest webRequest = WebRequest.Create(url) as HttpWebRequest;
        webRequest.Timeout = 20000;
        webRequest.Method = "GET";

        try
        {
            var response = webRequest.GetResponse();
            using (var stream = response.GetResponseStream())
            {
                var reader = new StreamReader(stream);
                var resp = reader.ReadToEnd();
                return resp.ToString();
            }
        }
        catch { }

        return "";
    }
}
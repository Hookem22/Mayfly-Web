using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Location
/// </summary>
public class Location
{
	public Location()
	{
    }

    #region Properties

    public string Name { get; set; }

    public string Address { get; set; }

    public double Latitude { get; set; }

    public double Longitude { get; set; }

    #endregion

    public static List<Location> SearchGooglePlaces(string searchName, string latitdue, string longitude)
    {
        return GooglePlaceService.GoogleSearchCity(searchName, latitdue, longitude);
    }

}
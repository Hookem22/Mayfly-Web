﻿using System;
using System.Collections.Generic;
using System.Device.Location;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for School
/// </summary>
public class School : Base<School>
{
    public School()
        : base("School")
    {

    }

    #region Properties

    public string Name { get; set; }

    public double Latitude { get; set; }

    public double Longitude { get; set; }

    public static School StEds = new School() { Id = "E1668987-C219-484C-B5BB-1ACACDCADE17", Name = "St. Edward's", Latitude = 30.231, Longitude = -97.758 };

    #endregion

    public static School GetClosest(string latitude, string longitude)
    {
        List<School> schools = GetByProcFast("getcloseschools", string.Format("latitude={0}&longitude={1}", latitude, longitude));
        if (schools.Count == 0)
        {
            return StEds;
        }
        else if (schools.Count == 1)
            return schools[0];

        double lat = 0;
        double lng = 0;
        double closest = 1000000;
        School closeSchool = null;
        if(double.TryParse(latitude, out lat) && double.TryParse(longitude, out lng))
        {
            var mePoint = new GeoCoordinate(lat, lng);
            foreach(School school in schools)
            {
                var schoolPt = new GeoCoordinate(school.Latitude, school.Longitude);
                double distance = mePoint.GetDistanceTo(schoolPt);
                if(distance < closest)
                {
                    closest = distance;
                    closeSchool = school;
                }
            }
        }
        return closeSchool;
    }
}
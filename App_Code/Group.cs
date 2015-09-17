using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

/// <summary>
/// Summary description for Group
/// </summary>
public class Group : Base<Group>
{
    public Group() : base("Group")
    {

    }

    #region Properties

    public string Name { get; set; }

    public string Description { get; set; }

    public string PictureUrl { get; set; }

    public double Latitude { get; set; }

    public double Longitude { get; set; }

    public string City { get; set; }

    public bool IsPublic { get; set; }

    public string Password { get; set; }

    [NonSave]
    List<Users> Members { get; set; }


    #endregion

    public static List<Group> GetByUserId(string userId)
    {
        //Group group1 = new Group();
        //group1.Name = "South Austin Board Games";
        //group1.PictureUrl = "http://photos3.meetupstatic.com/photos/event/4/7/4/c/global_360318252.jpeg";
        //group1.Description = "South Austin Game Night (SAGN) is a great group of people who love to play board games. Everything from party games to Eurogaming, we'll do it all. We play every Tuesday and Sunday at Rockin' Tomato on S. Lamar. Come on out and join us! And, hey, I know our events look sparse as far as attendance, but that's not the case!  Because we meet regularly, folks don't sign up for stuff.  You don't have to RSVP for events, just show up.  We get generally 30 to 40 people on our Tuesday meetings and 8-10 on Sundays.  So come on out and play some games!  There will be plenty of gaming to go around!";
        //group1.City = "Austin, TX";
        //group1.Latitude = 30.25;
        //group1.Longitude = -97.75;
        //group1.IsPublic = true;

        //group1.Save();

        return new List<Group>();
    }

    public static List<Group> Get(string latitude, string longitude)
    {
        return GetByProc("getgroups", string.Format("latitude={0}&longitude={1}", latitude, longitude));
    }

    //public static List<Group> Get()
    //{
    //    return new List<Group>();
        
    //    Group group1 = new Group();
    //    group1.Name = "South Austin Board Games";
    //    group1.PictureUrl = "http://photos3.meetupstatic.com/photos/event/4/7/4/c/global_360318252.jpeg";

    //    Group group2 = new Group();
    //    group2.Name = "Austin: Social with a Twist";
    //    group2.PictureUrl = "http://photos1.meetupstatic.com/photos/event/d/d/f/6/global_328616822.jpeg";

    //    Group group3 = new Group();
    //    group3.Name = "Open Government & Civic Technology Meetup by Open Austin";
    //    group3.PictureUrl = "http://photos3.meetupstatic.com/photos/event/6/c/1/8/thumb_393087672.jpeg";

    //    Group group4 = new Group();
    //    group4.Name = "Austin TechBreakfast";
    //    group4.PictureUrl = "http://photos3.meetupstatic.com/photos/event/9/7/2/e/global_255338702.jpeg";

    //    List<Group> groups = new List<Group> { group1, group2, group3, group4, group1, group2, group3, group4, group1, group2, group3, group4 };
    //    return groups;
    //}
}
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Runtime.Serialization.Json;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;

/// <summary>
/// Summary description for MeetupService
/// </summary>
public class MeetupService
{
    private const string YOUR_CONSUMER_KEY_PROD = "al25r4gjd2r9o9ue5gubs0rnms";
    private const string YOUR_CONSUMER_SECRET_PROD = "chu1bdn5up4sqdho1gf8qgothm";
    private const string REDIRECT_URI_PROD = "http://joinpowwow.com/Meetup";
    private const string YOUR_CONSUMER_KEY_TEST = "2tm7voh0nq1i3q32sjb6r94mj0";
    private const string YOUR_CONSUMER_SECRET_TEST = "r22oa9vsg1ro3f7mmkoj10d5jv";
    private const string REDIRECT_URI_TEST = "http://localhost:49542/Meetup";

    public static Meetup Authorize(string code)
    {
        string url = "https://secure.meetup.com/oauth2/access";
        string data = ConfigurationManager.AppSettings["IsProduction"] == "true" ?
            string.Format("client_id={0}&client_secret={1}&grant_type=authorization_code&redirect_uri={2}&code={3}", YOUR_CONSUMER_KEY_PROD, YOUR_CONSUMER_SECRET_PROD, REDIRECT_URI_PROD, code) :
            string.Format("client_id={0}&client_secret={1}&grant_type=authorization_code&redirect_uri={2}&code={3}", YOUR_CONSUMER_KEY_TEST, YOUR_CONSUMER_SECRET_TEST, REDIRECT_URI_TEST, code);
        
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        request.Method = "POST";
        request.ContentType = "application/x-www-form-urlencoded";
        request.ContentLength = data.Length;

        using (Stream webStream = request.GetRequestStream())
        using (StreamWriter requestWriter = new StreamWriter(webStream, System.Text.Encoding.ASCII))
        {
            requestWriter.Write(data);
        }

        try
        {
            WebResponse webResponse = request.GetResponse();
            using (Stream webStream = webResponse.GetResponseStream())
            {
                StreamReader reader = new StreamReader(webStream, Encoding.UTF8);
                String responseString = reader.ReadToEnd();

                Dictionary<string, string> meetupTokens = new JavaScriptSerializer().Deserialize<Dictionary<string, string>>(responseString);
                return new Meetup(meetupTokens["access_token"], meetupTokens["refresh_token"]);
            }
        }
        catch (Exception e)
        {
            Console.Out.WriteLine(e.Message);
        }

        return null;
    }

    public static void GetMember(Meetup meetup)
    {
        string url = string.Format("https://api.meetup.com/2/member/self/?access_token={0}", meetup.AccessToken);
        string response = GetResponse(url);
        try
        {
            Dictionary<string, object> dict = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(response);
            meetup.Member.Id = dict["id"].ToString();
            meetup.Member.Name = dict["name"].ToString();
        }
        catch { }
    }

    public static void GetGroups(Meetup meetup)
    {
        string url = string.Format("https://api.meetup.com/2/groups?organizer_id={0}&page=20&access_token={1}", "8157820", meetup.AccessToken);
        string response = GetResponse(url);
        try
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            Dictionary<string, object> dict = serializer.Deserialize<Dictionary<string, object>>(response);
            IEnumerable groups = dict["results"] as IEnumerable;
            foreach (dynamic group in groups)
            {
                Group g = new Group();
                meetup.Groups.Add(g);
                g.Id = group["id"].ToString();
                g.Name = group["name"].ToString();
            }
        }
        catch { }
    }

    public static void GetEvents(Meetup meetup)
    {
        foreach (Group group in meetup.Groups)
        {
            string url = string.Format("https://api.meetup.com/2/events?group_id={0}&page=20&access_token={1}", group.Id, meetup.AccessToken);
            string response = GetResponse(url);
            try
            {
                JavaScriptSerializer serializer = new JavaScriptSerializer();
                Dictionary<string, object> dict = serializer.Deserialize<Dictionary<string, object>>(response);
                IEnumerable events = dict["results"] as IEnumerable;
                foreach (dynamic evt in events)
                {
                    MeetupEvent me = new MeetupEvent();
                    meetup.MeetupEvents.Add(me);
                    me.Id = evt["id"].ToString();
                    me.Name = evt["name"].ToString();
                }
            }
            catch { }
        }
    }

    public class Meetup
    {
        public Meetup(string accessToken, string refreshToken)
        {
            AccessToken = accessToken;
            RefreshToken = refreshToken;
            Member = new Member();
            Groups = new List<Group>();
            MeetupEvents = new List<MeetupEvent>();
        }

        public string AccessToken { get; set; }

        public string RefreshToken { get; set; }

        public Member Member { get; set; }

        public List<Group> Groups { get; set; }

        public List<MeetupEvent> MeetupEvents { get; set; }
    }

    public class Member : MeetupBase
    {
    }

    public class Group : MeetupBase
    {

    }

    public class MeetupEvent : MeetupBase
    {

    }

    public abstract class MeetupBase
    {
        public MeetupBase()
        {

        }
        
        public string Id { get; set; }

        public string Name { get; set; }

        public string Photo { get; set; }
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
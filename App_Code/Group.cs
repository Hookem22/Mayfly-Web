using System;
using System.Collections.Generic;
using System.Device.Location;
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

    public string SchoolId { get; set; }

    public double Latitude { get; set; }

    public double? Longitude { get; set; }

    public string City { get; set; }

    public bool? IsPublic { get; set; }

    public string Password { get; set; }

    public string Locations { get; set; }

    public double? OrderBy { get; set; }

    [NonSave]
    public List<GroupUsers> Members { get; set; }

    [NonSave]
    public string UserId { get; set; }

    [NonSave]
    public string EventsHtml { get; set; }

    [NonSave]
    public double? Distance { get; set; }
    
    [NonSave]
    public string SchoolName { get; set; }

    #endregion

    public static Group Get(string id, string latitude, string longitude, Users user)
    {
        if (id.Contains("|"))
            id = id.Substring(0, id.IndexOf("|"));
        Group group = Base<Group>.Get(id);
        group.Members = GroupUsers.GetByGroup(id);
        group.EventsHtml = Event.GetByGroup(id, latitude, longitude, user);
        group.Description = group.Description.Replace("\n", "<br/>");
        if(!string.IsNullOrEmpty(group.SchoolId))
        {
            School school = School.Get(group.SchoolId);
            if (school != null)
                group.SchoolName = school.Name;
        }
        return group;
    }

    public static Group GetFast(string id)
    {
        List<Group> groups = GetByProcFast("getgroup", string.Format("groupid={0}", id));
        if (groups.Count > 0)
            return groups[0];

        return null;
    }

    public static List<Group> GetByUserId(string userId)
    {
        return GetByProc("getgroupsbyuser", string.Format("userid={0}", userId));
    }

    public static List<Group> GetBySchoolId(string schoolId)
    {
        List<Group> groups = GetByProc("getgroupsbyschool", string.Format("schoolid={0}", schoolId));
        return groups;
        //return ReorderByDistance(groups, latitude, longitude);
    }

    private static List<Group> ReorderByDistance(List<Group> groups, string latitude, string longitude)
    {
        double lat = double.Parse(latitude);
        double lng = double.Parse(longitude);
        var sCoord = new GeoCoordinate(lat, lng);
        foreach (Group group in groups)
        {
            var eCoord = new GeoCoordinate(group.Latitude, (double)group.Longitude);
            group.Distance = sCoord.GetDistanceTo(eCoord);
        }

        return groups.OrderBy(x=>x.Distance).ToList();
    }

    public new void Save()
    {
        base.Save();

        if (!string.IsNullOrEmpty(this.UserId))
        {
            GroupUsers going = new GroupUsers(this.Id, this.UserId, true);
            going.Save();

            //List<GroupUsers> groups = GroupUsers.GetByWhere(string.Format("(userid%20eq%20'{0}')", this.UserId)).FindAll(delegate (GroupUsers g)
            //{
            //    return g.IsAdmin == true;
            //});

            //if(groups.Count <= 1)
            //{
            //    Users user = Users.Get(this.UserId);

            //    string body = firstGroupEmail.Replace("{Group Name}", this.Name).Replace("{Your Name}", user.FirstName);
            //    EmailService email = new EmailService("PowWow@JoinPowWow.com", user.Email, "Your First Group", body);
            //    email.Send();
            //}
        }
    }

    public void Join()
    {
        GroupUsers users = GroupUsers.Get(this.Id, this.UserId, true);
        if (users != null)
        {
            users.Undelete();
        }
        else
        {
            users = new GroupUsers(this.Id, this.UserId, false);
            users.Save();
        }
    }

    public void Unjoin()
    {
        GroupUsers users = GroupUsers.Get(this.Id, this.UserId);
        users.Delete();
    }

    public static void SaveGroupInvites(List<EventInvited> invites, string message)
    {
        foreach (EventInvited invite in invites)
        {
            if (!string.IsNullOrEmpty(invite.FacebookId))
            {
                Users user = Users.GetByFacebookId(invite.FacebookId);
                if (user != null)
                {
                    Notification notification = new Notification("", user.Id, message);
                    notification.Save();

                    AzureMessagingService.Send(message, "", user.Id);
                }
            }
        }
    }

    public static void SendPushMessageToGroup(string groupId, string alert, string messageText, string userId)
    {
        foreach (GroupUsers user in GroupUsers.GetByGroup(groupId))
        {
            if (user.UserId == userId)
                continue;

            AzureMessagingService.Send(alert, messageText, user.UserId);
        }
    }

    public static void SaveNotificationToGroup(string groupId, string message, string userId, string eventId)
    {
        foreach (GroupUsers user in GroupUsers.GetByGroup(groupId))
        {
            if (user.UserId == userId)
                continue;

            Notification notification = new Notification(eventId, user.UserId, message);
            notification.Save();
        }
    }


    private string firstGroupEmail = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><meta content=\"text/html; charset=utf-8\" http-equiv=\"Content-Type\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" /><title></title><style type=\"text/css\">@media only screen and (max-width:480px){body,table,td,p,a,li,blockquote{-webkit-text-size-adjust:none !important}body{width:100% !important;min-width:100% !important}td[id=bodyCell]{padding:10px !important}table.kmMobileHide{display:none !important}table[class=kmTextContentContainer]{width:100% !important}table[class=kmBoxedTextContentContainer]{width:100% !important}td[class=kmImageContent]{padding-left:0 !important;padding-right:0 !important}img[class=kmImage]{width:100% !important}td.kmMobileStretch{padding-left:0 !important;padding-right:0 !important}table[class=kmSplitContentLeftContentContainer],table[class=kmSplitContentRightContentContainer],table[class=kmColumnContainer],td[class=kmVerticalButtonBarContentOuter] table[class=kmButtonBarContent],td[class=kmVerticalButtonCollectionContentOuter] table[class=kmButtonCollectionContent],table[class=kmVerticalButton],table[class=kmVerticalButtonContent]{width:100% !important}td[class=kmButtonCollectionInner]{padding-left:9px !important;padding-right:9px !important;padding-top:9px !important;padding-bottom:0 !important;background-color:transparent !important}td[class=kmVerticalButtonIconContent],td[class=kmVerticalButtonTextContent],td[class=kmVerticalButtonContentOuter]{padding-left:0 !important;padding-right:0 !important;padding-bottom:9px !important}table[class=kmSplitContentLeftContentContainer] td[class=kmTextContent],table[class=kmSplitContentRightContentContainer] td[class=kmTextContent],table[class=kmColumnContainer] td[class=kmTextContent],table[class=kmSplitContentLeftContentContainer] td[class=kmImageContent],table[class=kmSplitContentRightContentContainer] td[class=kmImageContent]{padding-top:9px !important}td[class=\"rowContainer kmFloatLeft\"],td[class=\"rowContainer kmFloatLeft firstColumn\"],td[class=\"rowContainer kmFloatLeft lastColumn\"]{float:left;clear:both;width:100% !important}table[id=templateContainer],table[class=templateRow]{max-width:600px !important;width:100% !important}h1{font-size:40px !important;line-height:130% !important}h2{font-size:32px !important;line-height:130% !important}h3{font-size:24px !important;line-height:130% !important}h4{font-size:18px !important;line-height:130% !important}td[class=kmTextContent]{font-size:14px !important;line-height:130% !important}td[class=kmTextBlockInner] td[class=kmTextContent]{padding-right:18px !important;padding-left:18px !important}table[class=\"kmTableBlock kmTableMobile\"] td[class=kmTableBlockInner]{padding-left:9px !important;padding-right:9px !important}table[class=\"kmTableBlock kmTableMobile\"] td[class=kmTableBlockInner] [class=kmTextContent]{font-size:14px !important;line-height:130% !important;padding-left:4px !important;padding-right:4px !important}}</style></head><body style=\"margin:0;padding:0;background-color:#EEE\"><center><table align=\"center\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" id=\"bodyTable\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding:0;background-color:#EEE;height:100%;margin:0;width:100%\"><tbody><tr><td align=\"center\" id=\"bodyCell\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding-top:50px;padding-left:20px;padding-bottom:20px;padding-right:20px;border-top:0;height:100%;margin:0;width:100%\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" id=\"templateContainer\" width=\"600\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;border:0 none #AAA;background-color:#FFF;border-radius:0\"><tbody><tr><td id=\"templateContainerInner\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding:0\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tr><td align=\"center\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"templateRow\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"rowContainer kmFloatLeft\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmImageBlock\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmImageBlockOuter\"><tr><td class=\"kmImageBlockInner\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding:0px;\" valign=\"top\"><table align=\"left\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmImageContentContainer\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"kmImageContent\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding:0;padding:0;\"><img align=\"left\" alt=\"\" class=\"kmImage\" src=\"https://d3k81ch9hvuctc.cloudfront.net/company/grX8QK/images/ef58abdb-8f42-4458-be9a-c1629ef1e82d.png\" width=\"600\" style=\"border:0;height:auto;line-height:100%;outline:none;text-decoration:none;padding-bottom:0;display:inline;vertical-align:bottom;margin-right:0;max-width:1413px;\" /></td></tr></tbody></table></td></tr></tbody></table><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" class=\"kmDividerBlock\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmDividerBlockOuter\"><tr><td class=\"kmDividerBlockInner\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding-top:18px;padding-bottom:18px;padding-left:18px;padding-right:18px;\"><table class=\"kmDividerContent\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;border-top-width:1px;border-top-style:solid;border-top-color:#ccc;\"><tbody><tr><td style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><span></span></td></tr></tbody></table></td></tr></tbody></table><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmTextBlock\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmTextBlockOuter\"><tr><td class=\"kmTextBlockInner\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;\"><table align=\"left\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmTextContentContainer\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"kmTextContent\" valign=\"top\" style='border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;color:#222;font-family:\"Helvetica Neue\", Arial;font-size:14px;line-height:130%;text-align:left;padding-top:9px;padding-bottom:9px;padding-left:18px;padding-right:18px;'><p style=\"margin:0;padding-bottom:1em;line-height: 20.7999992370605px; text-align: center;\">Welcome to Pow Wow!</p><p style=\"margin:0;padding-bottom:1em;line-height: 20.7999992370605px; text-align: center;\">You've just created a group and are on your way to enabling you and your tribe the best tool for meeting up.</p><p style=\"margin:0;padding-bottom:1em;line-height: 20.7999992370605px; text-align: center;\">Pretty simple from here.  If you have an existing group, simply send them this message through whatever means of communication you use.  </p><p style=\"margin:0;padding-bottom:1em;line-height: 20.7999992370605px; text-align: center;\">If you're starting a group from scratch, the best way to get people to join is to put together events. The more cool things you do, the more people will want to join.</p><p style=\"margin:0;padding-bottom:0;line-height: 20.7999992370605px; text-align: center;\"> </p></td></tr></tbody></table></td></tr></tbody></table><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmTextBlock\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmTextBlockOuter\"><tr><td class=\"kmTextBlockInner\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding-right:50px;padding-left:70px;\"><table align=\"left\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmTextContentContainer\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"kmTextContent\" valign=\"top\" style='border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;color:#222;font-family:\"Helvetica Neue\", Arial;font-size:14px;line-height:130%;text-align:left;padding-top:9px;padding-bottom:9px;padding-right:50px;padding-left:70px;border-style:solid;'><p style=\"margin:0;padding-bottom:1em;line-height: 20.8px;\">{Group Name},</p><p style=\"margin:0;padding-bottom:1em;line-height: 20.8px;\">I want to introduce ya'll to a really cool new app.  </p><p style=\"margin:0;padding-bottom:1em;line-height: 20.8px;\">Basically, Pow Wow is an app that allows anyone to spontaneously create a same day activity and find others to join. You can ask people in a particular group or anyone in your area. </p><p style=\"margin:0;padding-bottom:1em;line-height: 20.8px;\"><span style=\"line-height: 20.8px;\">Pow Wow can be found in the </span><a href=\"https://geo.itunes.apple.com/us/app/pow-wow-events/id1009503264?mt=8\" style=\"word-wrap:break-word;color:#15C;font-weight:bold;text-decoration:underline;line-height: 20.8px;\">iTunes</a><span style=\"line-height: 20.8px;\"> or </span><a href=\"https://play.google.com/store/apps/details?id=com.joinpowwow.powwow&amp;hl=en\" style=\"word-wrap:break-word;color:#15C;font-weight:bold;text-decoration:underline;line-height: 20.8px;\">Android</a><span style=\"line-height: 20.8px;\"> store. </span></p><p style=\"margin:0;padding-bottom:1em;line-height: 20.8px;\">Once you've downloaded it, find {Group Name} in Pow Wow and join so that you can get notified when others in our group around you are trying to get something going.</p><p style=\"margin:0;padding-bottom:1em;line-height: 20.8px;\">All the best,</p><p style=\"margin:0;padding-bottom:0;line-height: 20.8px;\">{Your Name}</p></td></tr></tbody></table></td></tr></tbody></table><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmImageBlock\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmImageBlockOuter\"><tr><td class=\"kmImageBlockInner\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding:0px;\" valign=\"top\"><table align=\"left\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmImageContentContainer\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"kmImageContent\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding:0;padding:0;text-align: center;\"><img align=\"center\" alt=\"\" class=\"kmImage\" src=\"https://d3k81ch9hvuctc.cloudfront.net/company/grX8QK/images/98430dbe-0206-43f5-9fd0-3495b4686d3d.png\" width=\"600\" style=\"border:0;height:auto;line-height:100%;outline:none;text-decoration:none;padding-bottom:0;display:inline;vertical-align:bottom;max-width:1500px;\" /></td></tr></tbody></table></td></tr></tbody></table><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" class=\"kmDividerBlock\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmDividerBlockOuter\"><tr><td class=\"kmDividerBlockInner\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;padding-top:18px;padding-bottom:18px;padding-left:18px;padding-right:18px;\"><table class=\"kmDividerContent\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;border-top-width:1px;border-top-style:solid;border-top-color:#ccc;\"><tbody><tr><td style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><span></span></td></tr></tbody></table></td></tr></tbody></table><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmTextBlock\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody class=\"kmTextBlockOuter\"><tr><td class=\"kmTextBlockInner\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;\"><table align=\"left\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"kmTextContentContainer\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"kmTextContent\" valign=\"top\" style='border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0;color:#222;font-family:\"Helvetica Neue\", Arial;font-size:14px;line-height:130%;text-align:left;padding-top:9px;padding-bottom:9px;padding-left:18px;padding-right:18px;'>            If you have questions, comments, or feedback please email us at Bob@JoinPowWow.com or find us on <a href=\"https://twitter.com/JoinPowWow\" style=\"word-wrap:break-word;color:#15C;font-weight:normal;text-decoration:underline\">Twitter</a></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></td></tr><tr><td align=\"center\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"templateRow\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"rowContainer kmFloatLeft\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"></td></tr></tbody></table></td></tr><tr><td align=\"center\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"templateRow\" width=\"100%\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"><tbody><tr><td class=\"rowContainer kmFloatLeft\" valign=\"top\" style=\"border-collapse:collapse;mso-table-lspace:0;mso-table-rspace:0\"></td></tr></tbody></table></td></tr></table></td></tr></tbody></table></td></tr></tbody></table></center></body></html>";
}
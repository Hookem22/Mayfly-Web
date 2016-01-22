using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;

/// <summary>
/// Summary description for Users
/// </summary>
public class Users : Base<Users>
{
    private const string ENCRYPT_KEY = "Mayfly";
    
    public Users() : base("Users")
    {

    }

    #region Properties

    public string Name { get; set; }

    public string FirstName { get; set; }

    public string DeviceId { get; set; }

    public string PushDeviceToken { get; set; }

    public string FacebookId { get; set; }

    public string Email { get; set; }

    public string Password { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public string SchoolId { get; set; }

    [NonSave]
    public bool? NewUser { get; set; }

    public bool? IsIntern { get; set; }

    public bool? IsiOS { get; set; }

    #endregion

    public static Users InitialLogin(string pushDeviceToken)
    {
        if (string.IsNullOrEmpty(pushDeviceToken))
            return null;

        return GetByPushTokenId(pushDeviceToken, true);
    }

    public static Users Login(dynamic me, string deviceId, string pushDeviceToken, string email, bool isiOS)
    {
        Users user = new Users();
        //if(!string.IsNullOrEmpty(email) && !string.IsNullOrEmpty(password))
        //{
        //    user = GetByEmail(email);
        //    if (user == null || string.IsNullOrEmpty(user.Password))
        //        return null;

        //    string pwd = Decrypt(ENCRYPT_KEY, user.Password, true);
        //    if (pwd == password)
        //    {
        //        if((!string.IsNullOrEmpty(deviceId) && deviceId != user.DeviceId) || (!string.IsNullOrEmpty(pushDeviceToken) && pushDeviceToken != user.PushDeviceToken))
        //        {
        //            user.DeviceId = deviceId;
        //            user.PushDeviceToken = pushDeviceToken;
        //            user.Save();
        //        }
        //        return user;
        //    }
                
        //    return null;
        //}

        if (ConfigurationManager.AppSettings["IsProduction"] == "true")
        {
            string name = "";
            string fbId = "";
            if (me != null)
            {
                name = me.name;
                fbId = me.id;
            }
            string body = string.Format("Name: {0}<br/>Device: {1}<br/>Push Token: {2}<br />Facebook: {3}", name, deviceId, pushDeviceToken, fbId);
            EmailService email1 = new EmailService("PowWow@joinpowwow.com", "williamallenparks@gmail.com", "Pow Wow Log in", body);
            email1.Send();
        }
        if (string.IsNullOrEmpty(pushDeviceToken))
        {
            if(string.IsNullOrEmpty(deviceId))
                return null;

            user = GetByDeviceId(deviceId);
            if (user == null)
            {
                return null;
            }
            else
            {
                user.PushDeviceToken = deviceId;
                user.IsiOS = isiOS;
                user.Save();
                return user;
            }
        }
        user = GetByPushTokenId(pushDeviceToken);
        if (user == null && me == null)
        {
            return null;
        }
        else if (user == null)
        {
            user = GetByFacebookId(me.id);
            if (user == null)
            {
                user = SignUpFromFacebook(me, deviceId, pushDeviceToken, isiOS);
                user.NewUser = true;
            }
            else if (isiOS)
            {
                string dev = deviceId ?? pushDeviceToken;
                user.DeviceId = dev;
                user.PushDeviceToken = dev;
                user.IsiOS = isiOS;
                user.Save();
            }
        }
        if ((user.PushDeviceToken != pushDeviceToken && !string.IsNullOrEmpty(pushDeviceToken)) ||
            (user.DeviceId != deviceId && !string.IsNullOrEmpty(deviceId)))
        {
            user.DeviceId = deviceId;
            user.PushDeviceToken = pushDeviceToken;
            user.IsiOS = isiOS;
            user.Save();
        }

        user.IsiOS = isiOS;
        user.Save();
        return user;
    }

    public static Users SignUpFromFacebook(dynamic me, string deviceId, string pushDeviceToken, bool isiOS)
    {       
        Users user = new Users();
        user.FacebookId = me.id;
        user.Name = me.name;
        user.FirstName = me.first_name;
        user.Email = me.email;
        user.DeviceId = deviceId;
        user.PushDeviceToken = string.IsNullOrEmpty(pushDeviceToken) ? deviceId : pushDeviceToken;
        user.IsiOS = isiOS;
        user.Save();

        //EmailService.SendWelcomeEmail(user.Email);

        string body1 = string.Format("{0}<br/><br/>{1}", user.Name, user.Email);
        EmailService email1 = new EmailService("PowWow@joinpowwow.com", "bob@joinpowwow.com", "New Pow Wow Sign Up", body1);
        email1.Send();

        string body2 = string.Format("{0}<br/><br/>{1}<br/>Device: {2}<br/>Push Token: {3}", user.Name, user.Email, user.DeviceId, user.PushDeviceToken);
        EmailService email2 = new EmailService("PowWow@joinpowwow.com", "williamallenparks@gmail.com", "New Pow Wow Sign Up", body2);
        email2.Send();

        return user;
    }

    public Users SignUpUser()
    {
        this.Password = Encrypt(ENCRYPT_KEY, this.Password, true);
        this.Save();

        EmailService.SendWelcomeEmail(this.Email);

        return this;
    }

    public static string ForgotPassword(string email)
    {
        if (string.IsNullOrEmpty(email))
            return "No user found with this email.";

        Users user = Users.GetByEmail(email);
        if (user == null || string.IsNullOrEmpty(user.Password))
            return "No user found with this email.";

        string body = "Your Pow Wow password is : " + Decrypt(ENCRYPT_KEY, user.Password, true);
        EmailService emailService = new EmailService("PowWow@JoinPowWow.com", user.Email, "Your Pow Wow Password", body);
        emailService.Send();

        return "Your password has been sent to your email.";
    }

    public static Users GetByFacebookId(string facebookId)
    {
        List<Users> users = GetByWhere(string.Format("(facebookid%20eq%20{0})", facebookId));
        if (users.Count > 0)
            return users[0];

        return null;
    }

    public static Users GetByPushTokenId(string pushTokenId, bool fast = false)
    {
        if(fast)
        {
            AzureService service = new AzureService("Users");
            string data = service.GetByProc("getuseridbypushdevicetoken", string.Format("pushdevicetoken={0}", pushTokenId)).ToString();
            if (!data.Contains("id"))
                return null;

            Users user = new Users();
            if(data.Contains("\"id\":"))
            {
                string id = data.Substring(data.IndexOf("\"id\":") + 6);
                id = id.Substring(0, id.IndexOf("\",\""));
                user.Id = id;
            }
            if (data.Contains("\"facebookid\":"))
            {
                string facebookId = data.Substring(data.IndexOf("\"facebookid\":") + 14);
                facebookId = facebookId.Substring(0, facebookId.IndexOf("\",\""));
                user.FacebookId = facebookId;
            }
            if (data.Contains("\"latitude\":"))
            {
                string latitude = data.Substring(data.IndexOf("\"latitude\":") + 11);
                latitude = latitude.Substring(0, latitude.IndexOf(",\""));
                double lat;
                if (double.TryParse(latitude, out lat))
                    user.Latitude = lat;
            }
            if (data.Contains("\"longitude\":"))
            {
                string longitude = data.Substring(data.IndexOf("\"longitude\":") + 12);
                longitude = longitude.Substring(0, longitude.IndexOf(",\""));
                double lng;
                if (double.TryParse(longitude, out lng))
                    user.Longitude = lng;
            }
            if (data.Contains("\"schoolid\":"))
            {
                try
                {
                    string schoolId = data.Substring(data.IndexOf("\"schoolid\":") + 12);
                    schoolId = schoolId.Substring(0, schoolId.IndexOf("\"}"));
                    if (schoolId != "null")
                        user.SchoolId = schoolId;
                }
                catch { }
            }
            return user;
        }

        List<Users> users = GetByProc("getuserbypushdevicetoken", string.Format("pushdevicetoken={0}", pushTokenId));
        if (users.Count > 0)
            return users[0];

        return null;
    }

    public static Users GetByDeviceId(string deviceId)
    {
        List<Users> users = GetByProcFast("getuserbydeviceid", string.Format("deviceid={0}", deviceId));
        if (users.Count > 0)
            return users[0];

        return null;
    }

    public static Users GetByEmail(string email)
    {
        List<Users> users = GetByWhere(string.Format("(email%20eq%20'{0}')", email));
        if (users.Count > 0)
            return users[0];

        return null;
    }

    public static List<Users> GetInterns()
    {
        List<Users> users = GetByWhere("(isintern%20eq%201)");
        return users;
    }

    public static string GetInternHtml()
    {
        List<Users> users = GetInterns();
        users = users.OrderBy(u => u.Name).ToList();

        string html = "<table><tr class='header'><td>Name</td><td class='inviteToggle'><div class='invite'>Non Pow Wow Invited</div></td><td class='inviteToggle'><div class='invite'>Pow Wow Invited</div></td><td class='eventsToggle'><div class='events'>Events Created</div></td><td class='eventsToggle'><div class='events'>Attending</div></td><td class='groupsToggle'><div class='groups'>Groups Created</div></td><td class='groupsToggle'><div class='groups'>Member</div></td><td class='inviteToggle'><div class='invite'>Non Pow Wow Invited</div></td><td class='inviteToggle'><div class='invite'>Pow Wow Invited</div></td><td class='eventsToggle'><div class='events'>Events Created</div></td><td class='eventsToggle'><div class='events'>Events Attending</div></td><td class='groupsToggle'><div class='groups'>Groups Created</div></td><td class='groupsToggle'><div class='groups'>Group Member</div></td></tr>";
        bool even = false;
        foreach(Users user in users)
        {
            if(string.IsNullOrEmpty(user.Name))
                continue;

            List<Event> events = Event.GetByUser(user.Id);
            List<Group> groups = Group.GetByUserId(user.Id);
            List<EventInvited> invited = EventInvited.GetByInvitedBy(user.Id);
            bool hide = invited.Count > 6 || events.Count > 4 || groups.Count > 6;

            html += even ? "<tr class='even'>" : "<tr>";
            html += hide ? string.Format("<td><a>{0}</a></td>", user.Name) : string.Format("<td>{0}</td>", user.Name);

            int nonPowwowInvitedCt = 0;
            string powwowInvited = "";
            string nonPowwowInvited = "";
            foreach (EventInvited ivt in invited)
            {
                if (string.IsNullOrEmpty(ivt.FacebookId))
                {
                    nonPowwowInvitedCt++;
                    if(nonPowwowInvited.Contains(ivt.EventId))
                    {
                        string inviteString = string.Format("{0}<br/>", ivt.Name);
                        nonPowwowInvited = nonPowwowInvited.Replace(string.Format("[{0}]</span>", ivt.EventId), string.Format("[{0}]</span>{1}", ivt.EventId, inviteString));
                    }
                    else
                    {
                        Event evt = Event.Get(ivt.EventId);

                        DateTime timeUtc = DateTime.SpecifyKind(Convert.ToDateTime(evt.StartTime), DateTimeKind.Utc);
                        TimeZoneInfo cstZone = TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time");
                        DateTime cstTime = TimeZoneInfo.ConvertTimeFromUtc(timeUtc, cstZone);

                        nonPowwowInvited += string.Format("<a href='../App/?eventId={0}' target='_blank'>{1} - {2}</a><br/><span style='display:none;'>[{0}]</span>", evt.Id, evt.Name, cstTime.ToString("ddd M/d h:mm tt"));
                        string inviteString = string.Format("{0}<br/>", ivt.Name);
                        nonPowwowInvited = nonPowwowInvited.Replace(string.Format("[{0}]</span>", ivt.EventId), string.Format("[{0}]</span>{1}", ivt.EventId, inviteString));
                    }
                }
                else
                {
                    if (powwowInvited.Contains(ivt.EventId))
                    {
                        string inviteString = string.Format("<a href='http://facebook.com/{0}' target='_blank'>{1}</a><br/>", ivt.FacebookId, ivt.Name);
                        powwowInvited = powwowInvited.Replace(string.Format("[{0}]</span>", ivt.EventId), string.Format("[{0}]</span>{1}", ivt.EventId, inviteString));
                    }
                    else
                    {
                        Event evt = Event.Get(ivt.EventId);

                        DateTime timeUtc = DateTime.SpecifyKind(Convert.ToDateTime(evt.StartTime), DateTimeKind.Utc);
                        TimeZoneInfo cstZone = TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time");
                        DateTime cstTime = TimeZoneInfo.ConvertTimeFromUtc(timeUtc, cstZone);

                        powwowInvited += string.Format("<a href='../App/?eventId={0}' target='_blank'>{1} - {2}</a><br/><span style='display:none;'>[{0}]</span>", evt.Id, evt.Name, cstTime.ToString("ddd M/d h:mm tt"));
                        string inviteString = string.Format("<a href='http://facebook.com/{0}' target='_blank'>{1}</a><br/>", ivt.FacebookId, ivt.Name);
                        powwowInvited = powwowInvited.Replace(string.Format("[{0}]</span>", ivt.EventId), string.Format("[{0}]</span>{1}", ivt.EventId, inviteString));
                    }
                }
            }
            html += string.Format("<td><div class='invite'>{0}</div></td><td><div class='invite'>{1}</div></td>", nonPowwowInvitedCt.ToString(), (invited.Count - nonPowwowInvitedCt).ToString());


            int eventAdminCt = 0;
            string createdInfo = "";
            string attendingInfo = "";
            foreach (Event evt in events)
            {
                DateTime timeUtc = DateTime.SpecifyKind(Convert.ToDateTime(evt.StartTime), DateTimeKind.Utc);
                TimeZoneInfo cstZone = TimeZoneInfo.FindSystemTimeZoneById("Central Standard Time");
                DateTime cstTime = TimeZoneInfo.ConvertTimeFromUtc(timeUtc, cstZone);

                if (evt.IsAdmin == true)
                {
                    eventAdminCt++;
                    createdInfo += string.Format("<a href='../App/?eventId={0}' target='_blank'>{1} - {2}</a><br/>", evt.Id, evt.Name, cstTime.ToString("ddd M/d h:mm tt"));
                }
                else
                {
                    attendingInfo += string.Format("<a href='../App/?eventId={0}' target='_blank'>{1} - {2}</a><br/>", evt.Id, evt.Name, cstTime.ToString("ddd M/d h:mm tt"));
                }
            }
            html += string.Format("<td><div class='events'>{0}</div></td><td><div class='events'>{1}</div></td>", eventAdminCt.ToString(), (events.Count - eventAdminCt).ToString());
            
            
            int groupAdminCt = 0;
            string createdGroupInfo = "";
            string attendingGroupInfo = "";
            foreach (Group group in groups)
            {
                GroupUsers groupUser = GroupUsers.Get(group.Id, user.Id, false);
                if (groupUser.IsAdmin)
                {
                    groupAdminCt++;
                    group.Members = GroupUsers.GetByGroup(group.Id);
                    createdGroupInfo += string.Format("{0} - {1} Members<br/>", group.Name, group.Members.Count.ToString());
                }
                else
                {
                    attendingGroupInfo += string.Format("{0}<br/>", group.Name);
                }
            }

            html += string.Format("<td><div class='groups'>{0}</div></td><td><div class='groups'>{1}</div></td>", groupAdminCt.ToString(), (groups.Count - groupAdminCt).ToString());

            if (hide) 
            {
                html += string.Format("<td><div class='details invite hide hiderow'>{0}</div></td><td><div class='details invite hide hiderow'>{1}</div></td>", nonPowwowInvited, powwowInvited);
                html += string.Format("<td><div class='details events hide hiderow'>{0}</div></td><td><div class='details events hide hiderow'>{1}</div></td>", createdInfo, attendingInfo);
                html += string.Format("<td><div class='details groups hide hiderow'>{0}</div></td><td><div class='details groups hide hiderow'>{1}</div></td>", createdGroupInfo, attendingGroupInfo);
            }   
            else
            {
                html += string.Format("<td><div class='details invite'>{0}</div></td><td><div class='details invite'>{1}</div></td>", nonPowwowInvited, powwowInvited);
                html += string.Format("<td><div class='details events'>{0}</div></td><td><div class='details events'>{1}</div></td>", createdInfo, attendingInfo);
                html += string.Format("<td><div class='details groups'>{0}</div></td><td><div class='details groups'>{1}</div></td>", createdGroupInfo, attendingGroupInfo);
            }

            html += "</tr>";
            even = !even;
        }
        html += "</table>";
        return html;
    }

    /// <summary>
    /// Encrypts the specified to encrypt.
    /// </summary>
    /// <param name="toEncrypt">To encrypt.</param>
    /// <param name="useHashing">if set to <c>true</c> [use hashing].</param>
    /// <returns>
    /// The encrypted string to be stored in the Database
    /// </returns>
    public static string Encrypt(string encryptionKey, string toEncrypt, bool useHashing)
    {
        byte[] keyArray;
        byte[] toEncryptArray = UTF8Encoding.UTF8.GetBytes(toEncrypt);

        System.Configuration.AppSettingsReader settingsReader =
                                            new AppSettingsReader();

        //If hashing use get hashcode regards to your key
        if (useHashing)
        {
            MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
            keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(encryptionKey));
            //Always release the resources and flush data
            // of the Cryptographic service provide. Best Practice

            hashmd5.Clear();
        }
        else
            keyArray = UTF8Encoding.UTF8.GetBytes(encryptionKey);

        TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();
        //set the secret key for the tripleDES algorithm
        tdes.Key = keyArray;
        //mode of operation. there are other 4 modes.
        //We choose ECB(Electronic code Book)
        tdes.Mode = CipherMode.ECB;
        //padding mode(if any extra byte added)

        tdes.Padding = PaddingMode.PKCS7;

        ICryptoTransform cTransform = tdes.CreateEncryptor();
        //transform the specified region of bytes array to resultArray
        byte[] resultArray =
          cTransform.TransformFinalBlock(toEncryptArray, 0,
          toEncryptArray.Length);
        //Release resources held by TripleDes Encryptor
        tdes.Clear();
        //Return the encrypted data into unreadable string format
        return Convert.ToBase64String(resultArray, 0, resultArray.Length);
    }

    /// <summary>
    /// Decrypts the specified encryption key.
    /// </summary>
    /// <param name="encryptionKey">The encryption key.</param>
    /// <param name="cipherString">The cipher string.</param>
    /// <param name="useHashing">if set to <c>true</c> [use hashing].</param>
    /// <returns>
    ///  The decrypted string based on the key
    /// </returns>
    public static string Decrypt(string encryptionKey, string cipherString, bool useHashing)
    {
        byte[] keyArray;
        //get the byte code of the string

        byte[] toEncryptArray = Convert.FromBase64String(cipherString);

        System.Configuration.AppSettingsReader settingsReader =
                                            new AppSettingsReader();

        if (useHashing)
        {
            //if hashing was used get the hash code with regards to your key
            MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();
            keyArray = hashmd5.ComputeHash(UTF8Encoding.UTF8.GetBytes(encryptionKey));
            //release any resource held by the MD5CryptoServiceProvider

            hashmd5.Clear();
        }
        else
        {
            //if hashing was not implemented get the byte code of the key
            keyArray = UTF8Encoding.UTF8.GetBytes(encryptionKey);
        }

        TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();
        //set the secret key for the tripleDES algorithm
        tdes.Key = keyArray;
        //mode of operation. there are other 4 modes.
        //We choose ECB(Electronic code Book)

        tdes.Mode = CipherMode.ECB;
        //padding mode(if any extra byte added)
        tdes.Padding = PaddingMode.PKCS7;

        ICryptoTransform cTransform = tdes.CreateDecryptor();
        byte[] resultArray = cTransform.TransformFinalBlock(
                             toEncryptArray, 0, toEncryptArray.Length);
        //Release resources held by TripleDes Encryptor
        tdes.Clear();
        //return the Clear decrypted TEXT
        return UTF8Encoding.UTF8.GetString(resultArray);
    }
}
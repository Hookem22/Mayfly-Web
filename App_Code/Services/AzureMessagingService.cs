using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Threading.Tasks;
using System.Net.Http;
using System.Web.Http;
using System.Net;
using System.Security.Cryptography;
using System.Globalization;
using System.IO;
using System.Text;

/// <summary>
/// Summary description for AzureMessagingService
/// </summary>
public class AzureMessagingService
{

    public static void Send(string alert, string message, string facebookId)
    {
        facebookId = "10106153174286280";
        Users user = Users.GetByFacebookId(facebookId);
        if (user == null || string.IsNullOrEmpty(user.PushDeviceToken))
            return;

        string os = !string.IsNullOrEmpty(user.DeviceId) ? "apple" : "gcm";
        Push(alert, message, user.PushDeviceToken.Replace(" ", ""), os);
    }

    private const string KEYNAME = "DefaultFullSharedAccessSignature";
    private const string KEY = "Xx0XVX29Gb0hPyBsoB7BYD0SUPiNYSQAB21Y115OXME=";

    private static void Push(string alert, string message, string tag, string os)
    {
        string url = "https://mayflyapphub-ns.servicebus.windows.net/mayflyapphub/messages";
        string data = "{\"aps\":{\"badge\":1,\"alert\":\"" + alert + "\",\"message\": \"" + message + "\"}}";
        if (os == "gcm")
            data = "{\"data\":{\"message\":\"" + alert + "\"}}";
        var sasToken = createToken("http://mayflyapphub-ns.servicebus.windows.net/mayflyapphub", KEYNAME, KEY);

        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        request.Method = "POST";
        request.ContentType = "application/json;charset=utf-8";
        request.ContentLength = data.Length;
        request.Headers.Add("Authorization", sasToken);
        request.Headers.Add("ServiceBusNotification-Format", os);
        if(!string.IsNullOrEmpty(tag))
            request.Headers.Add("ServiceBusNotification-Tags", tag);
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
                if (webStream != null)
                {
                    using (StreamReader responseReader = new StreamReader(webStream))
                    {
                        string response = responseReader.ReadToEnd();
                        Console.Out.WriteLine(response);
                    }
                }
            }
        }
        catch (Exception e)
        {
            Console.Out.WriteLine("-----------------");
            Console.Out.WriteLine(e.Message);
        }

    }

    /// <summary> 
    /// Code  for generating of SAS token for authorization with Service Bus 
    /// </summary> 
    /// <param name="resourceUri"></param> 
    /// <param name="keyName"></param> 
    /// <param name="key"></param> 
    /// <returns></returns> 
    private static string createToken(string resourceUri, string keyName, string key)
    {
        TimeSpan sinceEpoch = DateTime.UtcNow - new DateTime(1970, 1, 1);
        var expiry = Convert.ToString((int)sinceEpoch.TotalSeconds + 3600); //EXPIRES in 1h 
        string stringToSign = HttpUtility.UrlEncode(resourceUri) + "\n" + expiry;
        HMACSHA256 hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));

        var signature = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(stringToSign)));
        var sasToken = String.Format(CultureInfo.InvariantCulture,
        "SharedAccessSignature sr={0}&sig={1}&se={2}&skn={3}",
            HttpUtility.UrlEncode(resourceUri), HttpUtility.UrlEncode(signature), expiry, keyName);

        return sasToken;
    }

}
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

    #endregion

    public static Users Login(dynamic me, string deviceId, string pushDeviceToken, string email, string password)
    {
        Users user = new Users();
        if(!string.IsNullOrEmpty(email) && !string.IsNullOrEmpty(password))
        {
            user = GetByEmail(email);
            if (user == null)
                return null;

            string pwd = Decrypt(ENCRYPT_KEY, user.Password, true);
            if (pwd == password)
            {
                if((!string.IsNullOrEmpty(deviceId) && deviceId != user.DeviceId) || (!string.IsNullOrEmpty(pushDeviceToken) && pushDeviceToken != user.PushDeviceToken))
                {
                    user.DeviceId = deviceId;
                    user.PushDeviceToken = pushDeviceToken;
                    user.Save();
                }
                return user;
            }
                
            return null;
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
                user = SignUpFromFacebook(me, deviceId, pushDeviceToken);
            }
        }
        if (user.PushDeviceToken != pushDeviceToken && !string.IsNullOrEmpty(pushDeviceToken))
        {
            user.DeviceId = deviceId;
            user.PushDeviceToken = pushDeviceToken;
            user.Save();
        }

        return user;
    }

    public static Users SignUpFromFacebook(dynamic me, string deviceId, string pushDeviceToken)
    {
        Users user = new Users();
        user.FacebookId = me.id;
        user.Name = me.name;
        user.FirstName = me.first_name;
        user.Email = me.email;
        user.DeviceId = deviceId;
        user.PushDeviceToken = pushDeviceToken;
        user.Save();

        EmailService.SendWelcomeEmail(user.Email);

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

    public static Users GetByPushTokenId(string pushTokenId)
    {
        List<Users> users = GetByWhere(string.Format("(pushdevicetoken%20eq%20'{0}')", pushTokenId));
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
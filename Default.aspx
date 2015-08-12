<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="img/favicon.png" />
    <link href="/Styles/StyleSheet.css" rel="stylesheet" type="text/css" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script type="text/javascript">
        var appUrl = "/App";

        $(document).ready(function () {
            var mobParam = getParameterByName("id");
            var isMobile = mobilecheck() || tabletCheck() || mobParam == "m";
            if (isMobile) {
                $("body").addClass("Mobile");
            }

            //var appBanner = '<meta name="apple-itunes-app" content="app-id=1009503264"/>';
            //var iOS = (navigator.userAgent.match(/iPad|iPhone|iPod/g) ? true : false);
            //if (document.URL.indexOf("?") > 0) {
            //    if (document.URL.indexOf("?") > 0) {
            //        var referralId = document.URL.substr(document.URL.indexOf("?") + 1);
            //        appBanner = '<meta name="apple-itunes-app" content=\"app-id=1009503264, app-argument=fb397533583786525://?' + referralId + '\" />';
            //    }
            //    appUrl = "/App?" + document.URL.substr(document.URL.indexOf("?") + 1);
            //}
            ////else if (iOS) {
            ////    window.location = "https://itunes.apple.com/us/app/pow-wow-events/id1009503264?ls=1&mt=8";
            ////}

            //$('head').append(appBanner);

            $("#loginLink").click(function () {
                login();
            });
        });

    </script>
    <script type="text/javascript">
        var fbAccessToken = "";

        window.fbAsyncInit = function () {
            FB.init({
                appId: '397533583786525', // App ID
                status: true, // check login status
                cookie: true, // enable cookies to allow the server to access the session
                xfbml: true  // parse XFBML
            });

            FB.getLoginStatus(function (response) {
                if (response.status === 'connected') {
                    // the user is logged in and has authenticated your
                    // app, and response.authResponse supplies
                    // the user's ID, a valid access token, a signed
                    // request, and the time the access token 
                    // and signed request each expire
                    var uid = response.authResponse.userID;
                    fbAccessToken = response.authResponse.accessToken;

                } else if (response.status === 'not_authorized') {
                    console.log(response);

                } else {
                    console.log(response);
                }
            });
        };

        function login() {
            if (fbAccessToken)
            {
                window.location = appUrl;
                return;
            }
            else if (navigator.userAgent.match('CriOS')) {
                var appId = "397533583786525";
                var redirect = "http://joinpowwow.com/App";
                window.location = 'https://www.facebook.com/dialog/oauth?client_id=' + appId + '&redirect_uri=' + redirect + '&scope=public_profile,email,user_friends';
                return;
            }
            FB.login(function (response) {
                if (response.status === 'connected') {
                    var uid = response.authResponse.userID;
                    fbAccessToken = response.authResponse.accessToken;

                    var success = (function () {
                        window.location = appUrl;
                    });
                    Post("Login", { facebookId: uid }, success);
                }
                else {

                }

            }, { scope: 'public_profile,email,user_friends' });
        }

        // Load the SDK Asynchronously
        (function (d) {
            var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
            if (d.getElementById(id)) { return; }
            js = d.createElement('script'); js.id = id; js.async = true;
            js.src = "//connect.facebook.net/en_US/all.js";
            ref.parentNode.insertBefore(js, ref);
        } (document));
</script>
</head>
<body>
 <div id="fb-root"></div>
    <form id="form1" runat="server">
    <div class="header">
        <img class="title" src="Img/title.png" />
    </div>
    <div class="content">
        <h1 style="font-size:3.5em;font-weight:300;line-height:1.1;text-align:center;margin:.3em 0 0;">Find Your Tribe</h1>
        <h2 style="font-size:2em;font-weight: bold;text-align:center;margin:.2em 0 .4em;">Events near you today</h2>
<%--        <div class="links">
            <a href="https://itunes.apple.com/us/app/pow-wow-events/id1009503264?ls=1&mt=8"><img src="Img/appStoreLogo.png" /></a>
            <div style="font-size:24px;margin: 11px 16px;">or</div>
            <a id="loginLink" href="#"><img src="Img/facebookLoginButton.png" /></a>
        </div>--%>
        <a id="loginLink" href="#" style="left: 50%;position: absolute;margin-left: -124px;"><img src="Img/facebookLoginButton.png" /></a>
        <img style="margin:4em 0 0 10%;width:80%;" src="Img/appcombined.png" />

    </div>
    </form>
</body>
</html>

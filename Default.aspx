<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="img/favicon.png" />
    <link href="/Styles/StyleSheet.css?i=4" rel="stylesheet" type="text/css" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script type="text/javascript">
        var appUrl = "/App";

        $(document).ready(function () {
            var mobParam = getParameterByName("id");
            var isMobile = mobilecheck() || tabletCheck() || mobParam == "m";
            if (!isMobile) {
                $("body").removeClass("Mobile");
                $(".buttons").css({ width: "314px" });
                $(".buttons img").css({ width: "150px", height: "45px" });
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

            //$("#loginLink").click(function () {
            //    login();
            //});
        });

    </script>

<%--    <script type="text/javascript">
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
</script>--%>
</head>
<body class="Mobile">
 <div id="fb-root"></div>
    <form id="form1" runat="server">
    <div class="header">
        <img class="title" src="Img/powwowtitle.png" />
    </div>
    <div class="content">
      <%--  <h1 style="font-size:3.5em;font-weight:300;line-height:1.1;text-align:center;margin:.3em 0 0;">Find Your Tribe</h1>
        <h2 style="font-size:2em;font-weight: bold;text-align:center;margin:.2em 0 .6em;">Events near you today</h2>
        <div class="links">
            <a href="https://itunes.apple.com/us/app/pow-wow-events/id1009503264?ls=1&mt=8"><img src="Img/appStoreLogo.png" /></a>
            <div style="font-size:24px;margin: 11px 16px;">or</div>
            <a id="loginLink" href="#"><img src="Img/facebookLoginButton.png" /></a>
        </div>
        <a id="loginLink" href="#" style="left: 50%;position: absolute;margin-left: -124px;"><img src="Img/facebookLoginButton.png" style="width: 248px;" /></a>
        --%>
        <img src="Img/whitearrows.png" style="left: 50%;position: relative;width: 174px;margin: 18px 0 33px -87px;" />
        <div style="position: relative;width: 60%;left: 20%;text-align: center;line-height: 32px;font-size: 24px;margin-bottom: 30px;">Get a live feed of activities on your campus.</div>
        <div class="buttons" style="margin:0 auto;width: 203px;">
            <a href="https://geo.itunes.apple.com/us/app/pow-wow-events/id1009503264?mt=8" style="float:left;"><img src="Img/app-store.png" style="width: 203px;height: 60px;margin: 4px 2px 4px;" /></a>
            <a href="https://play.google.com/store/apps/details?id=com.joinpowwow.powwow&hl=en" style="float:left;""><img src="Img/goog-play.png" style="width: 203px;height: 60px;margin: 4px 2px;" /></a>
        </div>
        <div style="display:none;margin-top:230px;border-bottom: 1px solid rgba(0,0,0,.12);-moz-box-shadow: 0px 5px 5px rgba(0,0,0,.2);-webkit-box-shadow: 0px 5px 5px rgba(0,0,0,.2);box-shadow: 0px 5px 5px rgba(0,0,0,.2);"></div>
        <div style="display:none;margin: 0 0 45px;position: relative;background-color: #EEEEEE;border-top: 1px solid #ccc;color:#333;border-bottom: 1px solid rgba(0,0,0,.12);-moz-box-shadow: 0px 5px 5px rgba(0,0,0,.2);-webkit-box-shadow: 0px 5px 5px rgba(0,0,0,.2);box-shadow: 0px 2px 5px rgba(0,0,0,.2);">
            <div style="padding: 29px 18px 18px;font-size: 18px;color: #555;" >
                <div style="border-top: 1px solid #ccc;margin-bottom: -11px;"></div>
                <div style="margin: 0 auto; width: 35%;text-align: center;background-color: #EEEEEE;">Upcoming</div>
            </div>
            <div style="height:80px;border-top: 1px solid #ccc;border-bottom: 1px solid #F2F2F2;position:relative;background:white;">
                <img src="Img/texascowboys.png" style="float:left;height: 50px;margin: 12px 20px;"/>
                <div style="position: absolute;left: 90px;right: 77px;top: 10px;">Harvest Moon 2015 featuring Pat Green</div>
                <div style="position: absolute;top: 10px;right: 15px;">6:00 PM</div>
            </div>
            <div style="height:80px;border-top: 1px solid #ccc;border-bottom: 1px solid #F2F2F2;position:relative;background:white;">
                <img src="https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash2/v/t1.0-1/c134.14.582.582/s160x160/1230086_588712264500480_1718281986_n.jpg?oh=262e27985ce7b0c66f4b5b291e336774&amp;oe=56CF561D&amp;__gda__=1455038075_5baa2b1665fd4641737b3daabb0c4f7a" style="float:left;height: 55px;margin: 12px 20px;"/>
                <div style="position: absolute;left: 90px;right: 77px;top: 10px;">French Club Study Group</div>
                <div style="position: absolute;top: 10px;right: 15px;">4:30 PM</div>
            </div>
            <div style="height:80px;border-top: 1px solid #ccc;border-bottom: 1px solid #F2F2F2;position:relative;background:white;">
                <img src="https://fbcdn-profile-a.akamaihd.net/hprofile-ak-xpa1/v/t1.0-1/c45.211.527.527/s50x50/558747_439877799427416_400831031_n.png?oh=209b12dfb5adc45c23532280b7be0fb6&oe=56D2D702&__gda__=1455685523_7efb43c835e758de7a72aa877d04ac5a" style="float:left;height: 55px;margin: 12px 20px;"/>
                <div style="position: absolute;left: 90px;right: 78px;top: 10px;">Student Entrepreneur Club</div>
                <div style="position: absolute;top: 10px;right: 15px;">7:00 PM</div>
            </div>
            <div style="height:80px;border-top: 1px solid #ccc;border-bottom: 1px solid #F2F2F2;position:relative;background:white;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/UT%26Tmark.png/80px-UT%26Tmark.png" style="float:left;height: 55px;margin: 12px 20px;"/>
                <div style="position: absolute;left: 90px;right: 77px;top: 10px;">UT Basketball Game</div>
                <div style="position: absolute;top: 10px;right: 15px;">8:00 PM</div>
            </div>
        </div>
        <img style="margin:2em 0 2em 10%;width:80%;" src="Img/appcombined.png" />

    </div>
    </form>

    <a title="Real Time Web Analytics" href="http://clicky.com/100894033"><img alt="Real Time Web Analytics" src="//static.getclicky.com/media/links/badge.gif" border="0" style="display:none;" /></a>
    <script src="//static.getclicky.com/js" type="text/javascript"></script>
    <script type="text/javascript">try { clicky.init(100894033); } catch (e) { }</script>
    <noscript><p><img alt="Clicky" width="1" height="1" src="//in.getclicky.com/100894033ns.gif" /></p></noscript>
</body>
</html>

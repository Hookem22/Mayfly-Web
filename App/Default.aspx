<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="App_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
   <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <link href="/Styles/App.css" rel="stylesheet" type="text/css" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script type="text/javascript">

        $(document).ready(function () {
            var mobParam = getParameterByName("id");
            var isMobile = mobilecheck() || tabletCheck() || mobParam == "m";
            if (isMobile) {
                $("body").addClass("Mobile");
            }

            if (!$("#FacebookId").val()) {
                var fbInterval = setInterval(function () {
                    if ($("#FacebookId").val()) {
                        clearInterval(fbInterval);
                        GetLocation();
                    }
                }, 500);
            }
            
        });

        function GetLocation()
        {
            navigator.geolocation.getCurrentPosition(LoadEvents);
        }

        function LoadEvents(position)
        {
            var success = (function (results) {
                var eventList = ReorderEvents(results);
                PopulateEvents(eventList);
            });
            Post("GetEvents", { latitude: position.coords.latitude, longitude: position.coords.longitude }, success);
        }

        function ReorderEvents(list)
        {
            var goingList = [];
            var invitedList = [];
            var otherList = [];

            var fbId = $("#FacebookId").val();
            for(var i = 0; i < list.length; i++)
            {
                var event = list[i];
                if (event.Going.indexOf(fbId) >= 0)
                    goingList.push(event);
                else if (event.Invited.indexOf(fbId) >= 0)
                    invitedList.push(event);
                else
                    otherList.push(event);
            }

            var eventList = $.merge($.merge(goingList, invitedList), otherList);
            return eventList;
        }

        function PopulateEvents(eventList)
        {
            console.log(eventList)
            var fbId = $("#FacebookId").val();
            var html = "";
            for (var i = 0; i < eventList.length; i++) {
                var event = eventList[i];
                var eventHtml = '<div class="event">{img}<div style="float:left;"><span style="color:#4285F4;;">{name}</span><div style="height:4px;"></div>{distance}</div><div style="float:right;">{time}<div style="height:4px;"></div>{going}</div></div>';
                var time = new Date(event.StartTime).toLocaleTimeString().replace(":00", "");
                eventHtml = eventHtml.replace("{name}", event.Name).replace("{distance}", event.Distance).replace("{time}", time).replace("{going}", event.HowManyGoing);
                if (event.Going.indexOf(fbId) >= 0)
                    eventHtml = eventHtml.replace("{img}", '<img class="going" src="https://graph.facebook.com/' + fbId + '/picture" />');
                else if (event.Invited.indexOf(fbId) >= 0)
                    eventHtml = eventHtml.replace("{img}", '<img src="../Img/invited.png" />');
                else if (event.IsPrivate)
                    eventHtml = eventHtml.replace("{img}", '<img src="../Img/lock.png" />');
                else
                    eventHtml = eventHtml.replace("{img}", '<img src="../Img/face' + Math.floor(Math.random() * 8) + '.png" />');

                html += eventHtml;
            }

            $(".content").html("");
            $(".content").append(html);
        }

    </script>
    <script type="text/javascript">
        var currentUser;

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
                    $("#FacebookId").val(uid);
                    var fbAccessToken = response.authResponse.accessToken;

                    var success = (function (results) {
                        currentUser = results;
                    });
                    Post("GetUser", { facebookAccessToken: fbAccessToken }, success);

                } else {
                    window.location = "../";
                }
            });
        };

        // Load the SDK Asynchronously
        (function (d) {
            var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
            if (d.getElementById(id)) { return; }
            js = d.createElement('script'); js.id = id; js.async = true;
            js.src = "//connect.facebook.net/en_US/all.js";
            ref.parentNode.insertBefore(js, ref);
        }(document));
</script>
</head>
<body>
    <div id="fb-root"></div>
    <input type="hidden" id="FacebookId" runat="server" />
    <form id="form1" runat="server">
    <div class="header">
        <div style="width: 420px;margin:auto;">
            <img class="title" src="/Img/title.png" />
            <img class="notifications" src="/Img/bell.png" />
        </div>
    </div>
    <div class="content">
        <div class="event">
            <img class="going" src="https://graph.facebook.com/10106153174286280/picture" />
            <div style="float:left;"><span style="color:#4285F4;;">Test</span><div style="height:4px;"></div>2 miles away</div>
            <div style="float:right;">11:37 PM<div style="height:4px;"></div>1 of 3</div>
        </div>
        <div class="event">
            <img src="../Img/invited.png" />
        </div>
        <div class="event">
            <img src="../Img/lock.png" />
        </div>
        <div class="event">
            <img src="../Img/face2.png" />
        </div>
        <div class="event">
            <img class="going" src="https://graph.facebook.com/10106153174286280/picture" />
        </div>
        <div class="event">
            <img src="../Img/invited.png" />
        </div>
        <div class="event">
            <img src="../Img/lock.png" />
        </div>
        <div class="event">
            <img src="../Img/face2.png" />
        </div>
    </div>
    </form>
</body>
</html>

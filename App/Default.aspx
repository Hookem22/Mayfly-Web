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
    <script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>
    <script type="text/javascript">
        var isMobile;
        var currentLat;
        var currentLng;
        var locationResults = [];
        var currentLocation = {};

        $(document).ready(function () {
            var mobParam = getParameterByName("id");
            isMobile = mobilecheck() || tabletCheck() || mobParam == "m";
            if (!isMobile) {
                $("body").removeClass("Mobile");
            }
            else
            {
                //$("#addMap").height($(document).height() - 475);
            }

            if (!$("#FacebookId").val()) {
                var fbInterval = setInterval(function () {
                    if ($("#FacebookId").val()) {
                        clearInterval(fbInterval);
                        navigator.geolocation.getCurrentPosition(LoadEvents);
                    }
                }, 500);
            }

            $("#notificationBtn").click(function () {
                NotificationClick();
            });

            $("#addBtn").click(function () {
                OpenFromBottom("addDiv");
            });

            $("#AddLocation").click(function () {
                $("#locationSearchTextbox").val("");
                OpenFromBottom("locationDiv");
            });

            $("#isPublicBtn").click(function () {
                PublicClick();
            });

            $("#inviteBtn").click(function () {
                OpenFromBottom("inviteDiv");
                Post("GetFriends", { facebookAccessToken: fbAccessToken }, PopulateFriends);
            });

            $("#filterFriendsTextbox").keyup(function () {
                FilterFriends();
            });

            $("#inviteResults").on("click", "div", function () {
                $(this).toggleClass("invited");
            });

            $("#locationSearchTextbox").keyup(function () {
                var search = $("#locationSearchTextbox").val();
                if (search.length < 3)
                    return;

                Post("GetLocations", { searchName: search, latitude: currentLat, longitude: currentLng }, PopulateLocations);
            });

            
        });

        function LoadEvents(position)
        {
            currentLat = position.coords.latitude;
            currentLng = position.coords.longitude;

            Post("GetEvents", { latitude: position.coords.latitude, longitude: position.coords.longitude }, PopulateEvents);
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

        function PopulateEvents(results)
        {
            var eventList = ReorderEvents(results);

            var fbId = $("#FacebookId").val();
            var html = "";
            for (var i = 0; i < eventList.length; i++) {
                var event = eventList[i];
                var eventHtml = '<div class="event">{img}<div style="float:left;"><span style="color:#4285F4;;">{name}</span><div style="height:4px;"></div>{distance}</div><div style="float:right;">{time}<div style="height:4px;"></div>{going}</div><div style="clear:both;"></div></div>';
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

            $(".content").html(html);
        }

        function SaveClick() {

            CloseToBottom("addDiv");
        }

        function PublicClick() {
            var marginLeft = $(".pillBtn .slider").css("margin-left") == "0px" ? "44%" : "0px";
            $(".pillBtn .slider").animate({ "margin-left": marginLeft }, 350, function () {
                $(".pillBtn div").not(".slider").toggleClass("selected");
            });
        }

        function PopulateLocations(locations) {
            locationResults = locations;
            var html = "";
            if (locationResults.length == 1 && !locationResults[0].Name) {
                html = '<div onclick="AddLocation(-1);" style="border:none;" ><span style="font-weight:bold;color:#4285F4;">Just use "' + $("#locationSearchTextbox").val() + '"</span></div>';
            }
            else {
                for (var i = 0; i < locationResults.length; i++) {
                    var location = locationResults[i];
                    var locationHtml = '<div onclick="AddLocation(' + i + ');" ><span style="font-weight:bold;">{Name}</span><div></div>{Address}</div>';
                    html += locationHtml.replace("{Name}", location.Name).replace("{Address}", location.Address);
                }
            }
            $("#locationResults").html(html);
        }

        function AddLocation(index) {
            if (index == -1) {
                var address = $("#locationSearchTextbox").val() + ", " + locationResults[0].Address;
                console.log(address);
                var geocoder = new google.maps.Geocoder();
                geocoder.geocode({ 'address': address }, function (results, status) {
                    if (status == google.maps.GeocoderStatus.OK) {
                        currentLocation = { Name: $("#locationSearchTextbox").val(), Address: $("#locationSearchTextbox").val(), Latitude: results[0].geometry.location.lat(), Longitude: results[0].geometry.location.lng() };
                        PlotMap(currentLocation.Name, currentLocation.Latitude, currentLocation.Longitude);
                        $("#AddLocation").val(currentLocation.Name);
                    }
                });
            }
            else {
                currentLocation = locationResults[index];
                PlotMap(currentLocation.Name, currentLocation.Latitude, currentLocation.Longitude);
                $("#AddLocation").val(currentLocation.Name);
            }

            CloseToBottom("locationDiv");
        }

        function PlotMap(name, lat, lng) {
            var latLng = new google.maps.LatLng(lat, lng);
            var mapOptions = {
                zoom: 15,
                center: latLng,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            }

            var map = new google.maps.Map(document.getElementById('addMap'), mapOptions);
            var marker = new google.maps.Marker({
                position: latLng,
                map: map,
                title: name
            });
        }

        function PopulateFriends(friendList) {

            var html = "<div style='color:white;background:#AAAAAA;'>Friends</div>";
            for (var i = 0; i < friendList.length; i++) {
                var friend = friendList[i];
                html += '<div facebookId="' + friend.FacebookId + '"><span>' + friend.Name + '</span><img src="/Img/check.png" /></div>';
            }
            $("#inviteResults").html(html);
        }

        function FilterFriends() {
            var filter = $("#filterFriendsTextbox").val();
            $("#inviteResults div").not(":eq(0)").each(function () {
                if (!filter || $(this).html().toLowerCase().indexOf(filter.toLowerCase()) >= 0)
                    $(this).show();
                else
                    $(this).hide();
            });
        }

        function AddInvites() {
            var html = "";
            $("#inviteResults div.invited").each(function () {
                var fbId = $(this).attr("facebookId");
                var name = $(this).find("span").html();
                if (name.indexOf(" ") >= 0)
                    name = name.substring(0, name.indexOf(" "));
                html += "<div facebookId='" + fbId + "' ><img src='https://graph.facebook.com/" + fbId + "/picture' /><div>" + name + "</div></div>";
            });

            $("#invitedFriends").html(html);
            CloseToBottom("inviteDiv");
        }

        function NotificationClick() {
            console.log($("#notificationDiv").is(':visible'));
            if ($("#notificationDiv").is(':visible'))
                CloseNotification();
            else
                LoadNotifications();
        }

        function LoadNotifications() {
            Post("GetNotifications", { facebookId: $("#FacebookId").val() }, PopulateNotifications);
        }

        function PopulateNotifications(results) {
            var html = "";
            for(var i = 0; i < results.length; i++)
            {
                var notification = results[i];
                var notificationHtml = '<div><span style="font-weight:bold;">{Message}</span><div></div>{SinceSent}</div>';
                notificationHtml = notificationHtml.replace("{Message}", notification.Message).replace("{SinceSent}", notification.SinceSent);
                html += notificationHtml;
            }

            $("#notificationDiv").html(html);
            OpenNotification();
        }

        function OpenNotification() {
            $("#notificationDiv").show();
            $("#notificationDiv").animate({ left: "25%" }, 350);
        }

        function CloseNotification() {
            $("#notificationDiv").animate({ left: "100%" }, 350, function() {
                $("#notificationDiv").hide();
            });
        }

    </script>
    <script type="text/javascript">
        var currentUser;
        var fbAccessToken;

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
                    fbAccessToken = response.authResponse.accessToken;

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
<body class="Mobile">
    <form id="form1" runat="server">
        <div id="fb-root"></div>
        <input type="hidden" id="FacebookId" runat="server" />
        <div class="header">
            <div>
                <img class="title" src="/Img/title.png" />
                <img id="notificationBtn" src="/Img/bell.png" />
            </div>
        </div>
        <div class="content">
            <%--<div class="event">
                <img class="going" src="https://graph.facebook.com/10106153174286280/picture" />
                <div style="float:left;"><span style="color:#4285F4;;">Test</span><div style="height:4px;"></div>2 miles away</div>
                <div style="float:right;">11:37 PM<div style="height:4px;"></div>1 of 3</div>
            </div>--%>
        </div>
        <img id="addBtn" src="../Img/add.png" />
        <div id="addDiv">
            <a onclick="CloseToBottom('addDiv');" style="position: absolute; left:5%;top:20px;color:#4285F4;">Cancel</a>
            <div style="font-size:1.1em;margin-top:18px;text-align: center;">Create Event</div>
            <a onclick="SaveClick();" style="position: absolute; right:5%;top:20px;color:#4285F4;">Create</a>
            <input type="text" placeholder="What do you want to do?" style="margin:12px 0;" />
            <textarea rows="4" placeholder="Details"></textarea>
            <input id="AddLocation" type="text" placeholder="Location" style="width:48%;float:left;" />
            <input type="text" placeholder="Start Time" style="width:32%;float:right;" />
            <div style="float:left;margin:16px 0;">Other People:</div>
            <input type="number" placeholder="Max" style="width:20%;float:right;margin-left:12px;" />
            <input type="number" placeholder="Min" style="width:20%;float:right;" />
            <div id="isPublicBtn" class="pillBtn" style="clear:both;">
                <div class="slider"></div>
                <div style="margin: -25px 0 0 18%;float:left;">Public</div>
                <div style="margin: -25px 18% 0 0;float:right;" class="selected">Private</div>
            </div>
            <div id="inviteBtn" style="text-align:center;color:#4285F4;margin: 16px 0 8px;">Invite Friends</div>
            <div id="invitedFriends"></div>
            <div id="addMap"></div>
        </div>
        <div id="locationDiv">
            <a onclick="CloseToBottom('locationDiv');" style="position: absolute; left:5%;top:20px;color:#4285F4;">Cancel</a>
            <div style="font-size:1.1em;margin-top:18px;text-align: center;">Add Location</div>
            <input id="locationSearchTextbox" type="text" placeholder="Search" style="margin:12px 0;" />
            <div id="locationResults"></div>
        </div>
        <div id="inviteDiv">
            <a onclick="CloseToBottom('inviteDiv');" style="position: absolute; left:5%;top:20px;color:#4285F4;">Cancel</a>
            <div style="font-size:1.1em;margin-top:18px;text-align: center;">Recipients</div>
            <a onclick="AddInvites();" style="position: absolute; right:5%;top:20px;color:#4285F4;">Add</a>
            <input id="filterFriendsTextbox" type="text" placeholder="Search" style="margin:12px 0;" />
            <div id="inviteResults"></div>
        </div>
        <div id="notificationDiv"></div>
    </form>
</body>
</html>

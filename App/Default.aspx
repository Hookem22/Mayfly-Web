﻿<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="App_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
   <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <link href="/Styles/App.css?i=7" rel="stylesheet" type="text/css" />
    <link href="/Styles/NonMobileApp.css" rel="stylesheet" type="text/css" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/jquery.touchSwipe.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>
    <script type="text/javascript">
        var isMobile;
        var isiOS;
        var isAndroid;
        var currentLat;
        var currentLng;
        var eventsResults = [];
        var currentEvent = {};
        var currentUser;

        $(document).ready(function () {
            Init();

            var scrollTimer;
            $(".content").scroll(function () {
                if (scrollTimer) {
                    clearTimeout(scrollTimer);
                }
                scrollTimer = setTimeout(function () {
                    if ($(".content").scrollTop() < 15) {
                        ShowLoading();
                        LoadEvents();
                    }
                    else if ($(".content").scrollTop() < 90) {
                        $(".content").animate({ scrollTop: "90" }, 350);
                    }
                }, 100);
            });

            $("#addBtn").click(function () {
                OpenAdd();
            });

            $(".content").on("click", ".event", function () {
                var event = eventResults[$(this).attr("index")];
                var invited = event.ReferenceId == getParameterByName("goToEvent");
                if (!currentUser || (!currentUser.Id && !invited)) {
                    OpenLogin();
                    return;
                }

                if (event.IsPrivate && !Contains(event.Going, currentUser.Id) && !Contains(event.Invited, currentUser.Id) && !invited) {
                    MessageBox("This event is private. You cannot join private events unless you are invited.");
                    return;
                }

                OpenDetails(event);
            });

            $("#isPublicBtn").click(function () {
                PublicClick();
            });

            $("#DetailsJoinBtn").click(function () {
                JoinEvent();
            });
            
            $("#deleteEventBtn").click(function () {
                $(".goBtn").html("Ok");
                ActionMessageBox("This will delete this event. Continue?", DeleteEvent);
            });
        });

        function Init()
        {
            ShowLoading();
            if ($(window).height() > 550)
                $(".content div").css("min-height", ($(window).height() - 135) + "px");

            isiOS = getParameterByName("OS") == "iOS";
            isAndroid = getParameterByName("OS") == "Android";

            var mobParam = getParameterByName("id");
            isMobile = mobilecheck() || tabletCheck() || mobParam == "m";

            if (isiOS || isAndroid || isMobile) {

                currentUser = {};
                var fbAccessToken = getParameterByName("fbAccessToken");
                var deviceId = getParameterByName("deviceId");
                var pushDeviceToken = getParameterByName("pushDeviceToken");
                if(fbAccessToken || pushDeviceToken)
                    Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken, email: "", password: "" }, LoginSuccess);

                currentLat = +getParameterByName("lat");
                currentLng = +getParameterByName("lng");

                if (currentLat && currentLng)
                    LoadEvents();

            }

            if (!isMobile) {
                $("body").addClass("NonMobile");
            }

        }

        function LoginSuccess(results) {
            currentUser = results;

            if (currentLat && currentLng) {
                LoadEvents();
            }
            else if (currentUser && currentUser.Latitude && currentUser.Longitude)
                ReceiveLocation(currentUser.Latitude, currentUser.Longitude);
        }

        function ReceiveLocation(lat, lng)
        {
            if (!(currentLat && currentLng && Math.abs(currentLat - (+lat)) < 1 && Math.abs(currentLng - (+lng)) < 1))
            {
                currentLat = +lat;
                currentLng = +lng;
                ShowLoading();
                LoadEvents();
            }

            if(currentUser && currentUser.Id)
            {
                currentUser.Latitude = currentLat;
                currentUser.Longitude = currentLng;
                Post("SaveUser", { user: currentUser });
            }
        }

        function GoToEvent(referenceId)
        {
            Post("GetEventByReference", { referenceId: referenceId }, OpenDetails);
            $("#detailsDiv").show();
            $("#detailsDiv").css({ top: "0" });
        }

        function OpenAdd(isEdit) {
            if (!currentUser || !currentUser.Id) {
                OpenLogin();
                return;
            }

            OpenFromBottom("addDiv");
            if (!isEdit) {
                $("#addHeader").html("Create Event");
                $("#AddSaveBtn").html("Create");
                $("#addDiv input, #addDiv textarea").val("");
                $("#addDiv .invitedFriendsScroll").html("");
                $("#AddMap").css("height", "165px").hide();
                $("#inviteBtn").show();
                $("#addDiv .invitedFriends").show();
                $("#deleteEventBtn").hide();
                SetPublic(false);
                currentEvent = {};
                currentLocation = {};
            }
            else {
                $("#addHeader").html("Edit Event");
                $("#AddName").val(currentEvent.Name);
                $("#AddSaveBtn").html("Save");
                $("#AddDetails").val(currentEvent.EventDescription);
                $("#AddLocation").val(currentEvent.LocationName);
                currentLocation = { Name: currentEvent.LocationName, Address: currentEvent.LocationAddress, Latitude: currentEvent.LocationLatitude, Longitude: currentEvent.LocationLongitude };
                $("#AddStartTime").val(ToLocalTime(currentEvent.StartTime));
                var min = currentEvent.MinParticipants > 1 ? currentEvent.MinParticipants : "";
                $("#AddMin").val(min);
                var max = currentEvent.MaxParticipants ? currentEvent.MaxParticipants : "";
                $("#AddMax").val(max);
                SetPublic(!currentEvent.isPrivate);
                $("#AddMap").css("height", "135px");
                PlotMap("AddMap", currentEvent.LocationName, currentEvent.LocationLatitude, currentEvent.LocationLongitude);
                $("#inviteBtn").hide();
                $("#addDiv .invitedFriendsScroll").html("");
                $("#addDiv .invitedFriends").hide();
                $("#deleteEventBtn").show();
            }
        }

        function LatLngReturn(position)
        {
            currentLat = position.coords.latitude;
            currentLng = position.coords.longitude;
            LoadEvents();
        }

        function LoadEvents()
        {
            Post("GetEvents", { latitude: currentLat, longitude: currentLng }, PopulateEvents);
        }

        function ReorderEvents(list)
        {
            if (!currentUser || !currentUser.Id)
                return list;

            var id = currentUser.Id;
            var goingList = [];
            var invitedList = [];
            var otherList = [];

            for(var i = 0; i < list.length; i++)
            {
                var event = list[i];
                if (Contains(event.Going, id))
                    goingList.push(event);
                else if (Contains(event.Invited, id) || event.ReferenceId == getParameterByName("goToEvent"))
                    invitedList.push(event);
                else
                    otherList.push(event);
            }

            var eventList = $.merge($.merge(goingList, invitedList), otherList);
            return eventList;
        }

        function PopulateEvents(results)
        {
            eventResults = ReorderEvents(results);

            var id = currentUser ? currentUser.Id : "";
            var fbId = currentUser ? currentUser.FacebookId : "";
            var html = "";
            for (var i = 0; i < eventResults.length; i++) {
                var event = eventResults[i];
                var isGoing = event.isGoing != null && event.Going.indexOf(id) >= 0;
                var goingCt = event.Going.split("|").length;
                if (!isGoing && event.MaxParticipants > 0 && goingCt >= event.MaxParticipants)
                    continue;

                var eventHtml = '<div index="{index}" class="event">{img}<div style="float:left;"><span style="color:#4285F4;;">{name}</span><div style="height:4px;"></div>{distance}</div><div style="float:right;text-align:right;">{time}<div style="height:4px;"></div>{going}</div><div style="clear:both;"></div></div>';
                var time = ToLocalTime(event.StartTime);
                eventHtml = eventHtml.replace("{index}", i).replace("{name}", event.Name).replace("{distance}", event.Distance).replace("{time}", time).replace("{going}", event.HowManyGoing);
                if (Contains(event.Going, id)) {
                    if(fbId)
                        eventHtml = eventHtml.replace("{img}", '<img class="going" src="https://graph.facebook.com/' + fbId + '/picture" />');
                    else
                        eventHtml = eventHtml.replace("{img}", '<img src="../Img/face' + Math.floor(Math.random() * 8) + '.png" />');
                }
                else if (Contains(event.Invited, id) || event.ReferenceId == getParameterByName("goToEvent"))
                    eventHtml = eventHtml.replace("{img}", '<img src="../Img/invited.png" />');
                else if (event.IsPrivate)
                    eventHtml = eventHtml.replace("{img}", '<img src="../Img/lock.png" />');
                else
                    eventHtml = eventHtml.replace("{img}", '<img src="../Img/face' + Math.floor(Math.random() * 8) + '.png" />');

                html += eventHtml;
            }

            $(".content div").html(html);
            $(".content").scrollTop(90);
            HideLoading();
        }

        function OpenCreate(event)
        {
            $("#AddName").val(event.Name);
            $("#AddDetails").val(event.EventDescription);
            $("#AddLocation").val(event.LocationName);
            
            currentLocation.Name = event.LocationName;
            currentLocation.Address = event.LocationAddress;
            currentLocation.Latitude = event.LocationLatitude;
            currentLocation.Longitude = event.LocationLongitude;
            
            SetPublic(!event.IsPrivate);
            var min = event.MinParticipants ? event.MinParticipants : "";
            $("#AddMin").val(min);
            var max = event.MaxParticipants ? event.MaxParticipants : "";
            $("#AddMax").val(max);

            if (event.StartTime)
                $("#AddStartTime").val(ToLocalTime(event.StartTime));

            if (currentLocation.Name && currentLocation.Latitude && currentLocation.Longitude)
            {
                $("#AddMap").css("height", "165px").hide();
                PlotMap("AddMap", currentLocation.Name, currentLocation.Latitude, currentLocation.Longitude);
            }

            var contacts = [];
            $(event.Invited.split("|")).each(function() {
                var info = this.split(":");
                if (info.length == 2) {
                    var friend = { name: info[1] };
                    contacts.push(friend);
                    if (info[0].indexOf("p") == 0)
                        friend.phone = info[0].substring(1, info[0].length);
                    else
                        friend.facebookId = info[0];
                }
            });
            
            AddInvites(contacts);

        }

        function OpenDetails(event) {

            currentEvent = event;
            OpenFromBottom("detailsDiv");
            $("#addDiv .invitedFriendsScroll").html("");

            $("#DetailsName").html(event.Name);
            if (/*event.IsPrivate &&*/ event.Invited && currentUser && event.Invited.indexOf(currentUser.Id) == 0) {
                var edit = " - <span onclick='OpenAdd(true);' style='color:#4285F4;'>Edit</span>";
                $("#DetailsName").append(edit);
            }
            $("#DetailsDetails").html(event.EventDescription);
            $("#DetailsLocation").html("Location: " + event.LocationName);
            $("#DetailsStartTime").html("Start Time: " + ToLocalTime(event.StartTime));
            //$("#DetailsCutoffTime").html("Join By: " + ToLocalTime(event.CutoffTime));

            UpdateDetailsGoing(event);

            setTimeout(function () {
                var mapHt = $(window).height() -$("#DetailsMap").offset().top - 60;
                if (mapHt < 165)
                    mapHt = 165;
                $("#DetailsMap").css("height", mapHt + "px");
                PlotMap("DetailsMap", event.LocationName, event.LocationLatitude, event.LocationLongitude);
            }, 400);
            if (Contains(event.Going, currentUser.Id))
                $("#DetailsJoinBtn").html("Unjoin");
            else
                $("#DetailsJoinBtn").html("Join");

            var messageSuccess = function (messages) {
                $(messages).each(function () {
                    if (this.Seconds < 60 * 30)
                        $(".messageBtn").attr("src", "/Img/newmessage.png");
                });
            }
            $(".messageBtn").attr("src", "/Img/message.png");
            Post("GetMessages", { eventId: currentEvent.Id }, messageSuccess);
        }

        function UpdateDetailsGoing(event) {
            var going = event.Going.split("|");
            var goingCt = going.length == 1 && !going[0] ? 0 : going.length;

            var invited = event.Invited.split("|");
            var invitedCt = invited.length == 1 && !invited[0] ? 0 : invited.length;

            var howMany = "Going " + goingCt;
            if (event.HowManyGoing)
                howMany += " (" + event.HowManyGoing + ")";
            $("#DetailsHowMany").html(howMany);

            var inviteHtml = "";
            for (var i = 0; i < goingCt; i++) {
                var fbId = going[i].split(":")[0];
                var name = going[i].split(":")[1];
                var src = fbId.indexOf("p") == 0 ? "/Img/face" + Math.floor(Math.random() * 8) + ".png" : "https://graph.facebook.com/" + fbId + "/picture";
                inviteHtml += "<div><img src='" + src + "' /><div class='goingIcon icon'><img src='/Img/greenCheck.png' /></div><div>" + name + "</div></div>";
            }
            for (var i = 0; i < invitedCt; i++) {
                var fbId = invited[i].split(":")[0];
                var name = invited[i].split(":")[1];
                var src = fbId.indexOf("p") == 0 ? "/Img/face" + Math.floor(Math.random() * 8) + ".png" : "https://graph.facebook.com/" + fbId + "/picture";
                var alreadyGoing = false;
                if (fbId.indexOf("p") == 0) {
                    for (var j = 0; j < goingCt; j++) {
                        if (name == going[j].split(":")[1])
                            alreadyGoing = true;
                    }
                }
                if (event.Going.indexOf(fbId) < 0 && !alreadyGoing)
                    inviteHtml += "<div><img class='invitedFbImg' src='" + src + "' /><div class='invitedIcon icon'><img src='/Img/invited.png' /></div><div>" + name + "</div></div>";
            }
            for (var i = goingCt; i < event.MaxParticipants; i++) {
                inviteHtml += "<div class='nonFb'><img src='/Img/grayface" + Math.floor(Math.random() * 8) + ".png' /><div>Open</div></div>";
            }
            var totalCt = event.MaxParticipants || goingCt + invitedCt;
            $("#DetailsInvitedFriends  .invitedFriendsScroll").css("width", ((totalCt * 70) + 25) + "px");

            $("#DetailsInvitedFriends .invitedFriendsScroll").html(inviteHtml);
        }

        function SaveClick() {

            $("#addDiv input, #addDiv textarea").removeClass("error");
            var error = false;
            if (!$("#AddName").val()) {
                $("#AddName").addClass("error");
                error = true;
            }
            if (!$("#AddLocation").val()) {
                $("#AddLocation").addClass("error");
                error = true;
            }
            if (!$("#AddStartTime").val()) {
                $("#AddStartTime").addClass("error");
                error = true;
            }
            //if (!$("#AddMin").val()) {
            //    $("#AddMin").addClass("error");
            //    error = true;
            //}
            if (error)
                return;

            
            var event = GetCreateEvent();

            if (new Date() > event.StartTime) {
                $("#AddStartTime").addClass("error");
                return;
            }

            var success = (function(event) {
                LoadEvents();
                CloseToBottom("addDiv");
                
                if (currentEvent.Id) {
                    currentEvent = event;
                    OpenDetails(currentEvent);
                }
                else {
                    SendInvites(event);
                }
            });
            Post("SaveEvent", { evt: event }, success);

            CloseToBottom("addDiv");
        }

        function GetCreateEvent() {
            var startTime = "";
            var cutoffTime = "";
            if ($("#AddStartTime").val())
            {
                var now = new Date();
                startTime = new Date();
                var time = $("#AddStartTime").val();
                var hr = +time.substring(0, time.indexOf(":"));
                time = time.substring(time.indexOf(":") + 1);
                var min = +time.substring(0, time.indexOf(" "));
                var AMPM = time.substring(time.length - 2, time.length);
                if (AMPM == "AM" && hr == 12)
                    hr = 0;
                if (AMPM == "PM" && hr != 12)
                    hr += 12;
                startTime.setHours(hr);
                startTime.setMinutes(min);
                startTime.setSeconds(0);

                var diffMinutes = parseInt((startTime - now) / (60 * 1000));
                var cutoffDiff = 0;
                if (diffMinutes > 29)
                    cutoffDiff = 15;
                if (diffMinutes > 59)
                    cutoffDiff = 30;
                if (diffMinutes > 179)
                    cutoffDiff = 60;

                var MS_PER_MINUTE = 60000;
                cutoffTime = new Date(startTime - cutoffDiff * MS_PER_MINUTE);
            }


            var invited = currentEvent.Invited || currentUser.Id + ":" + currentUser.FirstName;
            var going = currentEvent.Going ? currentEvent.Going : currentUser.Id + ":" + currentUser.FirstName;

            var max = +$("#AddMax").val();
            var min = +$("#AddMin").val();

            var event = {
                Name: $("#AddName").val(), EventDescription: $("#AddDetails").val(), LocationName: currentLocation.Name,
                LocationAddress: currentLocation.Address, LocationLatitude: currentLocation.Latitude, LocationLongitude: currentLocation.Longitude,
                IsPrivate: $("#isPublicBtn .selected").html() == "Private", MinParticipants: min, MaxParticipants: max,
                StartTime: startTime, CutoffTime: cutoffTime, Invited: invited, Going: going,
                NotificationMessage: "Created: " + $("#AddName").val(), UserId: currentUser.Id
            };

            if (currentEvent.Id) {
                event.Id = currentEvent.Id;
                event.NotificationMessage = "";
            }

            return event;
        }

        function PublicClick() {
            //MessageBox("Pow Wow currently does not have enough members near you to create public events. Invite your friends to enable public events.");

            var marginLeft = $(".pillBtn .slider").css("margin-left") == "0px" ? "44%" : "0px";
            $(".pillBtn .slider").animate({ "margin-left": marginLeft }, 350, function () {
                $(".pillBtn div").not(".slider").toggleClass("selected");
            });
        }

        function SetPublic(isPublic)
        {
            var marginLeft = isPublic ? "0px" : "44%";
            $(".pillBtn .slider").css({ "margin-left": marginLeft });
            $(".pillBtn div").removeClass("selected");
            var idx = isPublic ? 1 : 2;
            $(".pillBtn div:eq(" + idx +")").addClass("selected");
        }

        function JoinEvent()
        {
            if (!currentUser || !currentUser.Id) {
                var title = currentEvent ? "Log In to Join " + currentEvent.Name + " and Discover Activities Around You" : "Log In to Join This Event";
                $(".loginHeader").html(title);
                OpenLogin();
                return;
            }

            if ($("#DetailsJoinBtn").html() == "Join") {
                currentEvent.Going = AddToString(currentEvent.Going, currentUser.Id + ":" + currentUser.FirstName);

                currentEvent.NotificationMessage = "Joined: " + currentEvent.Name;
                $("#DetailsJoinBtn").html("Unjoin");
                var alert = currentUser.FirstName + " joined " + currentEvent.Name;
                var message = "";
                //Post("SendJoinMessage", { alert: alert, message: message, facebookId: currentUser.FacebookId, evt: currentEvent });
            }
            else {
                currentEvent.Going = RemoveFromString(currentEvent.Going, currentUser.Id);
                currentEvent.NotificationMessage = "Unjoined: " + currentEvent.Name;
                $("#DetailsJoinBtn").html("Join");
            }

            currentEvent.UserId = currentUser.UserId;
            UpdateDetailsGoing(currentEvent);
            Post("SaveEvent", { evt: currentEvent }, LoadEvents);
        }

        function DeleteEvent() {
            var success = function () {
                CloseToBottom('addDiv');
                CloseToBottom('detailsDiv', true);
            }
            Post("DeleteEvent", { evt: currentEvent }, success);
        }

    </script>

    <!-- Login -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#loginSignupEmailPlaceholder").click(function () {
                $("#loginSignupEmailTextBox").focus();
            });

            $(".loginSignupHeader .backarrow").click(function () {
                $("#loginSignupDiv").hide();
            });

            $("#loginSignupEmailTextBox").keyup(function () {
                if($(this).val())
                {
                    $(".loginOrDiv").hide();
                    $("#facebookLoginBtn").hide();
                    $(".loginLineDiv").show();
                    $("#signupNextBtn").show();
                    $("#loginSignupEmailPlaceholder").hide();
                }
                else
                {
                    $(".loginOrDiv").show();
                    $("#facebookLoginBtn").show();
                    $(".loginLineDiv").hide();
                    $("#signupNextBtn").hide();
                    $("#loginSignupEmailPlaceholder").show();
                }
            });

            $("#signupNextBtn").click(function () {
                $("#signupDiv").show().animate({ left: "0" }, 0);
                $("#signupEmailTextBox").val($("#loginSignupEmailTextBox").val());
                $("#signupNameTextBox").focus();
            });

            $(".signupHeader .backarrow").click(function () {
                $("#signupDiv").animate({ left: "150%" }, 0, function () { $("#signupDiv").hide(); });
            });

            $("#loginTabHeader").click(function () {
                $("#loginDiv").show().animate({ left: "0" }, 0);
                $("#loginEmailTextBox").focus();
            });

            $(".loginHeader .backarrow").click(function () {
                $("#loginDiv").animate({ left: "150%" }, 0, function () { $("#loginDiv").hide(); });
            });

            $("#forgotPasswordBtn").click(function () {
                $("#forgotPasswordDiv").show();
                $("#forgotPasswordEmailTextBox").focus();
            });

            $(".forgotPasswordHeader .backarrow").click(function () {
                $("#forgotPasswordDiv").hide(); 
            });

            $("#signupBtn").click(function () {
                var error = false;
                $("#signupContentDiv input").removeClass("error");
                if (!$("#signupEmailTextBox").val()) {
                    $("#signupEmailTextBox").addClass("error");
                    error = true;
                }
                if (!$("#signupNameTextBox").val()) {
                    $("#signupNameTextBox").addClass("error");
                    error = true;
                }
                if (!$("#signupPasswordTextBox").val()) {
                    $("#signupPasswordTextBox").addClass("error");
                    error = true;
                }
                if (error)
                    return;

                var name = $("#signupNameTextBox").val();
                var firstName = name.indexOf(" ") > 0 ? name.substring(0, name.indexOf(" ")) : name;

                var deviceId = getParameterByName("deviceId");
                var pushDeviceToken = getParameterByName("pushDeviceToken");

                var user = {
                    Name: name, FirstName: firstName, Email: $("#signupEmailTextBox").val(), Password: $("#signupPasswordTextBox").val(),
                    DeviceId: deviceId, PushDeviceToken: pushDeviceToken, Latitude: currentLat, Longitude: currentLng
                };

                Post("SignUpUser", { user: user }, LoginSuccess);
                $("#signupDiv").css({ left: "150%" }).hide();
                CloseToBottom("loginSignupDiv");
            });

            $("#loginBtn").click(function () {
                var error = false;
                $("#loginContentDiv input").removeClass("error");
                if (!$("#loginEmailTextBox").val()) {
                    $("#loginEmailTextBox").addClass("error");
                    error = true;
                }
                if (!$("#loginPasswordTextBox").val()) {
                    $("#loginPasswordTextBox").addClass("error");
                    error = true;
                }
                if (error)
                    return;

                var deviceId = getParameterByName("deviceId");
                var pushDeviceToken = getParameterByName("pushDeviceToken");

                var success = function (user) {
                    if(!user)
                        MessageBox("Email or Password is incorrect")
                    else {
                        $("#loginDiv").css({ left: "150%" }).hide();
                        CloseToBottom("loginSignupDiv");
                        LoginSuccess(user);
                    }
                }

                Post("LoginUser", { facebookAccessToken: "", deviceId: deviceId, pushDeviceToken: pushDeviceToken, email: $("#loginEmailTextBox").val(), password: $("#loginPasswordTextBox").val() }, success);

            });

            $(".facebookLoginBtn").click(function () {
                if (isiOS) {
                    window.location = "ios:FacebookLogin";
                }
                else if (isAndroid) {
                    if (typeof androidAppProxy !== "undefined")
                        androidAppProxy.AndroidFacebookLogin();
                }
            });

            $("#forgotPasswordSendBtn").click(function () {
                var success = function (result) {
                    $("#forgotPasswordDiv").hide();
                    $("#loginDiv").animate({ left: "150%" }, 0, function () { $("#loginDiv").hide(); });
                    CloseToBottom("loginSignupDiv");
                    if (result)
                        MessageBox(result);
                };

                Post("ForgotPassword", { email: $("#forgotPasswordEmailTextBox").val() }, success);
            });

        });

        function OpenLogin() {
            $("#loginSignupDiv").css({ top: 0 }).show();
            $("#loginSignupEmailTextBox").focus();
        }

    </script>

    <!-- Location -->
    <script type="text/javascript">
        var locationResults = [];
        var currentLocation = {};

        $(document).ready(function () {
            $("#AddLocation").focus(function () {
                $("#locationSearchTextbox").val("");
                $("#locationResults").html("");
                $("#locationDiv").show();
                $("#locationDiv").css({ top: "0" });
                $("#locationSearchTextbox").focus();
                //setTimeout(function () {
                //    $("#locationSearchTextbox").focus();
                    
                //}, 200);
                //setTimeout(function () {
                //    //$(document).scrollTop(0);
                //    //$("#locationDiv").height($(document).height());
                //}, 500);
                //OpenFromBottom("locationDiv");
            });

            $("#locationSearchTextbox").keyup(function () {
                var search = $("#locationSearchTextbox").val();
                if (search.length < 3) {
                    $("#locationResults").html("");
                    return;
                }

                Post("GetLocations", { searchName: search, latitude: currentLat, longitude: currentLng }, PopulateLocations);
            });

            $("#locationResults").on("click", "div", function () {
                var idx = $(this).attr("locationIdx");
                AddLocation(idx);
            });

        });

        function PopulateLocations(locations) {
            locationResults = locations;
            var html = "";
            if (locationResults.length == 1 && !locationResults[0].Name) {
                html = '<div locationIdx="-1" style="border:none;" ><span style="font-weight:bold;color:#4285F4;">Just use "' + $("#locationSearchTextbox").val() + '"</span></div>';
            }
            else {
                for (var i = 0; i < locationResults.length; i++) {
                    var location = locationResults[i];
                    var locationHtml = '<div locationIdx="' + i + '" ><span style="font-weight:bold;">{Name}</span><div></div>{Address}</div>';
                    html += locationHtml.replace("{Name}", location.Name).replace("{Address}", location.Address);
                }
            }
            $("#locationResults").html(html);
        }

        function AddLocation(index) {
            if (index == -1) {
                var address = $("#locationSearchTextbox").val() + ", " + locationResults[0].Address;
                var geocoder = new google.maps.Geocoder();
                geocoder.geocode({ 'address': address }, function (results, status) {
                    if (status == google.maps.GeocoderStatus.OK) {
                        currentLocation = { Name: $("#locationSearchTextbox").val(), Address: $("#locationSearchTextbox").val(), Latitude: results[0].geometry.location.lat(), Longitude: results[0].geometry.location.lng() };
                        PlotMap("AddMap", currentLocation.Name, currentLocation.Latitude, currentLocation.Longitude);
                        $("#AddLocation").val(currentLocation.Name);
                    }
                });
            }
            else {
                currentLocation = locationResults[index];
                PlotMap("AddMap", currentLocation.Name, currentLocation.Latitude, currentLocation.Longitude);
                $("#AddLocation").val(currentLocation.Name);
            }

            CloseToBottom("locationDiv");
            locationResults = [];
        }

        function PlotMap(mapName, name, lat, lng) {
            $("#" + mapName).show();

            var latLng = new google.maps.LatLng(lat, lng);
            var mapOptions = {
                zoom: 15,
                center: latLng,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            }

            var map = new google.maps.Map(document.getElementById(mapName), mapOptions);
            var marker = new google.maps.Marker({
                position: latLng,
                map: map,
                title: name
            });
        }

    </script>

    <!-- Messages -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#sendText").focus(function () {
                setTimeout(function () { $("#messageDiv").scrollTop($("#messageDiv").height()); }, 200)
            });

            $("#sendText").keypress(function (e) {
                if (e.which == 13) {
                    SendMessage();
                }
            });
        });

        function OpenMessages() {
            $("#addBtn").hide();
            $("#DetailMap").hide();
            $("#messageDiv").show();
            $("#messageDiv").animate({ left: "0" }, 350);
            $("#MessageName").html(currentEvent.Name);
            $(".messageBtn").attr("src", "/Img/message.png");
            LoadMessages();
        }

        function LoadMessages() {
            Post("GetMessages", { eventId: currentEvent.Id }, PopulateMessages);
        }

        function PopulateMessages(messages) {
            var html = "";
            for (var i = 0; i < messages.length; i++) {
                var message = messages[i];
                if (Contains(message.Id, currentUser.Id)) {
                    var messageHtml = "<div style='float:right;clear:both;margin-top: 8px;'>{SinceSent}</div><div class='meMessage'>{Message}</div>";
                    html += messageHtml.replace("{SinceSent}", message.SinceSent).replace("{Message}", message.Message);
                }
                else {
                    var messageHtml = "<div style='float:left;clear:both;margin-top: 8px;'>{From} - {SinceSent}</div><div class='youMessage'>{Message}</div>";
                    html += messageHtml.replace("{From}", message.Name).replace("{SinceSent}", message.SinceSent).replace("{Message}", message.Message);
                }
            }
            $("#MessageResults").html(html);
            $("#MessageResults").scrollTop($("#MessageResults").height());
        }

        function SendMessage() {
            var text = $("#messageDiv input").val();
            if(!text)
                return;
            
            var message = { EventId: currentEvent.Id, Name: currentUser.FirstName, Message: text, UserId: currentUser.Id };
            Post("SendMessage", { message: message }, LoadMessages);
            $("#messageDiv input").val("");
        }

        function CloseMessages() {
            $("#DetailMap").show();
            $("#addBtn").show();
            $("#messageDiv").animate({ left: "100%" }, 350, function () {
                $("#messageDiv").hide();
            });
        }

    </script>

    <!-- Notifications -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#notificationBtn").click(function () {
                NotificationClick();
            });

            $("#notificationDiv").on("click", "div", function () {
                var eventId = $(this).attr("eventid");
                OpenEventFromNotification(eventId);
            });

            $("body").on("click", ".content", function () {
                if($("#notificationDiv").is(':visible'))
                    CloseNotification();
            });

            $("#notificationDiv").swipe({
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    CloseNotification();
                }
            });

        });

        function NotificationClick() {
            if ($("#notificationDiv").is(':visible'))
                CloseNotification();
            else
                LoadNotifications();
        }

        function LoadNotifications() {
            Post("GetNotifications", { userId: currentUser.Id }, PopulateNotifications);
        }

        function PopulateNotifications(results) {
            var html = "";
            for(var i = 0; i < results.length; i++)
            {
                var notification = results[i];
                var notificationHtml = '<div eventid="{eventId}"><span style="font-weight:bold;">{Message}</span><div></div>{SinceSent}</div>';
                notificationHtml = notificationHtml.replace("{eventId}", notification.EventId).replace("{Message}", notification.Message).replace("{SinceSent}", notification.SinceSent);
                html += notificationHtml;
            }

            $("#notificationDiv").html(html);
            OpenNotification();
        }

        function OpenNotification() {
            $("#notificationDiv").show();
            if (isMobile)
                $("#notificationDiv").animate({ left: "25%" }, 350);
            else
                $("#notificationDiv").animate({ "margin-left": "-300px" }, 350);
        }

        function CloseNotification() {
            if (isMobile) {
                $("#notificationDiv").animate({ left: "100%" }, 350, function () {
                    $("#notificationDiv").hide();
                });
            }
            else {
                $("#notificationDiv").animate({ "margin-left": "0" }, 350, function () {
                    $("#notificationDiv").hide();
                });
            }
        }

        function OpenEventFromNotification(eventId) {
            Post("GetEvent", { id: eventId }, OpenDetails);
            CloseNotification();
        }

        function OpenReferredNotification(notification) {
            $(".goBtn").html("Go");
            ActionMessageBox(notification.Message, OpenEventFromNotification, notification.EventId);
        }
    </script>

    <!-- Clock -->
    <script type="text/javascript">
            $(document).ready(function () {
                $("#AddStartTime").click(function () {
                    InitClock();
                });

                $("#clockCircle").on("click", "div", function () {
                    $("#clockCircle div").removeClass("selected");
                    $(this).addClass("selected");
                    if ($(this).hasClass("hour")) {
                        HourClicked($(this).html());
                    }
                    else {
                        var time = $("#clockDiv .time").html();
                        var hr = time.substring(0, time.indexOf(":"));
                        var min = $(this).html();
                        if (min == "5")
                            min = "05";
                        var AMPM = time.substring(time.indexOf(" ") + 1);
                        time = hr + ":" + min + " " + AMPM;
                        $("#clockDiv .time").html(time);
                        $("#AddStartTime").val(time);
                        $("#clockDiv").fadeOut();
                        $(".modal-backdrop").fadeOut();
                    }
                });

                $(".ampm").click(function () {
                    $(".ampm").removeClass("selected");
                    $(this).addClass("selected");

                    var time = $("#clockDiv .time").html();
                    time = time.substring(0, time.indexOf(" ") + 1);
                    time += $(this).html();
                    $("#clockDiv .time").html(time)
                });
            });

            function InitClock() {
                $(".modal-backdrop").show();
                $("#clockDiv").show();
                $("#clockCircle").html("");

                var date = new Date;
                var hr = date.getHours();
                var AMPM = hr > 11 ? "PM" : "AM";

                $(".ampm").removeClass("selected");
                $(".ampm").each(function () {
                    if ($(this).html() == AMPM)
                        $(this).addClass("selected");
                });

                $("#clockDiv .time").html("--:-- " + AMPM);

                var wd = $("#clockCircle").width();
                $("#clockCircle").height(wd * .8);

                var radius = (wd / 2) * .7;
                var html = "";
                var centerX = wd / 2;
                var centerY = wd / 2 + 60;
                for (var i = 1; i < 13; i++) {
                    var x = Math.cos(2 * Math.PI * ((i - 3) / 12)) * radius + centerX;
                    var y = Math.sin(2 * Math.PI * ((i - 3) / 12)) * radius + centerY;
                    html += '<div class="hour" style="position:absolute;left:' + x + 'px;top:' + y + 'px;">' + i + '</div>';
                }
                $("#clockCircle").append(html);


                //if (!$("#clockDiv .time").html().length) {
                //    var date = new Date;
                //    var min = date.getMinutes();
                //    if (min < 10)
                //        min = "0" + min;
                //    var hr = date.getHours();
                //    var AMPM = "AM";
                //    if (hr > 11)
                //        AMPM = "PM";
                //    if (hr > 12)
                //        hr -= 12;
                //    if (hr == 0)
                //        hr = 12;

                //    $(".ampm").each(function () {
                //        if ($(this).html() == AMPM)
                //            $(this).addClass("selected");
                //    });

                //    $("#clockDiv .time").html(hr + ":" + min + " " + AMPM);
                //}
                //else {
                //    var time = $("#clockDiv .time").html();
                //    var hr = time.substring(0, time.indexOf(":"));
                //}

                //var wd = $("#clockCircle").width();
                //$("#clockCircle").height(wd * .8);

                //var radius = (wd / 2) * .7;
                //var html = "";
                //var centerX = wd / 2;
                //var centerY = wd / 2 + 60;
                //for (var i = 1; i < 13; i++) {
                //    var x = Math.cos(2 * Math.PI * ((i - 3) / 12)) * radius + centerX;
                //    var y = Math.sin(2 * Math.PI * ((i - 3) / 12)) * radius + centerY;
                //    if (i == hr) {
                //        html += '<div class="selected hour" style="position:absolute;left:' + x + 'px;top:' + y + 'px;">' + i + '</div>';
                //    }
                //    else {
                //        html += '<div class="hour" style="position:absolute;left:' + x + 'px;top:' + y + 'px;">' + i + '</div>';
                //    }

                //}
                //$("#clockCircle").append(html);
            }

            function HourClicked(hr) {

                var time = $("#clockDiv .time").html();
                time = time.substring(time.indexOf(":"));
                var min = +time.substring(1, time.indexOf(" "));
                time = hr + time;
                $("#clockDiv .time").html(time);

                var wd = $("#clockCircle").width();
                $("#clockCircle").fadeOut("slow", function () {
                    var radius = (wd / 2) * .7;
                    var html = "";
                    var centerX = wd / 2;
                    var centerY = wd / 2 + 60;
                    for (var i = 0; i < 12; i++) {
                        var x = Math.cos(2 * Math.PI * ((i - 3) / 12)) * radius + centerX;
                        var y = Math.sin(2 * Math.PI * ((i - 3) / 12)) * radius + centerY;
                        var val = i == 0 ? "00" : (i * 5);
                        if ((i - 1) * 5 < min && i * 5 >= min)
                            html += '<div class="selected" style="position:absolute;left:' + x + 'px;top:' + y + 'px;">' + val + '</div>';
                        else
                            html += '<div style="position:absolute;left:' + x + 'px;top:' + y + 'px;">' + val + '</div>';

                    }
                    $("#clockCircle").html(html);
                    $("#clockCircle").fadeIn("slow");
                });

            }

            function DrawLine(x1, y1, x2, y2) {

                if (y1 < y2) {
                    var pom = y1;
                    y1 = y2;
                    y2 = pom;
                    pom = x1;
                    x1 = x2;
                    x2 = pom;
                }

                var a = Math.abs(x1 - x2);
                var b = Math.abs(y1 - y2);
                var c;
                var sx = (x1 + x2) / 2;
                var sy = (y1 + y2) / 2;
                var width = Math.sqrt(a * a + b * b);
                var x = sx - width / 2;
                var y = sy;

                a = width / 2;
                c = Math.abs(sx - x);
                b = Math.sqrt(Math.abs(x1 - x) * Math.abs(x1 - x) + Math.abs(y1 - y) * Math.abs(y1 - y));

                var cosb = (b * b - a * a - c * c) / (2 * a * c);
                var rad = Math.acos(cosb);
                var deg = (rad * 180) / Math.PI

                htmlns = "http://www.w3.org/1999/xhtml";
                div = document.createElementNS(htmlns, "div");
                div.setAttribute('style', 'border:1px solid #4285F4;width:' + width + 'px;height:0px;-moz-transform:rotate(' + deg + 'deg);-webkit-transform:rotate(' + deg + 'deg);position:absolute;top:' + y + 'px;left:' + x + 'px;');

                document.getElementById("clockDiv").appendChild(div);

            }
    </script>

    <!-- Facebook -->
    <script type="text/javascript">
        //var currentUser;
        //var fbAccessToken;

        //window.fbAsyncInit = function () {
            
        //    FB.init({
        //        appId: '397533583786525', // App ID
        //        status: true, // check login status
        //        cookie: true, // enable cookies to allow the server to access the session
        //        xfbml: true  // parse XFBML
        //    });

        //    fbAccessToken = getParameterByName("fbAccessToken");
        //    var deviceId = getParameterByName("deviceId");
        //    var pushDeviceToken = getParameterByName("pushDeviceToken");
        //    if (fbAccessToken) {
        //        Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);
        //    }
        //    else
        //    {
        //        FB.getLoginStatus(function (response) {

        //            if (response.status === 'connected') {
        //                // the user is logged in and has authenticated your
        //                // app, and response.authResponse supplies
        //                // the user's ID, a valid access token, a signed
        //                // request, and the time the access token 
        //                // and signed request each expire
        //                var uid = response.authResponse.userID;
        //                $("#FacebookId").val(uid);
        //                fbAccessToken = response.authResponse.accessToken;

        //                Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);

        //            } else {
        //                Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);
        //                //if (!fbAccessToken)
        //                //    window.location = "../";
        //                //else
        //                //    Post("LoginUser", { facebookAccessToken: fbAccessToken }, LoginSuccess);
        //            }
        //        });
        //    }
        //};

        //function LoginSuccess(results) {
        //    currentUser = results;
        //    $("#FacebookId").val(currentUser.FacebookId);
        //    //LoadEvents();
        //    /*TODO: fix
        //    if (document.URL.indexOf("?") > 0) {
        //        var referenceId = document.URL.substr(document.URL.indexOf("?") + 1);
        //        Post("GetReferredNotification", { referenceId: referenceId, facebookId: currentUser.FacebookId }, OpenReferredNotification);
        //    }
        //    */
        //}

        //function OpenFacebookLogin()
        //{
        //    OpenFromBottom("facebookLoginDiv");
        //}

        //function FacebookLogin() {
        //    if (isiOS) {
        //        window.location = "ios:FacebookLogin";
        //    }
        //    else if(isAndroid)
        //    {
        //        if (typeof androidAppProxy !== "undefined")
        //            androidAppProxy.AndroidFacebookLogin();
        //    }
        //    else
        //    {
        //        FB.login(function (response) {
        //            if (response.authResponse) {
        //                var uid = response.authResponse.userID;
        //                $("#FacebookId").val(uid);
        //                fbAccessToken = response.authResponse.accessToken;
        //                var deviceId = getParameterByName("deviceId");
        //                var pushDeviceToken = getParameterByName("pushDeviceToken");

        //                Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);
        //                CloseToBottom('facebookLoginDiv');
        //            } else {
        //                console.log('User cancelled login or did not fully authorize.');
        //            }
        //        });
        //    }
        //}

        //function FacebookLogout() {
        //    FB.logout(function (response) {
        //        // user is now logged out
        //    });
        //}

        //// Load the SDK Asynchronously
        //(function (d) {
        //    var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
        //    if (d.getElementById(id)) { return; }
        //    js = d.createElement('script'); js.id = id; js.async = true;
        //    js.src = "//connect.facebook.net/en_US/all.js";
        //    ref.parentNode.insertBefore(js, ref);
        //}(document));
    </script>

    <!-- Branch -->
    <script type="text/javascript">

        (function (b, r, a, n, c, h, _, s, d, k) { if (!b[n] || !b[n]._q) { for (; s < _.length;) c(h, _[s++]); d = r.createElement(a); d.async = 1; d.src = "https://cdn.branch.io/branch-v1.6.7.min.js"; k = r.getElementsByTagName(a)[0]; k.parentNode.insertBefore(d, k); b[n] = h } })(window, document, "script", "branch", function (b, r) { b[r] = function () { b._q.push([r, arguments]) } }, { _q: [], _v: 1 }, "init data first addListener removeListener setIdentity logout track link sendSMS referrals credits creditHistory applyCode validateCode getCode redeem banner closeBanner".split(" "), 0);

        branch.init('key_live_hmpTgy1sVLhPXtjDUW5hVoldyDfpel4T', function (err, data) {
            // callback to handle err or data
        });

        function GetBranchLink(event, phoneList, message)
        {
            branch.link({
                channel: isiOS ? "iOS" : isAndroid ? "Android" : "Web",
                feature: 'share',
                stage: 'Event Invite',
                data: {
                    ReferenceName: currentUser.Name,
                    ReferenceId: event.ReferenceId
                }
            }, function (err, link) {
                message = message.replace("{Branch}", link);
                SendText(phoneList, message);
                //console.log(err, link);
            });
        }

        //function SendBranchSMS()
        //{
        //    branch.sendSMS(
        //        '7135015344',
        //        {
        //            tags: ['tag1', 'tag2'],
        //            channel: 'facebook',
        //            feature: 'dashboard',
        //            stage: 'new user',
        //            data: {
        //                mydata: 'something',
        //                foo: 'bar',
        //                '$desktop_url': 'http://myappwebsite.com',
        //                '$ios_url': 'http://myappwebsite.com/ios',
        //                '$ipad_url': 'http://myappwebsite.com/ipad',
        //                '$android_url': 'http://myappwebsite.com/android',
        //                '$og_app_id': '12345',
        //                '$og_title': 'My App',
        //                '$og_description': 'My app\'s description.',
        //                '$og_image_url': 'http://myappwebsite.com/image.png'
        //            }
        //        },
        //        { make_new_link: true }, // Default: false. If set to true, sendSMS will generate a new link even if one already exists.
        //        function (err) { console.log(err); }
        //    );
        //}

</script>

</head>
<body>
    <form id="form1" runat="server">
        <div id="fb-root"></div>
        <input type="hidden" id="FacebookId" runat="server" />
        <div class="modal-backdrop"></div>
        <div class="loading"><img src="../Img/loading.gif" /></div>
        <div class="header">
            <div>
                <img class="title" src="/Img/title.png" />
                <img id="notificationBtn" src="/Img/bell.png" />
            </div>
        </div>
        <div class="content">
            <div style="min-height:500px;"></div>
        </div>
        <img id="addBtn" src="../Img/add.png" />
        <div id="addDiv">
            <div>
            <a onclick="CloseToBottom('addDiv', true);" style="position: absolute; left:5%;top:25px;color:#4285F4;">Cancel</a>
            <div id="addHeader" style="font-size:1.1em;margin-top:23px;text-align: center;">Create Event</div>
            <a id="AddSaveBtn" onclick="SaveClick();" style="position: absolute; right:5%;top:25px;color:#4285F4;font-weight: bold;">Create</a>
            <input id="AddName" type="text" placeholder="What do you want to do?" style="margin:12px 0 4px;" />
            <input id="AddLocation" type="text" placeholder="Location" style="width:48%;float:left;margin-bottom:4px;" />
            <input id="AddStartTime" type="text" placeholder="Start Time" readonly="readonly" style="width:32%;float:right;" />
            <textarea id="AddDetails" rows="4" placeholder="Details"></textarea>
            <div style="float:left;margin:16px 0;">Total People?</div>
            <input id="AddMax" type="number" placeholder="Max" style="width:15%;float:right;margin-left:4px;" />
            <input id="AddMin" type="number" placeholder="Min" style="width:15%;float:right;" />
            <div id="isPublicBtn" class="pillBtn" style="margin-bottom:16px;clear:both;">
                <div class="slider"></div>
                <div style="margin: -25px 0 0 18%;float:left;">Public</div>
                <div style="margin: -25px 18% 0 0;float:right;" class="selected">Private</div>
            </div>
            <div id="inviteBtn" style="text-align:center;color:#4285F4;margin: 0 0 8px;">Invite Friends</div>
            <div class="invitedFriends"><div class="invitedFriendsScroll"></div></div>
            <div id="AddMap" style="clear:both;"></div>
            <div id="deleteEventBtn" style="text-align:center;color:#4285F4;margin: 16px 0 8px;display:none;">Close Event</div>
            </div>
        </div>
        <div id="detailsDiv">
            <div>
            <a onclick="CloseToBottom('detailsDiv', true);" style="position: absolute; left:5%;top:25px;color:#4285F4;">Done</a>
            <div id="DetailsName" style="font-size:1.1em;margin:23px 0;text-align: center;"></div>
            <img onclick="OpenMessages();" class="messageBtn" src="/Img/message.png" style="position: absolute; right:5%;top:18px;height:32px;" />
            <div id="DetailsDetails" style="margin-bottom:12px;"></div>
            <div id="DetailsLocation" style="margin-bottom: 4px;"></div>
            <div id="DetailsStartTime" style="margin-bottom: 10px;"></div>
            <%--<div id="DetailsCutoffTime" style="margin-bottom: 4px;"></div>--%>
            <div id="DetailsHowMany" style="text-align:center;"></div>
            <div id="DetailsInvitedFriends" class="invitedFriends" ><div class="invitedFriendsScroll"></div></div>
            <div id="DetailsInvitedBtn" style="text-align:center;color:#4285F4;margin: 10px 0 18px;clear: both;">Invite Friends</div>
            <div id="DetailsMap"></div>
            <div id="DetailsJoinBtn" class="bottomBtn" style="position:fixed;top:100%;margin-top: -42px;bottom:initial;">Join</div>
            </div>
        </div>
        <div id="messageDiv">
            <div>
            <div style="top: 0;left:0;right:0;position:fixed;background:white;border-bottom:1px solid #ccc;z-index:500;">
                <a onclick="CloseMessages();" style="position: absolute; left:5%;top:20px;color:#4285F4;">Cancel</a>
                <div id="MessageName" style="font-size:1.1em;margin:18px 0;text-align: center;"></div>
            </div>
            <div id="MessageResults"></div>
            <div id="sendDiv">
                <input id="sendText" type="text" placeholder="Message" />
                <div onclick="SendMessage();">Send</div>
            </div>
            </div>
        </div>
        <div id="locationDiv">
            <div>
            <a onclick="CloseToBottom('locationDiv');" style="position: absolute; left:5%;top:20px;color:#4285F4;">Cancel</a>
            <div style="font-size:1.1em;margin-top:18px;text-align: center;">Add Location</div>
            <input id="locationSearchTextbox" type="text" placeholder="Search" style="margin:12px 0;" />
            <div id="locationResults"></div>
            </div>
        </div>
        <div id="inviteDiv">
            <div>
            <a onclick="CloseToBottom('inviteDiv');" style="position: absolute; left:5%;top:20px;color:#4285F4;">Cancel</a>
            <div style="font-size:1.1em;margin-top:18px;text-align: center;">Recipients</div>
            <a id="Invite" style="position: absolute; right:5%;top:20px;color:#4285F4;">Add</a>
            <input id="filterFriendsTextbox" type="text" placeholder="Search" style="margin:12px 0;" />
            <div id="inviteResults" class="addressBookList"></div>
            <div id="contactResults" class="addressBookList"></div>
            </div>
        </div>
        <div id="notificationDiv"></div>
        <div id="loginSignupDiv">
            <div class="loginSignupHeader">
                <img class="backarrow" src="/Img/whitebackarrow.png" />
                <img class="title" src="/Img/title.png" />
                <div class="subtitle">Sign up to discover activities<br /> near you today.</div>
                <div id="signupTabHeader" class="loginTabHeaders selected">SIGN UP<div class="arrowUp"></div></div>
                <div id="loginTabHeader" class="loginTabHeaders" style="left: 50%;">LOG IN<div class="arrowUp"></div></div>
            </div>
            <div id="signupTab">
                <input id="loginSignupEmailTextBox" /><div id="loginSignupEmailPlaceholder" >Enter your email</div>
                <div class="loginOrDiv" style="float:left;border-top:1px solid #B5B5B5;margin:8px 0 0 5%;width: 38%;"></div><div class="loginOrDiv" style="float:left;width:13.8%;text-align: center;color:#B5B5B5">OR</div><div class="loginOrDiv" style="float:right;border-top:1px solid #B5B5B5;margin:8px 5% 0 0;width: 38%;"></div>
                <div id="facebookLoginBtn" class="facebookLoginBtn" style="clear: both;text-align: center;color:#4285F4;"><img src="../Img/fbIcon.png" style="height: 20px;margin: 8px 10px 0 0;vertical-align: bottom;" />Sign up with Facebook</div>
                <div class="loginLineDiv" style="float:left;border-top:1px solid #B5B5B5;margin:8px 0 0 5%;width: 90%;margin-bottom: 12px;display:none;"></div>
                <div id="signupNextBtn" style="text-align: center;color:#4285F4;font-size:20px;display:none;">Next</div>
            </div>
        </div>
        <div id="signupDiv">
            <div class="signupHeader">
                <img class="backarrow" src="/Img/whitebackarrow.png" />
                <img class="title" src="/Img/title.png" />
            </div>
            <div id="signupContentDiv">
                <img src="../Img/grayenvelope.png" /><input id="signupEmailTextBox" placeholder="Your email" />
                <img src="../Img/grayface.png" style="margin-top: 2px;" /><input id="signupNameTextBox" placeholder="Your name" />
                <img src="../Img/graylock.png" style="margin-top: 0;" /><input id="signupPasswordTextBox" type="password" placeholder="Password" />
                <div id="signupBtn">Sign Up</div>
            </div>
        </div>
        <div id="loginDiv">
            <div class="loginHeader">
                <img class="backarrow" src="/Img/whitebackarrow.png" />
                <img class="title" src="/Img/title.png" />
            </div>
            <div id="loginContentDiv">
                <img src="../Img/grayenvelope.png" /><input id="loginEmailTextBox" placeholder="Your email" />
                <img src="../Img/graylock.png" /><input id="loginPasswordTextBox" type="password" placeholder="Password" />
                <div id="forgotPasswordBtn">Forgot?</div>
                <div id="loginBtn" style="margin-bottom:12px;">Log In</div>
                <div style="float:left;border-top:1px solid #B5B5B5;margin:8px 0 0 5%;width: 38%;"></div><div style="float:left;width:13.8%;text-align: center;color:#B5B5B5">OR</div><div style="float:right;border-top:1px solid #B5B5B5;margin:8px 5% 0 0;width: 38%;"></div>
                <div class="facebookLoginBtn" style="clear: both;text-align: center;color:#4285F4;"><img src="../Img/fbIcon.png" style="height: 20px;margin: 8px 10px 0 0;vertical-align: bottom;float: none;" />Log in with Facebook</div>

            </div>
        </div>
        <div id="forgotPasswordDiv">
            <div class="forgotPasswordHeader">
                <img class="backarrow" src="/Img/whitebackarrow.png" />
                <img class="title" src="/Img/title.png" />
            </div>
            <div id="forgotPasswordContentDiv">
                <img src="../Img/grayenvelope.png" /><input id="forgotPasswordEmailTextBox" placeholder="Your email" />
                <div id="forgotPasswordSendBtn" style="margin-bottom:12px;">Send Password</div>
            </div>
        </div>
        <div id="clockDiv">
            <div class="time"></div>
            <div id="clockCircle"></div>
            <div class="ampm" style="float:left;">AM</div>
            <div class="ampm" style="float:right;">PM</div>
            <div onclick='$("#clockDiv").fadeOut();$(".modal-backdrop").fadeOut();' class="bottomBtn" >Cancel</div>
        </div>
        <div id="MessageBox">
            <div class="messageContent"></div>
            <div onclick="CloseMessageBox();" class="bottomBtn">Ok</div>
        </div>
        <div id="ActionMessageBox">
            <div class="messageContent"></div>
            <div class="goBtn bottomBtn" style="left:0;right:50%;"">Go</div><div onclick="CloseMessageBox();" class="bottomBtn" style="left:50%;right:0;border-left:1px solid #ccc;">Cancel</div>
        </div>
    </form>
</body>
</html>

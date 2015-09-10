<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="App_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
   <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <link href="/Styles/App.css" rel="stylesheet" type="text/css" />
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
                if (!currentUser.FacebookId && !invited) {
                    OpenFacebookLogin();
                    return;
                }

                if (event.IsPrivate && !Contains(event.Going, currentUser.FacebookId) && !Contains(event.Invited, currentUser.FacebookId) && !invited) {
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

            if (isiOS) {
                isMobile = true;
                iOSInit();
                return;
            }
            else if (isAndroid)
            {
                isMobile = true;
                AndroidInit();
                return;
            }

            var mobParam = getParameterByName("id");
            isMobile = mobilecheck() || tabletCheck() || mobParam == "m";
            if (!isMobile) {
                $("body").addClass("NonMobile");
            }
            else {
                //$("#AddMap").height($(document).height() - 475);
            }

            //var fbInterval = setInterval(function () {
            //    if ($("#FacebookId").val() || fbAccessToken) {
            //        clearInterval(fbInterval);
            //        var lat = getParameterByName("lat");
            //        var lng = getParameterByName("lng");
            //        if (lat && lng) {
            //            currentLat = lat;
            //            currentLng = lng;
            //        }
            //        else {
            //            navigator.geolocation.getCurrentPosition(LatLngReturn);
            //        }
            //    }
            //}, 500);
        }

        function ReceiveLocation(lat, lng)
        {
            currentLat = lat;
            currentLng = lng;
            LoadEvents();
        }

        function GoToEvent(referenceId)
        {
            Post("GetEventByReference", { referenceId: referenceId }, OpenDetails);
            $("#detailsDiv").show();
            $("#detailsDiv").css({ top: "0" });
        }

        function OpenAdd(isEdit) {
            if (!currentUser.FacebookId) {
                OpenFacebookLogin();
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
            var bobList = [];
            var goingList = [];
            var invitedList = [];
            var otherList = [];

            var fbId = $("#FacebookId").val();
            for(var i = 0; i < list.length; i++)
            {
                var event = list[i];
                //if(event.Invited && event.Invited.indexOf("10106610968977054") == 0)
                //    bobList.push(event);
                if (Contains(event.Going, fbId))
                    goingList.push(event);
                else if (Contains(event.Invited, fbId) || event.ReferenceId == getParameterByName("goToEvent"))
                    invitedList.push(event);
                else
                    otherList.push(event);
            }

            var eventList = $.merge($.merge($.merge(bobList, goingList), invitedList), otherList);
            return eventList;
        }

        function PopulateEvents(results)
        {
            eventResults = ReorderEvents(results);

            var fbId = $("#FacebookId").val();
            var html = "";
            for (var i = 0; i < eventResults.length; i++) {
                var event = eventResults[i];
                var isGoing = event.isGoing != null && event.Going.indexOf(fbId) >= 0;
                var goingCt = event.Going.split("|").length;
                if (!isGoing && event.MaxParticipants > 0 && goingCt >= event.MaxParticipants)
                    continue;

                var eventHtml = '<div index="{index}" class="event">{img}<div style="float:left;"><span style="color:#4285F4;;">{name}</span><div style="height:4px;"></div>{distance}</div><div style="float:right;text-align:right;">{time}<div style="height:4px;"></div>{going}</div><div style="clear:both;"></div></div>';
                var time = ToLocalTime(event.StartTime);
                eventHtml = eventHtml.replace("{index}", i).replace("{name}", event.Name).replace("{distance}", event.Distance).replace("{time}", time).replace("{going}", event.HowManyGoing);
                if (Contains(event.Going, fbId))
                    eventHtml = eventHtml.replace("{img}", '<img class="going" src="https://graph.facebook.com/' + fbId + '/picture" />');
                else if (Contains(event.Invited, fbId) || event.ReferenceId == getParameterByName("goToEvent"))
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
            if (/*event.IsPrivate &&*/ event.Invited && currentUser && event.Invited.indexOf(currentUser.FacebookId) == 0) {
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
            if (Contains(event.Going, currentUser.FacebookId))
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
            console.log(event);
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


            var invited = currentEvent.Invited || currentUser.FacebookId + ":" + currentUser.FirstName;
            $("#addDiv .invitedFriendsScroll div").each(function () {
                if ($(this).attr("facebookId")) {
                    invited += "|" + $(this).attr("facebookId");
                    var name = $(this).find("div").html();
                    if (name.indexOf(" ") > 0)
                        name = name.substring(0, name.indexOf(" "));
                    invited += ":" + name;
                }
                if ($(this).attr("phone")) {
                    invited += "|p" + $(this).attr("phone");
                    var name = $(this).find("div").html();
                    if (name.indexOf(" ") > 0)
                        name = name.substring(0, name.indexOf(" "));
                    invited += ":" + name;
                }
            });
            if (!invited)
                invited = "";

            var going = currentEvent.Going ? currentEvent.Going : currentUser.FacebookId + ":" + currentUser.FirstName;
            if (!going)
                going = "";

            var max = +$("#AddMax").val();
            var min = +$("#AddMin").val();

            var event = {
                Name: $("#AddName").val(), EventDescription: $("#AddDetails").val(), LocationName: currentLocation.Name,
                LocationAddress: currentLocation.Address, LocationLatitude: currentLocation.Latitude, LocationLongitude: currentLocation.Longitude,
                IsPrivate: $("#isPublicBtn .selected").html() == "Private", MinParticipants: min, MaxParticipants: max,
                StartTime: startTime, CutoffTime: cutoffTime, Invited: invited, Going: going,
                NotificationMessage: "Created: " + $("#AddName").val(), FacebookId: currentUser.FacebookId
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
            if (!currentUser.FacebookId) {
                var title = currentEvent ? "Log In to Join " + currentEvent.Name + " and Discover Activities Around You" : "Log In to Join This Event";
                $(".loginHeader").html(title);
                OpenFacebookLogin();
                return;
            }

            if ($("#DetailsJoinBtn").html() == "Join") {
                currentEvent.Going = AddToString(currentEvent.Going, currentUser.FacebookId + ":" + currentUser.FirstName);

                currentEvent.NotificationMessage = "Joined: " + currentEvent.Name;
                $("#DetailsJoinBtn").html("Unjoin");
                var alert = currentUser.FirstName + " joined " + currentEvent.Name;
                var message = "";
                Post("SendJoinMessage", { alert: alert, message: message, facebookId: currentUser.FacebookId, evt: currentEvent });
            }
            else {
                currentEvent.Going = RemoveFromString(currentEvent.Going, currentUser.FacebookId);
                currentEvent.NotificationMessage = "Unjoined: " + currentEvent.Name;
                $("#DetailsJoinBtn").html("Join");
            }

            currentEvent.FacebookId = currentUser.FacebookId;
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

    <!-- Friends / Address Book -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#inviteBtn").click(function () {

                $("#Invite").html("Add");
                if (isiOS && !$("#contactResults").html())
                {
                    window.location = "ios:GetContacts";
                    //var event = JSON.stringify(GetCreateEvent());
                    //window.location = "ios:InviteFromCreate" + GetReturnUrlParameters() + "&createEvent=" + event;
                }
                //else if (isAndroid)
                //{
                //    if (typeof androidAppProxy !== "undefined") {
                //        androidAppProxy.getContacts("Message from JavaScript");
                //    } else {
                //        alert("Running outside Android app");
                //    }
                //}
                else
                {
                    OpenAddressBook();
                }

            });

            $("#Invite").click(function () {
                if ($(this).html() == "Add") {
                    AddInvitesToCreate();
                }
                else {
                    SendInvitesFromAddressBook();
                }
            });

            $("#DetailsInvitedBtn").click(function () {
                OpenDetailsInvite();
            });

            $("#filterFriendsTextbox").keyup(function () {
                FilterFriends();
            });

            $("#inviteResults").on("click", "div", function () {
                $(this).toggleClass("invited");
            });

            $("#contactResults").on("click", "div", function () {
                $(this).toggleClass("invited");
            });
        });

        function OpenDetailsInvite()
        {
            $("#Invite").html("Invite");
            if (isiOS && !$("#contactResults").html())
            {
                window.location = "ios:GetContacts";
            }
            else
            {
                OpenAddressBook();
            }
        }

        function OpenAddressBook()
        {
            OpenFromBottom("inviteDiv");
            $("#filterFriendsTextbox").val("");

            $("#inviteResults div").removeClass("invited").show();
            $("#contactResults div").removeClass("invited").show();

            $("#addDiv .invitedFriendsScroll div").each(function () {
                if ($(this).attr("facebookId")) {
                    var fbId = $(this).attr("facebookId");
                    $("#inviteResults div").each(function () {
                        if ($(this).attr("facebookId") == fbId)
                            $(this).addClass("invited");
                    });
                }
                if ($(this).attr("phone")) {
                    var phone = $(this).attr("phone");
                    $("#contactResults div").each(function () {
                        if ($(this).attr("phone") == phone)
                            $(this).addClass("invited");
                    });
                }
            });

            if (!$("#inviteResults").html())
                Post("GetFriends", { facebookAccessToken: fbAccessToken }, PopulateAddressBook);
        }

        function PopulateAddressBook(friendList) {
            var html = "<div style='color:white;background:#AAAAAA;'>Friends</div>";
            for (var i = 0; i < friendList.length; i++) {
                var friend = friendList[i];
                html += '<div facebookId="' + friend.FacebookId + '"><span>' + friend.Name + '</span><img src="/Img/check.png" /></div>';
            }
            $("#inviteResults").html(html);
        }

        function AndroidContacts(contactString) {
            var contacts = contactString.split("||");
            var contactArray = [];
            for (var i = 0; i < contacts.length; i++) {
                var contact = contacts[i].split("|");
                var contactObject = {};
                if (contact && contact[0] && contact[1]) {
                    contactObject.Name = contact[1];
                    contactObject.Phone = contact[0];
                    contactArray.push(contactObject);
                }                   
            }
            contactArray.sort(function (a, b) {
                return a.Name.localeCompare(b.Name);
            });

            var html = "<div style='color:white;background:#AAAAAA;'>Contacts</div>";
            for (var i = 0; i < contactArray.length; i++) {
                html += '<div phone="' + contactArray[i].Phone + '"><span>' + contactArray[i].Name + '</span><img src="/Img/check.png" /></div>';
            }
            $("#contactResults").html(html);

            if (fbAccessToken && !$("#inviteResults").html())
                Post("GetFriends", { facebookAccessToken: fbAccessToken }, PopulateAddressBook);
        }

        function iOSContacts(contactString) {
            var contacts = contactString.split("||");
            var contactArray = [];
            for (var i = 0; i < contacts.length; i++) {
                var contact = contacts[i].split("|");
                var contactObject = {};
                if (contact && contact[0] && contact[1]) {
                    contactObject.Name = contact[1];
                    contactObject.Phone = contact[0];
                    contactArray.push(contactObject);
                }
            }
            contactArray.sort(function (a, b) {
                return a.Name.localeCompare(b.Name);
            });

            var html = "<div style='color:white;background:#AAAAAA;'>Contacts</div>";
            for (var i = 0; i < contactArray.length; i++) {
                html += '<div phone="' + contactArray[i].Phone + '"><span>' + contactArray[i].Name + '</span><img src="/Img/check.png" /></div>';
            }
            $("#contactResults").html(html);

            if (fbAccessToken && !$("#inviteResults").html()) {
                var sucess = function (friendList) {
                    PopulateAddressBook(friendList);
                    OpenAddressBook();
                }
                Post("GetFriends", { facebookAccessToken: fbAccessToken }, sucess);
            }
            else
                OpenAddressBook();
        }

        function FilterFriends() {
            var filter = $("#filterFriendsTextbox").val();
            $("#inviteResults div").not(":eq(0)").each(function () {
                if (!filter || Contains($(this).html().toLowerCase(), filter.toLowerCase()))
                    $(this).show();
                else
                    $(this).hide();
            });

            $("#contactResults div").not(":eq(0)").each(function () {
                if (!filter || Contains($(this).html().toLowerCase(), filter.toLowerCase()))
                    $(this).show();
                else
                    $(this).hide();
            });
        }

        function AddInvitesToCreate() {
            
            //if (isiOS)
            //{
            //    var html = "";
            //    for (var i = 0; i < friendList.length; i++)
            //    {
            //        var friend = friendList[i];
            //        if(friend.facebookId) //Facebook user
            //            html += "<div facebookId='" + friend.facebookId + "' ><img src='https://graph.facebook.com/" + friend.facebookId + "/picture' /><div>" + friend.name + "</div></div>";
            //        else
            //            html += "<div phone='" + friend.phone + "' ><img src='/Img/face" + Math.floor(Math.random() * 8) + ".png' /><div>" + friend.name + "</div></div>";
            //    }
            //    $("#addDiv .invitedFriendsScroll").css("width", ((friendList.length * 70) + 25) + "px");
            //    $("#addDiv .invitedFriendsScroll").html(html);
            //}
            //else
            //{
                var html = "";
                $("#inviteResults div.invited").each(function () {
                    var fbId = $(this).attr("facebookId");
                    var name = $(this).find("span").html();
                    if (Contains(name, " "))
                        name = name.substring(0, name.indexOf(" "));
                    html += "<div facebookId='" + fbId + "' ><img src='https://graph.facebook.com/" + fbId + "/picture' /><div>" + name + "</div></div>";
                });

                $("#contactResults div.invited").each(function () {
                    var phone = $(this).attr("phone");
                    var name = $(this).find("span").html();
                    if (Contains(name, " "))
                        name = name.substring(0, name.indexOf(" "));
                    html += "<div phone='" + phone + "' ><img src='/Img/face" + Math.floor(Math.random() * 8) + ".png' /><div>" + name + "</div></div>";
                });

                var width = $("#inviteResults div.invited").length * 70 + $("#contactResults div.invited") * 60 + 25;
                $("#addDiv .invitedFriendsScroll").css("width", width + "px");
                $("#addDiv .invitedFriendsScroll").html(html);
                CloseToBottom("inviteDiv");
            //}
        }
        
        function SendInvitesFromAddressBook()
        {
            var event = jQuery.extend({}, currentEvent);
            event.FacebookId = "";
            $("#inviteResults div.invited").each(function () {
                var fbId = $(this).attr("facebookId");
                var name = $(this).find("span").html();
                if (Contains(name, " "))
                    name = name.substring(0, name.indexOf(" "));
                event.FacebookId = AddToString(event.FacebookId, fbId + ":" + name);
            });

            $("#contactResults div.invited").each(function () {
                var phone = $(this).attr("phone");
                var name = $(this).find("span").html();
                if (Contains(name, " "))
                    name = name.substring(0, name.indexOf(" "));
                event.FacebookId = AddToString(event.FacebookId, "p" + phone + ":" + name);
            });

            $(event.FacebookId.split("|")).each(function () {
                currentEvent.Invited = AddToString(currentEvent.Invited, this);
            });
            
            Post("SaveEvent", { evt: currentEvent }, UpdateDetailsGoing);

            event.Invited = event.FacebookId;
            SendInvites(event);
            CloseToBottom("inviteDiv");
        }

        function SendInvites(event) {
            event.FacebookId = event.Invited.replace(currentUser.FacebookId, "");
            event.NotificationMessage = currentUser.FirstName + " invited you to " + event.Name;

            Post("SendInvites", { evt: event });

            var phoneList = "";
            $(event.Invited.split("|")).each(function () {
                var info = this.split(":");
                if (info.length == 2 && info[0].indexOf("p") == 0) {
                    phoneList += info[0].substring(1) + ",";
                }
            });

            if (phoneList) {
                phoneList = phoneList.substring(0, phoneList.length - 1);
                var message = "Your invited to " + event.Name + ". Download the Pow Wow app to reply: {Branch}";
                GetBranchLink(event, phoneList, message);
            }
                
        }

        function SendText(phoneList, message) {

            if (isiOS)
            {
                var params = "?phone=" + phoneList + "&message=" + message;
                window.location = "ios:SendSMS" + params;
            }
            else if(isAndroid)
            {
                if (typeof androidAppProxy !== "undefined") {
                    androidAppProxy.sendSMS(phoneList, message);
                } else {
                    console.log("Running outside Android app");
                }
            }
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
                if (Contains(message.FacebookId, currentUser.FacebookId)) {
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
            
            var message = { EventId: currentEvent.Id, Name: currentUser.FirstName, Message: text, FacebookId: currentUser.FacebookId };
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
            Post("GetNotifications", { facebookId: $("#FacebookId").val() }, PopulateNotifications);
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

    <!-- Integrate with iOS / Android -->
     <script type="text/javascript">
         function iOSInit()
         {
             //var token = getParameterByName("fbAccessToken");
             //if (token)
             //    fbAccessToken = token;

             currentUser = {};
             if (getParameterByName("facebookId") && getParameterByName("facebookId") != "(null)")
                 currentUser.FacebookId = getParameterByName("facebookId");
             if (getParameterByName("firstName") && getParameterByName("firstName") != "(null)")
                 currentUser.FirstName = getParameterByName("firstName");

             $("#FacebookId").val(currentUser.FacebookId);

             currentLat = getParameterByName("lat");
             currentLng = getParameterByName("lng");

             if (getParameterByName("createEvent"))
             {
                 var event = JSON.parse(getParameterByName("createEvent"));
                 OpenCreate(event);

                 $("#addDiv").show();
                 $("#addDiv").css({ top: "0" });
                 HideLoading();
             }
             else if(getParameterByName("goToEvent"))
             {
                 var referenceId = getParameterByName("goToEvent");
                 if (getParameterByName("toMessaging")) {
                     var messageSuccess = function (event) {
                         currentEvent = event;
                         $("#messageDiv").show();
                         $("#messageDiv").css({ left: "0" });
                         OpenMessages();
                         OpenDetails(event);
                     };
                     Post("GetEventByReference", { referenceId: referenceId }, messageSuccess);
                 }
                 else
                 {
                     Post("GetEventByReference", { referenceId: referenceId }, OpenDetails);
                     $("#detailsDiv").show();
                     $("#detailsDiv").css({ top: "0" });
                 }
                 HideLoading();
             }
             else if (getParameterByName("joinEvent")) {
                 var referenceId = getParameterByName("joinEvent");
                 var getSuccess = function (evt) {
                     currentEvent = evt;
                     JoinEvent();
                     HideLoading();
                 };
                 Post("GetEventByReference", { referenceId: referenceId }, getSuccess)
             }
             else if(currentLat && currentLng)
             {
                 LoadEvents();
             }
         }

         function AndroidInit()
         {
             currentUser = {};
             if (getParameterByName("facebookId") && getParameterByName("facebookId") != "(null)")
                 currentUser.FacebookId = getParameterByName("facebookId");
             if (getParameterByName("firstName") && getParameterByName("firstName") != "(null)")
                 currentUser.FirstName = getParameterByName("firstName");

            var lat = getParameterByName("lat");
            var lng = getParameterByName("lng");
            if (lat && lng) {
                currentLat = lat;
                currentLng = lng;
                //if (!getParameterByName("fbAccessToken"))
                LoadEvents();
            }
         }

         function GetReturnUrlParameters()
         {
             return "?OS=" + getParameterByName("OS") + "&facebookId=" + currentUser.FacebookId + "&firstName=" + currentUser.FirstName + "&lat=" + currentLat + "&lng=" + currentLng;
         }

     </script>

    <!-- Facebook -->
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

            fbAccessToken = getParameterByName("fbAccessToken");
            var deviceId = getParameterByName("deviceId");
            var pushDeviceToken = getParameterByName("pushDeviceToken");
            if (fbAccessToken) {
                Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);
            }
            else
            {
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

                        Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);

                    } else {
                        Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);
                        //if (!fbAccessToken)
                        //    window.location = "../";
                        //else
                        //    Post("LoginUser", { facebookAccessToken: fbAccessToken }, LoginSuccess);
                    }
                });
            }
        };

        function LoginSuccess(results) {
            currentUser = results;
            $("#FacebookId").val(currentUser.FacebookId);
            //LoadEvents();
            /*TODO: fix
            if (document.URL.indexOf("?") > 0) {
                var referenceId = document.URL.substr(document.URL.indexOf("?") + 1);
                Post("GetReferredNotification", { referenceId: referenceId, facebookId: currentUser.FacebookId }, OpenReferredNotification);
            }
            */
        }

        function OpenFacebookLogin()
        {
            OpenFromBottom("facebookLoginDiv");
        }

        function FacebookLogin() {
            if (isiOS) {
                window.location = "ios:FacebookLogin";
            }
            else if(isAndroid)
            {
                if (typeof androidAppProxy !== "undefined")
                    androidAppProxy.AndroidFacebookLogin();
            }
            else
            {
                FB.login(function (response) {
                    if (response.authResponse) {
                        var uid = response.authResponse.userID;
                        $("#FacebookId").val(uid);
                        fbAccessToken = response.authResponse.accessToken;
                        var deviceId = getParameterByName("deviceId");
                        var pushDeviceToken = getParameterByName("pushDeviceToken");

                        Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken }, LoginSuccess);
                        CloseToBottom('facebookLoginDiv');
                    } else {
                        console.log('User cancelled login or did not fully authorize.');
                    }
                });
            }
        }

        function FacebookLogout() {
            FB.logout(function (response) {
                // user is now logged out
            });
        }

        // Load the SDK Asynchronously
        (function (d) {
            var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
            if (d.getElementById(id)) { return; }
            js = d.createElement('script'); js.id = id; js.async = true;
            js.src = "//connect.facebook.net/en_US/all.js";
            ref.parentNode.insertBefore(js, ref);
        }(document));
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
            <%--<div class="event">
                <img class="going" src="https://graph.facebook.com/10106153174286280/picture" />
                <div style="float:left;"><span style="color:#4285F4;;">Test</span><div style="height:4px;"></div>2 miles away</div>
                <div style="float:right;">11:37 PM<div style="height:4px;"></div>1 of 3</div>
            </div>--%>
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
        <div id="facebookLoginDiv">
            <a onclick="CloseToBottom('facebookLoginDiv');" style="position: absolute; left:5%;top:30px;color:#4285F4;">Cancel</a>
            <div class="loginHeader" style="margin:60px 20px 0;text-align: center;font-size: 20px;line-height: 28px;">Log In to Discover Activities Near You Today</div>
            <img src="../Img/appScreenshot.png" style="margin: 12px auto;height: 55%;display:block;" />
            <div style="text-align: center;position: absolute;width: 100%;top: 100%;margin-top: -80px;">
                <div onclick="FacebookLogin();" style="display:block;margin:0 auto;width: 80%;background-color:#3B5998;color:white;padding: 10px 0;border-radius: 5px;">Log In with Facebook</div>
                <div style="margin-top: 6px;font-size: 14px;">We don't post anything to Facebook</div>
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

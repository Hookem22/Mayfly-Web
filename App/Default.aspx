<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="App_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
   <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <link href="/Styles/App.css?i=7" rel="stylesheet" type="text/css" />
    <link href="/Styles/NonMobileApp.css?i=2" rel="stylesheet" type="text/css" />
    <link href="/Styles/Animation.css?i=3" rel="stylesheet" type="text/css" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/jquery.touchSwipe.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
<%--    <script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>--%>
    <script type="text/javascript">
        var isMobile;
        var isiOS;
        var isAndroid;
        var currentLat;
        var currentLng;
        var currentSchool;
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
                    if ($(".content").scrollTop() <= 0) {
                        ShowLoading();
                        LoadEvents();
                        if(currentEvent && currentEvent.Id)
                            LoadMessages();
                    }
                    else if ($(".content").scrollTop() < 90) {
                        $(".content").animate({ scrollTop: "90" }, 350);
                    }
                }, 100);
            });

            $(".content").swipe({
                swipeLeft: function (event, direction, distance, duration, fingerCount) {
                    if ($("#menuDiv").is(':visible'))
                        CloseMenu();
                    //else
                    //    OpenGroups();
                },
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    OpenMenu();
                }
            });

            $("#groupsDiv").swipe({
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    MenuClick();
                }
            });

            $(".content, #groupEvents").on("click", ".event", function (e) {
                //if ($(e.target).hasClass("group"))
                //    return;

                if (!currentUser || !currentUser.Id) {
                    OpenLogin();
                    return;
                }

                if ($(this).find(".groupList").hasClass("private"))
                {
                    var isPrivate = true;
                    var groupId = $(this).find(".group").attr("groupid");
                    $("#myGroupsDiv > div").each(function () {
                        if ($(this).attr("groupid") == groupId)
                            isPrivate = false;
                    });

                    if (isPrivate) {
                        MessageBox("This event is private. Please join the group to attend this event.");
                        return;
                    }
                }
                
                var eventId = $(this).attr("eventid");
                var name = $(this).find(".name").html();
                OpenEvent(eventId, name);
            });

            //Remove for now
            //$(".content").on("click", ".group", function () {
            //    if (!currentUser || !currentUser.Id) {
            //        OpenLogin();
            //        return;
            //    }

            //    var groupId = $(this).attr("groupid");
            //    var name = $(this).html().substring(1);
            //    var isPrivate = $(this).hasClass("private");
            //    GetGroup(groupId, name, isPrivate);
            //});

            $(".screenHeader .backArrow").click(function () {
                if ($(this).closest(".screen").attr('id') == "groupDetailsDiv")
                    currentGroup = {};
                else if ($(this).closest(".screen").attr('id') == "detailsDiv")
                    currentEvent = {};
                
                CloseRight($(this).closest(".screen"));
            });

            $("#addDiv .backArrow").click(function () {
                //LoadEvents();
            });

            $("#detailsDiv .backArrow").click(function () {
                if (currentEvent.IsDirty)
                    LoadEvents();
            });

            $(".screen.swipe").swipe({
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    if ($(this).closest(".screen").attr('id') == "groupDetailsDiv")
                        currentGroup = {};
                    
                    CloseRight(this);
                }
            });

            $("#addDiv .screenHeader").swipe({
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    //LoadEvents();
                    CloseRight($("#addDiv"));
                }
            });

            //$("#detailsDiv .invitedFriends").swipe({
            //    swipeLeft: function (event, direction, distance, duration, fingerCount) {
            //        event.stopImmediatePropagation();
            //    },
            //    swipeRight: function (event, direction, distance, duration, fingerCount) {
            //        event.stopImmediatePropagation();
            //    }
            //});

            $("#detailsDiv .screenSubheader, #detailsDescription, #detailsInviteBtn, #detailsAddMessage, #MessageResults, #detailsDiv .separator")
                .swipe({
                //swipeLeft: function (event, direction, distance, duration, fingerCount) {
                //    OpenMessages();
                //},
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    CloseRight($(this).closest(".screen"));
                    if (currentEvent.IsDirty)
                        LoadEvents();

                    currentEvent = {};
                }
            });
        });

        function Init()
        {
            if ($(window).height() > 600)
                $("#contentResults").css("min-height", ($(window).height() - 220) + "px");
            else if ($(window).height() > 550)
                $("#contentResults").css("min-height", ($(window).height() - 160) + "px");
            
            isiOS = getParameterByName("OS") == "iOS";
            isAndroid = getParameterByName("OS") == "Android";

            var mobParam = getParameterByName("id");
            isMobile = mobilecheck() || tabletCheck() || mobParam == "m";

            if (isiOS || isAndroid || isMobile) {

                currentUser = {};
                var pushDeviceToken = getParameterByName("pushDeviceToken");
                currentLat = +getParameterByName("lat") || 30.25;
                currentLng = +getParameterByName("lng") || -97.75;

                Post("InitEvents", { pushDeviceToken: pushDeviceToken, latitude: currentLat, longitude: currentLng }, InitSuccess);

                if(currentLat && currentLng) //Default to St. Edwards
                    GetSchool();
                else
                    currentSchool = { Id: "E1668987-C219-484C-B5BB-1ACACDCADE17", Name: "St. Edward's", Latitude: 30.231, Longitude: -97.758 }; //St Edward's

                $(".content").scrollTop(90);
            }

            fbAccessToken = getParameterByName("fbAccessToken");
            var deviceId = getParameterByName("deviceId");
            var pushDeviceToken = getParameterByName("pushDeviceToken");
            Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken, email:"", isiOS:isiOS }, LoginSuccess);

            if (!isMobile) {
                $("body").addClass("NonMobile");
            }
            if (isiOS) {
                $("body").addClass("ios");
            }
            var eventId = getParameterByName("eventId");
            if(eventId)
                OpenEvent(eventId);
        }

        function InitSuccess(results) {
            if(results)
                PopulateEvents(results);
        }

        function LoginSuccess(results) {
            currentUser = results;

            if (!currentLat && !currentLng && currentUser && currentUser.Latitude && currentUser.Longitude) {
                currentLat = currentUser.Latitude;
                currentLng = currentUser.Longitude;
            }

            if(currentUser && currentUser.NewUser) {
                ShowNewUserScreen();
            }

            if(currentUser) {
                currentUser.Latitude = currentLat;
                currentUser.Longitude = currentLng;
                GetSchool();
            }

            if (currentUser) {
                LoadMyGroups();
            }
            
            $(".facebookPic").attr("src", "https://graph.facebook.com/" + currentUser.FacebookId + "/picture");
            $(".facebookName").html(currentUser.FirstName);
            GetLitPoints();
        }

        function GetSchool() {
            var success = function(results) {
                currentSchool = results;
                if(currentUser && currentSchool)
                    currentUser.SchoolId = currentSchool.Id;
                if(currentSchool){
                    $("#groupsDiv .menuHeader").html(currentSchool.Name.toUpperCase() + " INTERESTS");
                    $("#loginHeader").html("Log in to find and join events at " + currentSchool.Name + ".");
                }
                LoadEvents();
            };
            var user = currentUser && currentUser.Id ? currentUser : { Latitude: currentLat, Longitude: currentLng };
            Post("GetSchool", { user: user }, success);
        }

        function ReceiveLocation(lat, lng)
        {
            if (!(currentLat && currentLng && Math.abs(currentLat - (+lat)) < 0.2 && Math.abs(currentLng - (+lng)) < 0.2))
            {
                currentLat = +lat;
                currentLng = +lng;
                if(currentUser) {
                    currentUser.Latitude = currentLat;
                    currentUser.Longitude = currentLng;
                }
                GetSchool();
            }

            if(currentUser && currentUser.Id)
            {
                currentUser.Latitude = currentLat;
                currentUser.Longitude = currentLng;
                Post("SaveUser", { user: currentUser });
            }

            //$(".content").html(window.location.href);
        }

        function GoToEvent(referenceId)
        {
            Post("GetEventByReference", { referenceId: referenceId }, OpenEventDetails);
            $("#detailsDiv").show();
            $("#detailsDiv").css({ top: "0" });
        }

        function LatLngReturn(position)
        {
            currentLat = position.coords.latitude;
            currentLng = position.coords.longitude;
            MessageBox(currentLat + "," + currentLng);
            LoadEvents();
        }

        function LoadEvents()
        {
            var user = currentUser && currentUser.Id ? currentUser : { SchoolId: currentSchool.Id, Latitude: currentLat, Longitude: currentLng };
            Post("GetEvents", { user: user, latitude: currentLat, longitude: currentLng }, PopulateEvents);
        }

        function PopulateEvents(results)
        {
            var html = SetLocalTimes(results);
            $(".content #contentResults").html(html);
            var today = new Date().getDay();
            $(".content #contentResults .dayHeader").each(function () {
                var day = $(this).attr("dayofweek");
                if (day == today)
                    $(this).find("div:last-child").html("Today");
                else if(day - today == 1)
                    $(this).find("div:last-child").html("Tomorrow");
            });

            if ($(".content").scrollTop() < 20)
                $(".content").scrollTop(20);

            $(".content").animate({ scrollTop: "90" }, 350);

            if($(".loading").is(':visible'))
                HideLoading();

            LoadGroups();
        }

        function GetLitPoints() {
            var success = function (points) {
                $(".litPoints").html(points);
            }

            Post("GetLitPoints", { user: currentUser }, success);
        }

        function SetLocalTimes(html)
        {
            while(html.indexOf("{{") >= 0)
            {
                var beginIdx = html.indexOf("{{");
                var endIdx = html.indexOf("}}");
                var time = html.substring(beginIdx + 2, endIdx);
                var localTime = ToLocalTime(time);
                html = html.substring(0, beginIdx) + localTime + html.substring(endIdx + 2);
            }
            while (html.indexOf("[[") >= 0) {
                var beginIdx = html.indexOf("[[");
                var endIdx = html.indexOf("]]");
                var time = html.substring(beginIdx + 2, endIdx);
                var localTime = ToLocalDay(time, true);
                html = html.substring(0, beginIdx) + localTime + html.substring(endIdx + 2);
            }
            return html;
        }
    </script>

    <!-- Add / Edit Event -->
    <script type="text/javascript">
        var eventIcons = ["Sunny", "Lightning", "Sunglasses", "Castle", "Firework", "Spaceship", "Hammock", "Tent", "Flipflops", "Pool", "Jetski", "Canoe", "Cloudy", "Snow", "Storm", "WindmillPaper", "OldCar", "Motorbike", "Segway", "Hat", "Boots", "Books", "Science", "MovieEvent", "MovieSlate", "Television", "Ticket", "Money", "VideoCamera", "Microphone", "Guitar", "Cassette", "Dj", "RecordPlayer", "Speaker", "Trumpet", "Astronaut", "CaptainShield", "Darth-Vader", "Minion", "Pacman", "PacmanGhost", "WallE", "PirateFlag", "Xbox", "Joystick", "Cards", "Chessboard", "PingPong", "Bowling", "Snooker", "Telescope", "MagicBunny", "Crown", "Flag", "Podium", "PrizeCup", "Football", "Helmet", "Backboard", "Baseball", "Soccer", "SoccerField", "Tennis", "Karate", "Dumbbell", "Rollerblade", "Bottle", "Beer", "Beermug", "Champagne", "Cocktail", "Whiskey", "Wine", "Coffee", "Watermelon", "TableSet", "Sushi", "Pizza", "Noodles", "FrenchFries", "ChickenWing", "Grill", "BirthdayCake", "Candycane", "Cupcake", "Icecream"];

        $(document).ready(function () {
            PopulateEventIcons();

            $("#AddName, #AddDetails, #AddGroupDivName, #AddGroupDescription, #AddGroupPassword").focus(function () {
                if (isAndroid && $(this).attr("readonly") != "readonly")
                    $(".screen .screenBottom, .separator, #inviteBtn, .invitedFriends").hide();
            });

            $("#AddName, #AddDetails, #AddGroupDivName, #AddGroupDescription, #AddGroupPassword").blur(function () {
                if (isAndroid)
                    $(".screen .screenBottom, .separator, #inviteBtn, .invitedFriends").show();
            });

            $("#addBtn").click(function () {
                OpenAdd();
            });

            $("#addDiv .bottomBtn").click(function () {
                SaveEvent();
            });

            $("#deleteEventBtn").click(function () {
                ActionMessageBox("This will delete this event. Continue?", DeleteEvent);
            });

            $("#AddGroupName").click(function () {
                $(".modal-backdrop").show();
                $("#addGroupDiv").show();
            });

            $("#addGroupsResultsDiv").on("click", "div", function () {
                var groupId = $(this).attr("groupid");
                if (!groupId)
                    return;

                var name = $(this).find("div").html();
                $("#AddGroupName").val(name);
                currentGroup.Id = groupId;
                currentGroup.Name = name;
                CloseAddGroup();

            });

            $("#addGroupDiv .smallBottomBtn").click(function () {
                CloseAddGroup();
            });

            $("#addFromGroupBtn").click(function () {
                var group = currentGroup;
                OpenAdd();
                $("#inviteGroups div").each(function () {
                    var groupId = $(this).attr("groupid");
                    if (groupId && groupId == group.Id) {
                        $(this).addClass("invited");

                        var src = $(this).find(".logo").attr("src");
                        var name = $(this).find("div").html();
                        if (name.length > 7)
                            name = name.substring(0, 6) + "...";
                        var html = "<div groupId='" + groupId + "' ><img src='" + src + "' /><div>" + name + "</div></div>";
                        $("#addDiv .invitedFriendsScroll").html(html);
                    }
                });
            });

            $("#AddEventIcons").on("click", "img", function () {
                $("#AddEventIcons img").removeClass("selected");
                $(this).addClass("selected");
            });
        });

        function PopulateEventIcons() {
            var html1 = "";
            var html2 = "";
            var html3 = "";
            for (var i = 0; i < eventIcons.length; i++) {
                var icon = eventIcons[i];
                if(i % 3 == 0)
                    html1 += "<img src='/Img/Event Icons/" + icon + ".png' />";
                else if (i % 3 == 1)
                    html2 += "<img src='/Img/Event Icons/" + icon + ".png' />";
                else if (i % 3 == 2)
                    html3 += "<img src='/Img/Event Icons/" + icon + ".png' />";
            }

            var html = "<div><div>" + html1 + "</div><div>" + html2 + "</div><div>" + html3 + "</div></div>";
            $("#AddEventIcons").html(html);

            var ht = $(window).height() - 251 - 201;
            var imgHt = (ht - 40) / 3;
            $("#AddEventIcons img").css("height", imgHt);
            $("#AddEventIcons > div").css("width", (eventIcons.length / 3) * (imgHt + 10) + 20 + "px");

        }

        function SelectIcon(iconName) {
            $("#AddEventIcons img").removeClass("selected");

            $("#AddEventIcons img").each(function () {
                if ($(this).attr("src").indexOf(iconName) >= 0) {
                    $(this).addClass("selected");

                    $(eventIcons).each(function (i) {
                        if (this == iconName) {
                            var ht = $(window).height() - 251 - 201;
                            var imgHt = (ht - 40) / 3;
                            var col = Math.floor(i / 3);
                            $("#AddEventIcons").scrollLeft(col * (imgHt + 10));
                        }
                    });

                }
            });
        }

        function OpenAdd(isEdit) {
            if (!currentUser || !currentUser.Id || !fbAccessToken) {
                OpenLogin();
                return;
            }

            $("#addDiv").show();
            $("#addDiv input").removeClass("error");
            $("#inviteGroups div").removeClass("invited");
            if (!isEdit) {
                $("#addDiv .screenTitle").html("Create Event");
                $("#addDiv .bottomBtn").html("Create");
                $("#addDiv .bottomBtn").html("Create");
                $("#addDiv input, #addDiv textarea").val("");
                $("#addDiv #AddDay").val("Today");
                InitDay();
                SelectIcon("Sunny");
                $("#addDiv #inviteBtn").show();
                $("#addDiv .invitedFriendsScroll").html("");
                $("#AddMap").css("height", "165px").hide();
                $("#addDiv .invitedFriends").show();
                $("#deleteEventBtn").hide();
                currentLocation = { Name: currentSchool.Name, Address: "", Latitude: currentSchool.Latitude, Longitude: currentSchool.Longitude };

                currentEvent = {};
                currentGroup = {};
            }
            else {
                $("#addDiv .screenTitle").html("Edit Event");
                $("#addDiv .bottomBtn").html("Save");
                $("#AddName").val(currentEvent.Name);
                $("#addDiv .bottomBtn").html("Save");
                $("#AddDetails").val(currentEvent.Description);
                $("#AddLocation").val(currentEvent.LocationName);
                currentLocation = { Name: currentEvent.LocationName, Address: currentEvent.LocationAddress, Latitude: currentEvent.LocationLatitude, Longitude: currentEvent.LocationLongitude };
                $("#addDiv #AddDay").val(GetDayLabel(currentEvent.StartTime));
                $("#AddStartTime").val(currentEvent.LocalTime);
                InitDay();
                var min = currentEvent.MinParticipants > 1 ? currentEvent.MinParticipants : "";
                $("#AddMin").val(min);
                var max = currentEvent.MaxParticipants ? currentEvent.MaxParticipants : "";
                $("#AddMax").val(max);
                currentGroup = { Id: currentEvent.GroupId };
                $("#addGroupsResultsDiv div").each(function () {
                    if($(this).attr("groupid") == currentEvent.GroupId)
                        $("#AddGroupName").val($(this).find("div").html());
                });
                SelectIcon(currentEvent.GroupPictureUrl);
                
                $("#addDiv #inviteBtn").hide();
                $("#addDiv .invitedFriendsScroll").html("");
                //$("#AddMap").css("height", "135px");
                //PlotMap("AddMap", currentEvent.LocationName, currentEvent.LocationLatitude, currentEvent.LocationLongitude);
                $("#deleteEventBtn").show();
            }

            $("#inviteDiv div").removeClass("invited");
        }

        function SaveEvent() {

            $("#addDiv input, #addDiv textarea").removeClass("error");
            var error = false;
            if (!$("#AddName").val()) {
                $("#AddName").addClass("error");
                error = true;
            }
            //if (!$("#AddLocation").val()) {
            //    $("#AddLocation").addClass("error");
            //    error = true;
            //}
            if (!$("#AddStartTime").val()) {
                $("#AddStartTime").addClass("error");
                error = true;
            }
            if (error)
                return;


            var event = GetCreateEvent();

            if (new Date() > event.StartTime) {
                $("#AddStartTime").addClass("error");
                return;
            }

            var success = (function (event) {
                LoadEvents();
                $("#addDiv").hide();
                SendInvites(event);

                if (currentEvent.Id) {
                    currentEvent = event;
                    OpenEventDetails(currentEvent);
                }
                //else if (event.GroupId) {
                //    GetGroup(event.GroupId);

                //    var alert = "New event posted to your group " + currentGroup.Name + ".";
                //    var messageText = "";
                //    Post("SendMessageToGroup", { groupId: event.GroupId, alert: alert, messageText: messageText, userId: currentUser.Id });

                //    var message = "New: " + event.Name;
                //    Post("SaveNotificationToGroup", { groupId: event.GroupId, message: message, userId: currentUser.Id, eventId: event.Id });
                //}
            });
            Post("SaveEvent", { evt: event }, success);

            $("#addDiv").hide();
        }

        function GetCreateEvent() {
            var startTime = "";
            var dayOfWeek;
            var localTime = "";
            if ($("#AddStartTime").val()) {
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

                var i = 0;
                $("#dateDivResults div").each(function () {
                    if ($(this).hasClass("selected")) {
                        startTime.setDate(startTime.getDate() + i);
                    }
                    i++;
                });

                dayOfWeek = startTime.getDay();
                localTime = $("#AddStartTime").val();
            }

            var max = +$("#AddMax").val() || 0;
            var min = +$("#AddMin").val() || 0;

            var groupId = currentEvent && currentEvent.GroupId ? currentEvent.GroupId : "";
            var groupName = currentEvent && currentEvent.GroupName ? currentEvent.GroupName : "";
            var img = $("#AddEventIcons img.selected").attr("src");
            img = img.substring(img.lastIndexOf("/") + 1);
            img = img.substring(0, img.indexOf("."));
            var groupPictureUrl = img;
            var allPrivate = true;
            $("#inviteGroups div.invited").each(function () {
                var gId = $(this).attr("groupid");
                if (gId) {
                    groupId += groupId ? "|" + gId : gId;
                    var gName = $(this).find("div").html();
                    groupName += groupName ? "|" + gName : gName;
                    //if (!groupPictureUrl) {
                    //    var gPic = $(this).find("img.logo").attr("src");
                    //    if (gPic.indexOf("group.png") < 0)
                    //        groupPictureUrl = gPic;
                    //}
                    var isPrivate = false;
                    $("#myGroupsDiv > div.private").each(function () {
                        if ($(this).attr("groupid") == gId)
                            isPrivate = true;
                    });
                    allPrivate = allPrivate && isPrivate;
                }
            });

            var groupIsPublic = !allPrivate || !groupId || (currentEvent && currentEvent.GroupIsPublic == true);

            var event = {
                Name: $("#AddName").val(), Description: $("#AddDetails").val(), GroupId: groupId, GroupName: groupName, GroupPictureUrl: groupPictureUrl,
                GroupIsPublic: groupIsPublic, LocationName: currentLocation.Name, LocationAddress: currentLocation.Address, LocationLatitude: currentLocation.Latitude,
                LocationLongitude: currentLocation.Longitude, SchoolId: currentSchool.Id, MinParticipants: min, MaxParticipants: max, StartTime: startTime,
                DayOfWeek: dayOfWeek, LocalTime: localTime, NotificationMessage: "Created " + $("#AddName").val(), UserId: currentUser.Id
            };

            if (currentEvent.Id) {
                event.Id = currentEvent.Id;
                event.NotificationMessage = "";
                event.UserId = "";
                event.Going = currentEvent.Going;
            }

            return event;
        }

        function CloseAddGroup() {
            $("#addGroupDiv").fadeOut();
            $(".modal-backdrop").fadeOut();
        }

        function DeleteEvent() {
            var success = function () {
                $("#addDiv").hide();
                $("#detailsDiv").hide();
                LoadEvents();
            }
            Post("DeleteEvent", { evt: currentEvent }, success);
        }

    </script>

    <!-- Details -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#detailsDiv .detailMenuBtn").click(function () {
                setTimeout(function () { $("#detailsEditBtn").show() }, 50);
            });

            $("#detailsDiv").click(function () {
                $("#detailsEditBtn").hide();
            });

            $("#detailsDiv .detailMenuBtn").click(function () {
                $("#detailsEditBtn").show();
            });

            $("#detailsEditBtn").click(function () {
                OpenAdd(true);
            });

            $("#joinBtn").click(function () {
                if (!IsGoing(currentEvent.Going, currentUser.Id))
                    JoinEvent();
                else
                    ActionMessageBox("Unjoin " + currentEvent.Name + "?", UnjoinEvent, null, "Yes", "No");
            });
        });

        function OpenEvent(eventId, eventName) {
            if ((!currentUser || !currentUser.Id || !fbAccessToken) && !getParameterByName("eventId")) {
                OpenLogin();
                return;
            }

            eventName = eventName || "";
            Post("GetEvent", { id: eventId }, OpenEventDetails);
            $("#detailsDiv .screenTitle").html(eventName);
            $("#detailsDiv .screenSubheader").hide();
            $("#detailsDiv .screenContent").hide();
            $("#detailsDiv .detailMenuBtn").hide();
            $("#inviteGroups div").removeClass("invited");
            $("#detailsDiv").show();
        }

        function OpenEventDetails(event) {
            if ((!currentUser || !currentUser.Id || !fbAccessToken) && !getParameterByName("eventId")) {
                OpenLogin();
                return;
            }

            currentEvent = event;
            //if (event.GroupId) {
            //    $("#detailsDiv").removeClass("nonGroup");
            //    $("#detailsLogo").show().attr("src", event.GroupPictureUrl);

            //    //$("#detailsDiv").removeClass("nonGroup");
            //    //if (!currentGroup || !currentGroup.Id || event.GroupId.indexOf(currentGroup.Id) < 0) {
            //    //    var success = function (results) {
            //    //        currentGroup = results;
            //    //        $("#detailsLogo").show().attr("src", currentGroup.PictureUrl);
            //    //        if (currentGroup.IsPublic || IsGoing(currentGroup.Members, currentUser.Id))
            //    //            OpenEventDetails(currentEvent);
            //    //        else if (!currentGroup.IsPublic)
            //    //            MessageBox("This event is private. Please join the group to attend this event.");
            //    //    };
            //    //    Post("GetGroup", { groupId: event.GroupId, latitude: currentLat, longitude: currentLng, user: currentUser }, success);
            //    //    return;
            //    //}
            //}
            //else {
            $("#detailsDiv").addClass("nonGroup");
            $("#detailsLogo").hide();
            //}

            $("#detailsDiv").show();
            $("#detailsDiv .screenSubheader").show();
            $("#detailsDiv .screenContent").show();
            $("#detailsDiv .screenTitle").html(event.Name);
            var subheaderHtml = ToLocalDay(event.StartTime) + " - " + ToLocalTime(event.StartTime);
            //if(currentGroup && currentGroup.Name)
            //    subheaderHtml += " - " + currentGroup.Name;
            $("#detailsDiv #detailsInfo").html(subheaderHtml);

            var descHtml = event.Description;
            if (descHtml.length > 200) {
                descHtml = descHtml.substring(0, 200) + " ... ";
                descHtml += "<a class='readMore'>Read More</a>";
            }

            $("#detailsDescription").html(descHtml);

            UpdateDetailsGoing(event);

            $("#detailsMap").hide();
            //setTimeout(function () {
            //    var mapHt = $(window).height() - $("#detailsMap").offset().top - 20;
            //    if (mapHt < 165)
            //        mapHt = 165;
            //    $("#detailsMap").css("height", mapHt + "px");
            //    PlotMap("detailsMap", event.LocationName, event.LocationLatitude, event.LocationLongitude);
            //}, 400);

            if (IsGoing(event.Going, currentUser.Id)) {
                $("#joinBtn").html("GOING");
                $("#joinBtn").addClass("selected");
            }
            else {
                $("#joinBtn").html("+ JOIN EVENT");
                $("#joinBtn").removeClass("selected");
            }
            
            if (IsAdmin(event.Going, currentUser.Id) || (currentGroup && currentGroup.Members && IsAdmin(currentGroup.Members, currentUser.Id)))
                $("#detailsDiv .detailMenuBtn").show();
            else
                $("#detailsDiv .detailMenuBtn").hide();

            var messageSuccess = function (messageCk) {
                if(messageCk)
                    $(".messageBtn").attr("src", "/Img/newmessage.png");
            }
            $("#inviteDiv div").removeClass("invited");
            //$(".messageBtn").attr("src", "/Img/message.png");
            //Post("CheckNewMessages", { eventId: currentEvent.Id, userId: currentUser.Id }, messageSuccess);
            LoadMessages();
        }

        function UpdateDetailsGoing(event) {

            var howMany = "Going: " + event.Going.length + " | Invited: " + event.Invited.length;
            //if (HowManyGoing(event))
            //    howMany += " (" + HowManyGoing(event) + ")";
            $("#detailsHowMany").html(howMany);

            var goingHtml = "";
            var people = 0;
            for (var i = 0; i < event.Going.length; i++) {
                var user = event.Going[i];
                if(user.FacebookId) {
                    var src = "https://graph.facebook.com/" + user.FacebookId + "/picture";
                    goingHtml += "<div><img src='" + src + "' /><div class='goingIcon icon'><img src='/Img/greenCheck.png' /></div><div>" + user.FirstName + "</div></div>";
                }
                else {
                    var src = "/Img/face" + Math.floor(Math.random() * 8) + ".png";
                    goingHtml += "<div class='nonFb'><img src='" + src + "' /><div class='goingIcon icon'><img src='/Img/greenCheck.png' /></div><div>" + user.FirstName + "</div></div>";
                }
                people++;
            }
            for (var i = 0; i < event.Invited.length; i++) {
                var user = event.Invited[i];
                var isGoing = false;
                for (var j = 0; j < event.Going.length; j++)
                {
                    if(user.FacebookId == event.Going[j].FacebookId)
                    {
                        isGoing = true;
                        break;
                    }
                }
                if(isGoing)
                    continue;
                if (user.FacebookId) {
                    var src = "https://graph.facebook.com/" + user.FacebookId + "/picture";
                    goingHtml += "<div><img src='" + src + "' /><div class='invitedIcon icon'><img src='/Img/invited.png' /></div><div>" + user.Name + "</div></div>";
                }
                //else if(user && user.Name && user.Name != "null") {
                //    var src = "/Img/face" + Math.floor(Math.random() * 8) + ".png";
                //    goingHtml += "<div class='nonFb'><img src='" + src + "' /><div class='invitedIcon icon'><img src='/Img/invited.png' /></div><div>" + user.Name + "</div></div>";
                //}
                people++;
            }
            //for (var i = people; i < event.MaxParticipants; i++) {
            //    goingHtml += "<div class='nonFb'><img src='/Img/grayface" + Math.floor(Math.random() * 8) + ".png' /><div>Open</div></div>";
            //}
            //var notGoing = event.MaxParticipants ? (event.MaxParticipants - people) * 64 : 0;
            var width = (people * 70) + 10;
            $("#detailsInvitedFriends .invitedFriendsScroll").css("width", width + "px");

            $("#detailsInvitedFriends .invitedFriendsScroll").html(goingHtml);
        }

        function HowManyGoing(event)
        {
            var howManyGoing = "";
            if (event.MinParticipants > 1 && event.MaxParticipants > 0)
                howManyGoing = "Min: " + event.MinParticipants + " Max: " + event.MaxParticipants;
            else if (event.MinParticipants > 1)
                howManyGoing = "Min: " + event.MinParticipants;
            else if (event.MaxParticipants > 0)
                "Max: " + event.MaxParticipants;

            return howManyGoing;
        }

        function JoinEvent() {
            if (!currentUser || !currentUser.Id) {
                OpenLogin();
                return;
            }

            currentEvent.IsDirty = true;
            $("#joinBtn").html("GOING");
            $("#joinBtn").addClass("selected");

            currentEvent.NotificationMessage = "Joined: " + currentEvent.Name;
            currentEvent.UserId = currentUser.Id;
            var going = { EventId: currentEvent.Id, UserId: currentUser.Id, FacebookId: currentUser.FacebookId, FirstName: currentUser.FirstName, IsAdmin: false };
            currentEvent.Going.push(going);
            UpdateDetailsGoing(currentEvent);

            Post("JoinEvent", { evt: currentEvent }, LoadEvents);
        }

        function UnjoinEvent()
        {
            currentEvent.IsDirty = true;
            $("#joinBtn").html("+ JOIN EVENT");
            $("#joinBtn").removeClass("selected");

            currentEvent.NotificationMessage = "Unjoined: " + currentEvent.Name;
            currentEvent.UserId = currentUser.Id;
            RemoveByUserId(currentEvent.Going, currentUser.Id);
            UpdateDetailsGoing(currentEvent);

            Post("UnjoinEvent", { evt: currentEvent }, LoadEvents);
        }

    </script>

    <!-- Login -->
    <script type="text/javascript">
        var fbAccessToken;

        //window.fbAsyncInit = function () {

        //    FB.init({
        //        appId: '397533583786525', // App ID
        //        status: true, // check login status
        //        cookie: true, // enable cookies to allow the server to access the session
        //        xfbml: true  // parse XFBML
        //    });
        //    fbAccessToken = getParameterByName("fbAccessToken");
        //    if (!fbAccessToken) {
        //        FB.getLoginStatus(function (response) {
        //            if (response.status === 'connected') {
        //                fbAccessToken = response.authResponse.accessToken;
        //            }
        //        });
        //    }

        //    var deviceId = getParameterByName("deviceId");
        //    var pushDeviceToken = getParameterByName("pushDeviceToken");
        //    Post("LoginUser", { facebookAccessToken: fbAccessToken, deviceId: deviceId, pushDeviceToken: pushDeviceToken, email:"", password:"" }, LoginSuccess);
        //};

        function OpenLogin()
        {
            $("#facebookLoginDiv").show();
        }

        function FacebookLogin() {
            ShowLoading();
            if (isiOS) {
                window.location = "ios:FacebookLogin";
            }
            else if(isAndroid)
            {
                if (typeof androidAppProxy !== "undefined")
                    androidAppProxy.AndroidFacebookLogin();
            }
        }

        // Load the SDK Asynchronously
        //(function (d) {
        //    var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
        //    if (d.getElementById(id)) { return; }
        //    js = d.createElement('script'); js.id = id; js.async = true;
        //    js.src = "//connect.facebook.net/en_US/all.js";
        //    ref.parentNode.insertBefore(js, ref);
        //}(document));

        </script>

    <!-- Friends / Address Book -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#inviteBtn").click(function () {
                $("#Invite").html("Add");
                $("#inviteGroups").show();
                if (isiOS && !$("#contactResults").html()) {
                    window.location = "ios:GetContacts";
                }
                else {
                    OpenAddressBook();
                }
            });
            $("#inviteDiv #Invite").click(function () {
                if (!$("#inviteGroups").is(':visible'))
                {
                    SendGroupInvites();
                }
                else if ($(this).html() == "Add") {
                    AddInvitesToCreate();
                }
                else {
                    SendInvites();
                    AddGroupsToEvent();
                }
            });
            $("#detailsInviteBtn").click(function () {
                $("#Invite").html("Invite");
                $("#inviteGroups").show();
                if (isiOS && !$("#contactResults").html()) {
                    window.location = "ios:GetContacts";
                }
                else {
                    OpenAddressBook();
                }
            });
            $("#groupInviteBtn").click(function () {
                $("#Invite").html("Invite");
                $("#inviteGroups").hide();
                if (isiOS && !$("#contactResults").html()) {
                    window.location = "ios:GetContacts";
                }
                else {
                    OpenAddressBook();
                }
            });
            $("#filterFriendsTextbox").keyup(function () {
                FilterFriends();
            });
            $("#inviteGroups").on("click", "div", function () {
                $(this).toggleClass("invited");
            });
            $("#inviteResults").on("click", "div", function () {
                $(this).toggleClass("invited");
            });
            $("#contactResults").on("click", "div", function () {
                $(this).toggleClass("invited");
            });
        });

        function OpenAddressBook() {
            OpenFromBottom("inviteDiv");
            $("#filterFriendsTextbox").val("");
            //$("#inviteResults div").removeClass("invited").show();
            //$("#contactResults div").removeClass("invited").show();
            //$("#addDiv .invitedFriendsScroll div").each(function () {
            //    if ($(this).attr("facebookId")) {
            //        var fbId = $(this).attr("facebookId");
            //        $("#inviteResults div").each(function () {
            //            if ($(this).attr("facebookId") == fbId)
            //                $(this).addClass("invited");
            //        });
            //    }
            //    if ($(this).attr("phone")) {
            //        var phone = $(this).attr("phone");
            //        $("#contactResults div").each(function () {
            //            if ($(this).attr("phone") == phone)
            //                $(this).addClass("invited");
            //        });
            //    }
            //});

            if (currentEvent && currentEvent.GroupId)
            {
                $(currentEvent.GroupId.split("|")).each(function () {
                    var groupId = this;
                    $("#inviteGroups div").each(function () {
                        if ($(this).attr("groupid") == groupId)
                            $(this).addClass("invited");
                    });
                });
            }
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

        function AddInvitesToCreate(friendList) {

            if (isiOS && friendList) {
                var html = "";
                for (var i = 0; i < friendList.length; i++) {
                    var friend = friendList[i];
                    if (friend.facebookId) //Facebook user
                        html += "<div facebookId='" + friend.facebookId + "' ><img src='https://graph.facebook.com/" + friend.facebookId + "/picture' /><div>" + friend.name + "</div></div>";
                    else
                        html += "<div phone='" + friend.phone + "' ><img src='/Img/face" + Math.floor(Math.random() * 8) + ".png' /><div>" + friend.name + "</div></div>";
                }
                $("#addDiv .invitedFriendsScroll").css("width", ((friendList.length * 70) + 25) + "px");
                $("#addDiv .invitedFriendsScroll").html(html);
            }
            else {
                var html = "";
                $("#inviteGroups div.invited").each(function () {
                    var groupId = $(this).attr("groupid");
                    if (!groupId)
                        return true;
                    var src = $(this).find(".logo").attr("src");
                    var name = $(this).find("div").html();
                    if (name.length > 7)
                        name = name.substring(0, 6) + "...";
                    html += "<div groupId='" + groupId + "' ><img src='" + src + "' /><div>" + name + "</div></div>";
                });
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
                    html += "<div phone='" + phone + "' class='nonFb' ><img src='/Img/face" + Math.floor(Math.random() * 8) + ".png' /><div>" + name + "</div></div>";
                });
                var width = $("#inviteGroups div.invited").length / 2 * 70 + $("#inviteResults div.invited").length * 70 + $("#contactResults div.invited").length * 60 + 25;
                $("#addDiv .invitedFriendsScroll").css("width", width + "px");
                $("#addDiv .invitedFriendsScroll").html(html);
                CloseToBottom("inviteDiv");
            }
        }

        function SendInvites(event) {
            var phoneList = "";
            if (!event) {
                event = jQuery.extend({}, currentEvent);
                $("#inviteResults div.invited").each(function () {
                    var fbId = $(this).attr("facebookId");
                    var name = $(this).find("span").html();
                    if (Contains(name, " "))
                        name = name.substring(0, name.indexOf(" "));

                    var inList = false;
                    $(event.Invited).each(function () {
                        if (this.FacebookId == fbId)
                            inList = true;
                    });
                    if (!inList)
                        event.Invited.push({ EventId: event.Id, FacebookId: fbId, Name: name, InvitedBy: currentUser.Id });
                });
                $("#contactResults div.invited").each(function () {
                    var phone = $(this).attr("phone");
                    var name = $(this).find("span").html();
                    if (Contains(name, " "))
                        name = name.substring(0, name.indexOf(" "));
                    event.Invited.push({ EventId: event.Id, FacebookId: "", Name: name, InvitedBy: currentUser.Id });
                    phoneList += phone + ",";
                });

                CloseRight($("#inviteDiv"));
            }
            else
            {
                event.Invited = [];

                $("#addDiv .invitedFriendsScroll > div").each(function () {
                    var fbId = $(this).attr("facebookId");
                    var phone = $(this).attr("phone");
                    var name = $(this).find("div").html();
                    if (!fbId && !phone)
                        return true;

                    event.Invited.push({ EventId: event.Id, FacebookId: fbId, Name: name, InvitedBy: currentUser.Id });
                    if(phone)
                        phoneList += phone + ",";
                });
            }

            if (event.Invited && event.Invited.length)
            {
                event.NotificationMessage = currentUser.FirstName + " invited you to " + event.Name;
                Post("SaveInvites", { evt: event }, UpdateDetailsGoing);
            }

            if (phoneList) {
                var message = "You're invited to " + event.Name + ". Download the Pow Wow app to reply: {Branch}";
                GetBranchLink(event, phoneList, message);
            }
        }

        function SendGroupInvites() {
            var invites = [];
            var nameList = "";
            var phoneList = "";
            $("#inviteResults div.invited").each(function () {
                var fbId = $(this).attr("facebookId");
                var name = $(this).find("span").html();
                if (Contains(name, " "))
                    name = name.substring(0, name.indexOf(" "));

                nameList += name + ", ";
                invites.push({ FacebookId: fbId, Name: name, InvitedBy: currentUser.Id });
            });
            $("#contactResults div.invited").each(function () {
                var phone = $(this).attr("phone");
                var name = $(this).find("span").html();
                if (Contains(name, " "))
                    name = name.substring(0, name.indexOf(" "));
                
                phoneList += phone + ",";
            });

            CloseRight($("#inviteDiv"));
            if (nameList) {
                nameList = nameList.substring(0, nameList.length - 2);
                var msg = nameList.indexOf(",") < 0 ? nameList + " has been invited." : nameList + " have been invited.";
                MessageBox(msg);
            }

            if (invites && invites.length) {
                var message = currentUser.FirstName + " invited you to " + currentGroup.Name;
                Post("SaveGroupInvites", { invites: invites, message: message });
            }

            if (phoneList) {
                var message = "You're invited to " + currentGroup.Name + ". Download the Pow Wow app to join: {Branch}";
                var evt = { ReferenceId: 0 };
                GetBranchLink(evt, phoneList, message);
            }
        }

        function AddGroupsToEvent()
        {
            $("#inviteGroups div.invited").each(function () {
                var groupId = $(this).attr("groupid");
                if (groupId)
                {
                    if (currentEvent.GroupId.indexOf(groupId) < 0) {
                        currentEvent.GroupId += currentEvent.GroupId ? "|" + groupId : groupId;
                        var groupName = $(this).find("div").html();
                        currentEvent.GroupName = currentEvent.GroupName ? currentEvent.GroupName + "|" + groupName : groupName;
                        var groupPictureUrl = $(this).find("img.logo").attr("src");
                        if (!currentEvent.GroupPictureUrl && groupPictureUrl.indexOf("group.png") < 0)
                            currentEvent.GroupPictureUrl = groupPictureUrl;
                        if (currentEvent.GroupIsPublic == false) {
                            var isPrivate = false;
                            $("#myGroupsDiv > div.private").each(function () {
                                if ($(this).attr("groupid") == groupId)
                                    isPrivate = true;
                            });
                            currentEvent.GroupIsPublic = !isPrivate;
                        }

                    }
                }
            });
            currentEvent.UserId = currentUser.Id;
            var success = function (result) {
                OpenEventDetails(result);
                LoadEvents();
            };
            Post("AddGroupsToEvent", { evt: currentEvent }, success);
        }

        function SendText(phoneList, message) {
            if (isiOS) {
                phoneList = phoneList.substring(0, phoneList.length - 1);
                var params = "?message=" + message + "&phone=" + phoneList;
                window.location = "ios:SendSMS" + params;
            }
            else if (isAndroid) {
                if (typeof androidAppProxy !== "undefined") {
                    androidAppProxy.sendSMS(phoneList, message);
                } else {
                    console.log("Running outside Android app");
                }
            }
        }
    </script>

    <!-- Menu -->
    <script type="text/javascript">
        $(document).ready(function () {
            $("#menuBtn").click(function () {
                MenuClick();
            });

            $("#menuBackground").click(function () {
                CloseMenu();
            });

            $("#litQuestion").click(function () {
                MessageBox("Create events to get points. The more people that join your event, the more points you get!");
            });

            $("body").on("click", ".content", function () {
                if ($("#menuDiv").is(':visible'))
                    CloseMenu();
            });

            $("#menuDiv").swipe({
                swipeLeft: function (event, direction, distance, duration, fingerCount) {
                    CloseMenu();
                }
            });

            $("#eventsButton").click(function () {
                $("#eventsButton, #interestsButton, #notificationsButton").removeClass("selected");
                $(this).addClass("selected");

                CloseGroups();
            });

            $("#interestsButton").click(function () {
                $("#eventsButton, #interestsButton, #notificationsButton").removeClass("selected");
                $(this).addClass("selected");

                OpenGroups();
            });

            $("#notificationsButton").click(function () {
                $("#eventsButton, #interestsButton, #notificationsButton").removeClass("selected");
                $(this).addClass("selected");

                CloseMenu();
            });

            $("#myGroupsDiv").on("click", "div", function () {
                var groupId = $(this).attr("groupid");
                if(!groupId)
                    return;
                var name = $(this).find("span").html();
                var isPrivate = false;
                GetGroup(groupId, name, isPrivate);
                setTimeout(CloseMenu, 500);
            });

            $("#myNotificationsDiv").on("click", "div", function () {
                var eventId = $(this).attr("eventid");
                if(eventId)
                    OpenEventFromNotification(eventId);
            });
        });


        function LoadNotifications() {
            if(currentUser && currentUser.Id)
                Post("GetNotifications", { userId: currentUser.Id }, PopulateNotifications);
        }

        function PopulateNotifications(results) {
            var html = "";
            for (var i = 0; i < results.length; i++) {
                var notification = results[i];
                var notificationHtml = '<div eventid="{eventId}" style="padding:8px 4px 8px 16px;border-bottom:1px solid #3F4552;"><span style="font-weight:bold;">{Message}</span><div style="padding-top:2px;">{SinceSent}</div></div>';
                notificationHtml = notificationHtml.replace("{eventId}", notification.EventId).replace("{Message}", notification.Message).replace("{SinceSent}", notification.SinceSent);
                html += notificationHtml;
            }

            $("#myNotificationsDiv").html(html);
        }


        function OpenEventFromNotification(eventId) {
            var success = function (event) {
                OpenEventDetails(event);
                setTimeout(CloseMenu, 500);
            };
            Post("GetEvent", { id: eventId }, success);
        }
    </script>

    <!-- Groups -->
    <script type="text/javascript">
        var currentGroup = {};

        $(document).ready(function () {

            $("#groupAddDiv .screenTitle").click(function () {
                if (currentUser && currentUser.FacebookId == "10106153174286280" || currentUser.FacebookId == "10106610968977054")
                {
                    $('#changeLatLngDiv').show();
                    $('.modal-backdrop').show();
                }
            });

            $("#changeLatLngDiv .okBtn").click(function () {
                var lat = $("#ChangeLatitude").val();
                var lng = $("#ChangeLongitude").val();
                ReceiveLocation(lat, lng);

                $('#changeLatLngDiv').hide();
                $('.modal-backdrop').hide();
                $("#groupAddDiv").hide();
                GroupsClick();
            });

            $("#groupsBtn").click(function () {
                GroupsClick();
            });

            $("#groupsAddBtn, #groupAddBtn, #groupAddBtnDiv").click(function () {
                if (!currentUser || !currentUser.Id) {
                    OpenLogin();
                    return;
                }
                AddEditGroup();
            });

            $("#groupDetailsDiv .detailMenuBtn").click(function () {
                setTimeout(function () { $("#groupEditBtn").show() }, 50);
            });

            $("#groupDetailsDiv").click(function () {
                $("#groupEditBtn").hide();
            });

            $("#groupDetailsDiv .detailMenuBtn").click(function () {
                $("#groupEditBtn").show();
            });

            $("#groupAddDiv .detailMenuBtn").click(function () {
                setTimeout(function () { $("#groupAddLocationsBtn").show() }, 50);
            });

            $("#groupAddDiv").click(function () {
                $("#groupAddLocationsBtn").hide();
            });

            $("#groupAddDiv .detailMenuBtn").click(function () {
                $("#groupAddLocationsBtn").show();
            });

            $("#groupFilterTextBox").keyup(function () {
                var search = $("#groupFilterTextBox").val().toLowerCase();
                if (search.length == 0) {
                    $("#groupsListDiv > div").show();
                    $("#groupsListDiv > div.private").hide();
                    return;
                }
                $("#groupsListDiv > div").each(function () {
                    var name = $(this).find("div").html().toLowerCase();
                    if (name.indexOf(search) >= 0)
                        $(this).show();
                    else
                        $(this).hide();
                });
            });

            $("#groupsListDiv").on("click", "div", function () {
                var groupId = $(this).attr("groupid");
                if (!groupId)
                    return;

                var name = $(this).find("div").html();
                if (name.indexOf("<img ") >= 0)
                    name = name.substring(0, name.indexOf("<img "));
                var isPrivate = $(this).hasClass("private");
                GetGroup(groupId, name, isPrivate);
            });

            $("#groupDetailsDiv #groupDetailsDescription").on("click", ".readMore", function () {
                $("#groupDetailsDiv #groupDetailsDescription").html(currentGroup.Description);
            });

            $("#detailsDiv #detailsDescription").on("click", ".readMore", function () {
                $("#detailsDiv #detailsDescription").html(currentEvent.Description);
            });

            $("#groupJoinBtn").click(function () {
                if (!IsGoing(currentGroup.Members, currentUser.Id))
                    JoinGroup();
                else
                    ActionMessageBox("Unjoin " + currentGroup.Name + "?", UnjoinGroup, null, "Yes", "No");
            });

            $("#myGroupsDiv").on("click", ".joinGroupBtn", function () {
                GroupsClick();
            });

            $("#addGroupsResultsDiv").on("click", ".joinGroupBtn", function () {
                $("#addGroupDiv").hide();
                $("#addDiv").hide();
                CloseMessageBox();
                OpenGroups();
            });

            $("#isPublicBtn").click(function () {
                PublicClick();
            });

            $("#groupAddDiv .bottomBtn").click(function () {
                SaveGroup();
            });

            $("#groupEditBtn").click(function () {
                AddEditGroup(currentGroup);
            });

            $("#groupAddLocationsBtn").click(function () {
                AddGroupLocations();
            });

            $("#checkPasswordDiv .okBtn").click(function () {
                var pwd = $("#checkPasswordDiv input").val();
                $("#checkPasswordDiv").hide();

                var ckPasswordTimer = setInterval(function () {
                    if(currentGroup && currentGroup.Id) {
                        clearInterval(ckPasswordTimer);
                        if (pwd == currentGroup.Password) {
                            $(".modal-backdrop").hide();
                            OpenGroupDetails();
                        }
                        else {
                            $("#checkPasswordDiv").hide();
                            MessageBox("Incorrect Password");
                        }
                    }
                }, 200);
            });

            $("#AddGroupPictureUrl").blur(function () {
                $("#AddGroupPicture").show().attr("src", $(this).val());
                $("#groupAddDiv .deleteBtn").show();
            });

            $("#groupAddDiv .deleteBtn").click(function () {
                $("#AddGroupPictureUrl").show().val("");
                $("#AddGroupPicture").hide().attr("src", $(this).val());
                $("#groupAddDiv .deleteBtn").hide();
            });

            $("#newUserResultsDiv").on("click", "div", function() {
                $(this).find("img.checkmark").toggleClass("unchecked");
            });

            $("#newUserDiv .okBtn").click(function() {
                $("#newUserResultsDiv img.checkmark").each(function() {
                    if(!$(this).hasClass("unchecked")) {
                        var groupId = $(this).closest("div").attr("groupid");

                        var group = { Id: groupId, UserId: currentUser.Id };
                        Post("JoinGroup", { group: group }, LoadMyGroups);
                    }
                });
                HideNewUserScreen();
            });

        });

        function AddEditGroup(group)
        {
            if (!group)
            {
                currentGroup = {};
                $("#groupAddDiv .screenTitle").html("Add Interest");
                $("#groupAddDiv .bottomBtn").html("Create");
                $("#groupAddDiv input").removeClass("error");
                $("#AddGroupDivName").val("");
                $("#AddGroupDescription").val("");
                $("#AddGroupSchool").val(currentSchool.Name);
                SetPublic(true);
                $("#AddGroupPassword").val("");
                $("#AddGroupPictureUrl").val("");
                $("#AddGroupPicture").hide();
                $("#groupAddDiv .deleteBtn").hide();
            }
            else
            {
                $("#groupAddDiv .screenTitle").html("Edit Interest");
                $("#groupAddDiv .bottomBtn").html("Save");
                $("#groupAddDiv input").removeClass("error");
                $("#AddGroupDivName").val(group.Name);
                $("#AddGroupSchool").val(group.SchoolName);
                $("#AddGroupDescription").val(group.Description);
                SetPublic(group.IsPublic);
                $("#AddGroupPassword").val(group.Password);
                $("#groupDetailsDiv").hide();
                if (group.PictureUrl) {
                    $("#AddGroupPictureUrl").hide().val(group.PictureUrl);
                    $("#AddGroupPicture").show().attr("src", group.PictureUrl);
                    $("#groupAddDiv .deleteBtn").show();
                }
                else {
                    $("#AddGroupPictureUrl").show().val("");
                    $("#AddGroupPicture").hide();
                    $("#groupAddDiv .deleteBtn").hide();
                }

            }
            $("#groupAddDiv").show();
        }

        function SaveGroup()
        {
            var error = false;
            $("#groupAddDiv input").removeClass("error");
            if (!$("#AddGroupDivName").val())
            {
                $("#AddGroupDivName").addClass("error");
                error = true;
            }
            if (error)
                return;

            currentGroup.Name = $("#AddGroupDivName").val();
            currentGroup.Description = $("#AddGroupDescription").val();
            currentGroup.SchoolId = currentSchool.Id;
            currentGroup.IsPublic = $("#isPublicBtn .selected").html() == "Public";
            currentGroup.Password = $("#AddGroupPassword").val();
            currentGroup.PictureUrl = $("#AddGroupPictureUrl").val();
            currentGroup.UserId = currentGroup.Id ? "" : currentUser.Id;
            if(!currentGroup.IsPublic && !currentGroup.Password)
            {
                MessageBox("Private interests must have passwords to access them.");
                $("#AddGroupPassword").addClass("error");
                return;
            }

            var success = function () {
                OpenGroups();
                LoadMyGroups();
            };

            Post("SaveGroup", { group: currentGroup }, success);
            $("#groupAddDiv").hide();
            if(!currentGroup.Id)
                MessageBox("Your interest " + currentGroup.Name + " has been created.");

        }

        function GetCityName() {
            currentGroup.Latitude = currentLat;
            currentGroup.Longitude = currentLng;

            var latlng = new google.maps.LatLng(currentLat, currentLng);
            var geocoder = new google.maps.Geocoder();
            geocoder.geocode({ 'latLng': latlng }, function (results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    if (results) {
                        for (var i = 0; i < results[0].address_components.length; i++) {
                            if (results[0].address_components[i].types[0] == "locality")
                                var city = results[0].address_components[i];
                            if (results[0].address_components[i].types[0] == "administrative_area_level_1")
                                var region = results[0].address_components[i];
                            if (results[0].address_components[i].types[0] == "country")
                                var country = results[0].address_components[i];
                        }
                        $("#AddGroupCity").val(city.long_name + ", " + region.short_name);
                    }
                } 
            });
        }

        function GetGroup(groupId, groupName, isPrivate)
        {
            if (isPrivate) {
                var priv = true;
                $("#myGroupsDiv > div").each(function () {
                    if ($(this).attr("groupid") == groupId)
                        priv = false;
                });
                if (priv) {
                    $("#checkPasswordDiv input").val("");
                    $("#checkPasswordDiv").show();
                    $(".modal-backdrop").show();
                    var success = function (results) {
                        currentGroup = results;
                    }
                    Post("GetGroup", { groupId: groupId, latitude: currentLat, longitude: currentLng, user: currentUser }, success);
                    return;
                }
            }

            OpenGroupInitial(groupName);
            Post("GetGroup", { groupId: groupId, latitude: currentLat, longitude: currentLng, user: currentUser }, OpenGroupDetails);
        }

        function LoadMyGroups() {
            Post("GetGroupsByUser", { userId: currentUser.Id }, PopulateMyGroups);
        }

        function PopulateMyGroups(results) {
            var html = "";
            for (var i = 0; i < results.length; i++) {
                var group = results[i];
                var groupHtml = '<div groupid="{groupId}" style="padding: 12px 4px 12px 16px;border-bottom:1px solid #3F4552;"><span>{Name}</span></div>';
                groupHtml = groupHtml.replace("{groupId}", group.Id).replace("{Name}", group.Name);
                if (group.IsPublic == false)
                    groupHtml = groupHtml.replace("style=", "class='private' style=");
                html += groupHtml;
            }
            if (!html)
                html = '<div class="joinGroupBtn" style="padding: 12px 4px 12px 16px;border-bottom:1px solid #3F4552;font-weight: bold;">+ ADD INTERESTS</div>';

            $("#myGroupsDiv").html(html);

            html = "<div style='color:white;background:#AAAAAA;padding: 4px 20px;border-bottom: 1px solid #D8D8D8;'>My Interests</div>";
            for (var i = 0; i < results.length; i++) {
                var group = results[i];
                var groupHtml = '<div groupid="{GroupId}" ><img class="logo" src="{PictureUrl}" onerror="this.src=\'../Img/group.png\';" /><div>{Name}</div><img class="check" src="/Img/check.png"></div>';
                groupHtml = groupHtml.replace("{GroupId}", group.Id).replace("{PictureUrl}", group.PictureUrl).replace("{Name}", group.Name);
                html += groupHtml;
            }
            if (!html)
                html = "<div style='text-align: center;'>You are not a member of any interests.</div><div class='blueBtn joinGroupBtn' style='margin: 24px 16%;'>Add Interests</div>";

            html += "</div>";
            $("#inviteGroups").html(html);
        }

        function LoadGroups() {
            Post("GetGroups", { schoolId:currentSchool.Id }, PopulateGroups);
        }

        function PopulateGroups(results) {
            var html = "";
            for (var i = 0; i < results.length; i++) {
                var group = results[i];
                var groupHtml = group.IsPublic ? '<div groupid="{GroupId}" >{Img}<div>{Name}</div></div>' : '<div groupid="{GroupId}" class="private" >{Img}<div>{Name}<img class="privateImg" src="../Img/whitelock.png"/></div></div>';
                var img = group.PictureUrl ? '<img src="' + group.PictureUrl + '" onerror="this.src=\'../Img/group.png\';" />' : '<img src="../Img/group.png" class="logo" />';
                groupHtml = groupHtml.replace("{GroupId}", group.Id).replace("{Img}", img).replace("{Name}", group.Name);
                html += groupHtml;
            }
            $("#groupsListDiv").html(html);

            //New User Groups
            html = "";
            var length = results.length < 4 ? results.length : 4;
            for (var i = 0; i < length; i++) {
                var group = results[i];
                var groupHtml = '<div groupid="{GroupId}" >{Img}<div>{Name}</div><img class="checkmark" src="/Img/check.png" /></div>';
                var img = group.PictureUrl ? '<img src="' + group.PictureUrl + '" onerror="this.src=\'../Img/group.png\';" />' : '<img src="../Img/group.png" class="logo" />';
                groupHtml = groupHtml.replace("{GroupId}", group.Id).replace("{Img}", img).replace("{Name}", group.Name);
                html += groupHtml;
            }

            $("#newUserResultsDiv").html(html);
        }

        function OpenGroupInitial(groupName) {
            $("#groupDetailsDiv .screenTitle").html(groupName);
            $("#groupDetailsLogo").hide();
            $("#groupDetailsDiv #groupDetailsInfo").html("");
            $("#groupDetailsDiv #groupDetailsDescription").html("");
            $("#groupInviteBtn").hide();
            $("#groupJoinBtn").hide();
            $("#groupDetailsDiv").show();
            $("#groupDetailsDiv #groupEvents").html("");
            $("#groupDetailsDiv .detailMenuBtn").hide();
        }

        function OpenGroupDetails(group) {
            HideLoading();
            if (group)
                currentGroup = group;

            $("#groupDetailsDiv").show();
            $("#groupDetailsDiv .screenTitle").html(currentGroup.Name);
            $("#groupDetailsLogo").show().attr("src", currentGroup.PictureUrl);
            var subheaderHtml = currentGroup.Members.length < 6 ? currentGroup.SchoolName : "<span style='font-weight:bold;'>" + currentGroup.Members.length + "</span> Members - " + currentGroup.SchoolName;
            $("#groupDetailsDiv #groupDetailsInfo").html(subheaderHtml);

            var descHtml = currentGroup.Description;
            if (descHtml.length > 110) {
                descHtml = descHtml.substring(0, 110) + " ... ";
                descHtml += "<a class='readMore'>Read More</a>";
            }

            $("#groupDetailsDiv #groupDetailsDescription").html(descHtml);
            $("#groupDetailsDiv #groupEvents").html(SetLocalTimes(currentGroup.EventsHtml));

            $("#groupInviteBtn").show();
            $("#groupJoinBtn").show();
            if (IsGoing(currentGroup.Members, currentUser.Id)) {
                $("#groupJoinBtn").html("MEMBER");
                $("#groupJoinBtn").addClass("selected");
            }
            else {
                $("#groupJoinBtn").html("+ ADD INTEREST");
                $("#groupJoinBtn").removeClass("selected");
            }

            if (IsAdmin(currentGroup.Members, currentUser.Id) || currentUser.FacebookId == "10106610968977054")
                $("#groupDetailsDiv .detailMenuBtn").show();
            else
                $("#groupDetailsDiv .detailMenuBtn").hide();
        }

        function JoinGroup() {
            if (!currentUser || !currentUser.Id) {
                OpenLogin();
                return;
            }

            $("#groupJoinBtn").html("MEMBER");
            $("#groupJoinBtn").addClass("selected");

            currentGroup.UserId = currentUser.Id;
            var user = { GroupId: currentGroup.Id, UserId: currentUser.Id, FacebookId: currentUser.FacebookId, FirstName: currentUser.FirstName, IsAdmin: false };
            currentGroup.Members.push(user);
            var subheaderHtml = currentGroup.Members.length < 6 ? currentGroup.SchoolName : "<span style='font-weight:bold;'>" + currentGroup.Members.length + "</span> Members - " + currentGroup.SchoolName;
            $("#groupDetailsDiv #groupDetailsInfo").html(subheaderHtml);

            if ($("#myGroupsDiv div").not(".joinGroupBtn").length <= 0)
            {
                MessageBox("You've joined " + currentGroup.Name + "! <br/><br/>You will now be notified when new events are added to this interest, or you can create your own events in this interest.");
            }

            Post("JoinGroup", { group: currentGroup }, LoadMyGroups);
        }

        function UnjoinGroup() {
            $("#groupJoinBtn").html("+ ADD INTEREST");
            $("#groupJoinBtn").removeClass("selected");

            currentGroup.UserId = currentUser.Id;
            RemoveByUserId(currentGroup.Members, currentUser.Id);
            var subheaderHtml = currentGroup.Members.length < 6 ? currentGroup.SchoolName : "<span style='font-weight:bold;'>" + currentGroup.Members.length + "</span> Members - " + currentGroup.SchoolName;
            $("#groupDetailsDiv #groupDetailsInfo").html(subheaderHtml);

            Post("UnjoinGroup", { group: currentGroup }, LoadMyGroups);
        }

        function SetPublic(isPublic) {
            var marginLeft = isPublic ? "0px" : "44%";
            $(".pillBtn .slider").css({ "margin-left": marginLeft });
            $(".pillBtn div").removeClass("selected");
            var idx = isPublic ? 1 : 2;
            $(".pillBtn div:eq(" + idx + ")").addClass("selected");
        }

        function AddGroupLocations()
        {
            $("#groupLocationsTextbox").val("");
            var locations = currentGroup.Locations ? currentGroup.Locations.split("|") : "";
            for (var i = 0; i < locations.length; i++)
            {

            }
            $("#groupLocationsDiv").show();
        }
    
        function ShowNewUserScreen() {
            if(!$("#groupsListDiv").html()) {
                LoadGroups();
            }
            
            $("#newUserDiv").show();
            $(".modal-backdrop").show();
        }
        
        function HideNewUserScreen() {
            $("#newUserDiv").hide();
            $("#showGroupsBtnDiv").show();
        }

    </script>

    <!-- Location -->
    <script type="text/javascript">
        var locationResults = [];
        var currentLocation = {};

        $(document).ready(function () {
            $("#AddLocation").focus(function () {
                $("#locationSearchTextbox").val("");
                $("#locationSearchTextbox").attr("readonly", false);
                $("#locationResults").html("");
                $("#locationDiv").show();
                $("#locationSearchTextbox").focus();

                if(currentGroup && currentGroup.Locations)
                {
                    $("#locationSearchTextbox").attr("readonly", true);
                    $("#locationSearchTextbox").blur();
                    var locations = currentGroup.Locations.split("|");
                    var html = "";
                    for(var i = 0; i < locations.length; i++)
                    {
                        var name = locations[i];
                        var location = { Name: name, Latitude: currentGroup.Latitude, Longitude: currentGroup.Longitude, Address: "" };
                        locationResults.push(location);
                        var locationHtml = '<div locationIdx="' + i + '" ><span style="font-weight:bold;">{Name}</span><div></div>{Address}</div>';
                        html += locationHtml.replace("{Name}", location.Name).replace("{Address}", location.Address);
                    }
                    $("#locationResults").html(html);
                }
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
                console.log("Index:" + index);
                console.log(currentLocation);
                PlotMap("AddMap", currentLocation.Name, currentLocation.Latitude, currentLocation.Longitude);
                $("#AddLocation").val(currentLocation.Name);
            }

            $("#locationDiv").hide();
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
            $("#detailsAddMessage").click(function () {
                $("#addMessageDiv .screenTitle").html(currentEvent.Name);
                $("#AddMessageTextbox").val("");
                $("#AddMessageTextbox").focus();
                OpenFromBottom("addMessageDiv");
            });

            $("#addMessageDiv .bottomBtn").click(function () {
                var text = $("#AddMessageTextbox").val();
                if (text) {
                    var message = { EventId: currentEvent.Id, Name: currentUser.FirstName, Message: text, UserId: currentUser.Id, FacebookId: currentUser.FacebookId };
                    Post("SendMessage", { message: message }, LoadMessages);
                }
                $("#addMessageDiv").hide();
            });

            $(".messageBtn").click(function () {
                OpenMessages();
            });

            $("#sendText").focus(function () {
                setTimeout(function () { $("#MessageResults").scrollTop(10000000); }, 200)
            });

            $("#sendText").keypress(function (e) {
                if (e.which == 13) {
                    SendMessage();
                }
            });

            $("#sendText").keyup(function () {
                var boxWidth = $("#sendText").width();
                $(".hiddenText").html($("#sendText").val());
                var rows = 1;
                while ($(".hiddenText").width() > boxWidth)
                {
                    $(".hiddenText").html(RemoveTextLine(boxWidth));
                    rows++;

                    if (rows > 10)
                        break;
                }
                $("#sendText").attr("rows", rows);
                $("#MessageResults").css("padding-bottom", (62 + 18 * rows) + "px");
                $("#MessageResults").scrollTop(10000000);
            });

            $("#messageDiv .backArrow").click(function () {
                CloseMessages();
            });

            $("#messageDiv").swipe({
                swipeRight: function (event, direction, distance, duration, fingerCount) {
                    CloseMessages();
                }
            });
        });

        function RemoveTextLine(boxWidth)
        {
            var text = $(".hiddenText").html();
            var line = "";
            $(".hiddenText").html("");
            while (true)
            {
                if(text.indexOf(" ") < 0)
                    return "";

                line += text.substring(0, text.indexOf(" "));
                $(".hiddenText").html(line);
                line += " ";
                if($(".hiddenText").width() > boxWidth)
                    return text;

                text = text.substring(text.indexOf(" ") + 1);
            }
        }

        function OpenMessages() {
            $("#addBtn").hide();
            $("#DetailMap").hide();
            $("#messageDiv").show();
            $("#messageDiv").show();
            $("#messageDiv .screenTitle").html(currentEvent.Name);
            $(".messageBtn").attr("src", "/Img/message.png");
            $("#MessageResults").scrollTop(10000000);
            LoadMessages();
        }

        function LoadMessages() {
            Post("GetMessages", { eventId: currentEvent.Id }, PopulateMessages);
        }

        function PopulateMessages(messages) {
            var html = "";
            for (var i = 0; i < messages.length; i++) {
                var message = messages[i];
                var messageHtml = "<div class='message'><img src='{FacebookPic}' /><div class='name'>{Name}</div><div class='sinceSent'>{SinceSent}</div><div class='messageText'>{Message}</div><div class='separator'></div>";
                html += messageHtml.replace("{FacebookPic}", "https://graph.facebook.com/" + message.FacebookId + "/picture")
                                    .replace("{Name}", message.Name).replace("{SinceSent}", message.SinceSent).replace("{Message}", message.Message);
            }

            $("#MessageResults").html(html);
            $("#MessageResults .separator:last-child").css({ height: "40px", "margin-bottom": "0" });

            $("#detailsAddMessage img").attr("src", "https://graph.facebook.com/" + currentUser.FacebookId + "/picture");
            $("#addMessageDiv img").attr("src", "https://graph.facebook.com/" + currentUser.FacebookId + "/picture");
            $("#addMessageDiv .name").html(currentUser.FirstName);

            //var html = "";
            //for (var i = 0; i < messages.length; i++) {
            //    var message = messages[i];
            //    if (message.UserId == currentUser.Id) {
            //        var messageHtml = "<div style='float:right;clear:both;margin-top: 8px;'>{SinceSent}</div><div class='meMessage'>{Message}</div>";
            //        html += messageHtml.replace("{SinceSent}", message.SinceSent).replace("{Message}", message.Message);
            //    }
            //    else {
            //        var messageHtml = "<div style='float:left;clear:both;margin-top: 8px;'>{From} - {SinceSent}</div><div class='youMessage'>{Message}</div>";
            //        html += messageHtml.replace("{From}", message.Name).replace("{SinceSent}", message.SinceSent).replace("{Message}", message.Message);
            //    }
            //}
            //$("#MessageResults").html(html);
            //$("#MessageResults").css("padding-top", (44 + $("#messageDiv .screenTitle").height()) + "px"); //Hack for multi line titles
            //$("#MessageResults").scrollTop(1000000);

            ////Mark Messages as read
            //Post("UpdateCheckedMessages", { eventId: currentEvent.Id, userId: currentUser.Id });
        }

        function SendMessage() {
            var text = $("#sendText").val();
            if(!text)
                return;
            
            var message = { EventId: currentEvent.Id, Name: currentUser.FirstName, Message: text, UserId: currentUser.Id, FacebookId: currentUser.FacebookId };
            Post("SendMessage", { message: message }, LoadMessages);
            $("#sendText").val("");
            $("#sendText").attr("rows", 1);
            $("#MessageResults").css("padding-bottom", "80px");
        }

        function CloseMessages() {
            $("#addBtn").show();
            $("#DetailMap").show();
            $("#messageDiv").hide();
        }

    </script>

    <!-- Clock / Date -->
    <script type="text/javascript">
            $(document).ready(function () {
                $("#AddStartTime").click(function () {
                    InitClock();
                });

                $("#AddDay").click(function () {
                    $(".modal-backdrop").show();
                    $("#dateDiv").show();
                    var results = $("#dateDivResults div");
                    for (var i = 0; i < results.length; i++) {
                        if ($(results[i]).hasClass("selected")) {
                            $("#dateDivResults").scrollTop(i * 42);
                            break;
                        }
                    }
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

                $("#dateDivResults").on("click", "div", function () {
                    $("#dateDivResults div").removeClass("selected");
                    $(this).addClass("selected");

                    $("#AddDay").val($(this).html());

                    $("#dateDiv").fadeOut();
                    $(".modal-backdrop").fadeOut();
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

            function InitDay() {
                var html = "";
                var today = new Date().getDay();
                var scroll = 0;
                for(var i = 0; i < 90; i++)
                {
                    var day = "Today";
                    if (i == 1)
                        day = "Tomorrow";
                    else if(i > 1)
                    {
                        day = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][(i + today) % 7];
                        var date = addDays(new Date(), i);
                        var month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][date.getMonth()];
                        day += ", " + month + " " + date.getDate();
                    }
                    if ($("#AddDay").val() == day) {
                        html += "<div class='selected'>" + day + "</div>";
                        scroll = i;
                    }
                    else {
                        html += "<div>" + day + "</div>";
                    }
                }
                $("#dateDivResults").html(html);
            }

            function addDays(date, days) {
                var result = new Date(date);
                result.setDate(result.getDate() + days);
                return result;
            }

            function GetDayLabel(dateTime)
            {
                var today = new Date();
                var startDate = new Date(dateTime);
                if (today.getDate() == startDate.getDate() && today.getMonth() == startDate.getMonth())
                    return "Today";
                else if (addDays(today, 1).getDate() == startDate.getDate() && addDays(today, 1).getMonth() == startDate.getMonth())
                    return "Tomorrow";

                var day = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][startDate.getDay()];
                var month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][startDate.getMonth()];
                return day + ", " + month + " " + startDate.getDate();
            }
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
        <div class="modal-backdrop"></div>
        <div class="loading"><img src="../Img/loading.gif" /></div>
        <div class="header">
            <div>
                <img id="menuBtn" src="/Img/smallmenu.png" />
                <img class="title" src="/Img/powwowtitle.png" />
 <%--               <img id="groupsBtn" src="/Img/whitegroup.png" />
                <input id="groupFilterTextBox" type="text" placeholder="Search Interests" />--%>
            </div>
        </div>
        <div class="content">
            <div id="contentResults">
                <img class="launchImg" src="../Img/launch.png" />
            </div>
        </div>
        <div id="addBtn"><img src="../Img/plus.png" /></div>
        <div id="menuDiv">
            <div id="menuContent">
                <div style="border-bottom: 1px solid #ccc;">
                    <img class="facebookPic" style="margin: 15px 20px; width: 50px; border-radius: 25px;" />
                    <div class="facebookName" style="width: 90px;text-align: center;margin-bottom: 8px;"></div>
                    <div class="litPoints" style="text-align: right;position: absolute;top: 35px;right: 62px;font-size: 24px;">0</div>
                    <img src="../Img/match.png" style="width: 60px;position: absolute;top: 14px;right: 10px;" />
                    <img id="litQuestion" src="../Img/questionmark.png" style="width: 18px;position: absolute;top: 5px;right: 5px;" />
                </div>
                <div id="eventsButton" class="selected">Events</div>
                <div id="interestsButton">Interests</div>
                <div id="notificationsButton">Notifications</div>
            </div>
            <div id="menuBackground"></div>
        </div>
        <div id="groupsDiv">
<%--            <div id="groupAddBtnDiv">
                Add Interest
                <img id="groupAddBtn" src="../Img/grayAdd.png" />
            </div>--%>
            <div class="menuHeader">ST. EDWARD'S INTERESTS</div>
            <div id="groupsListDiv"></div>
            <div id="groupsAddBtn"><img src="../Img/plus.png" /></div>
        </div>
        <div id="groupAddDiv" class="screen swipe">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle">Add Interest</div>
            </div>
            <div class="screenContent">
                <input id="AddGroupDivName" type="text" placeholder="Your Interest Name" style="margin:12px 0 4px;" />
                <input id="AddGroupSchool" type="text" placeholder="School" style="margin-bottom:4px;" readonly="readonly" />
                <textarea id="AddGroupDescription" rows="4" placeholder="Description"></textarea>
                <div id="isPublicBtn" class="pillBtn" style="margin:10px 0 12px;clear:both;">
                    <div class="slider"></div>
                    <div style="margin: -26px 0 0 18%;float:left;" class="selected">Public</div>
                    <div style="margin: -26px 18% 0 0;float:right;">Private</div>
                </div>
                <input id="AddGroupPassword" type="text" placeholder="Private Password" style="margin-bottom:4px;" readonly="readonly" />
                <div style="display:none;"><input id="AddGroupPictureUrl" type="text" placeholder="Logo Image Url"  /></div>
                <img id="AddGroupPicture" style="height: 80px;margin: 10px 0;" onerror="this.style.display='none';" />
                <img class="deleteBtn" src="../Img/delete.png" />
            </div>
            <div class="screenBottom"><div class="bottomBtn">Create</div></div>
        </div>
        <div id="groupDetailsDiv" class="screen swipe">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle"></div>
                <img class="detailMenuBtn" src="/Img/smallmenu.png" />
                <div id="groupEditBtn">Edit</div>
            </div>
            <div class="screenSubheader">
                <img id="groupDetailsLogo" onerror="this.style.display='none';" />
                <div id="groupDetailsInfo"></div>
                <div id="groupJoinBtn" class="joinBtn">+ ADD INTEREST</div>
            </div>
            <div class="screenContent">
                <div id="groupDetailsDescription"></div>
                <div id="groupInviteBtn">Invite Friends to Interest</div>
            </div>
            <div id="groupEvents"></div>
            <div id="addFromGroupBtn"><img src="../Img/plus.png" /></div>
        </div>
        <div id="addDiv" class="screen">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle">Create Event</div>
            </div>
            <div class="screenContent" style="margin-bottom: 70px;">
                <div>
                    <input id="AddName" type="text" placeholder="What do you want to do?" style="margin:12px 0 4px;" />
                    <input id="AddLocation" type="text" placeholder="Location" style="display:none;float:left;margin-bottom:4px;" />
                    <input id="AddDay" type="text" placeholder="Day" readonly="readonly" style="width:48%;float:left;margin-bottom:4px;" />
                    <input id="AddStartTime" type="text" placeholder="Start Time" readonly="readonly" style="width:32%;float:right;" />
                    <textarea id="AddDetails" rows="4" placeholder="Location & Details"></textarea>
                    <div id="AddEventIcons"></div>
                    <%--<div style="float:left;margin:16px 0;">Total People?</div>
                    <input id="AddMax" type="number" placeholder="Max" style="width:15%;float:right;margin-left:4px;" />
                    <input id="AddMin" type="number" placeholder="Min" style="width:15%;float:right;" />--%>
                </div>
                <div class="separator" style="position: absolute;left: 0;right: 0;bottom: 178px;"></div>
                <div id="inviteBtn" style="position: absolute;left: 0;right: 0;bottom: 135px;">Invite Friends or Interests</div>
                <div class="invitedFriends" style="position: absolute;left: 0;right: 16px;bottom: 68px;"><div class="invitedFriendsScroll"></div></div>
                <div id="AddMap" style="clear:both;"></div>
                <div id="deleteEventBtn" style="text-align:center;color:#4285F4;display:none;position:absolute;left: 0;right: 0;bottom: 148px;">Close Event</div>
            </div>
            <div class="screenBottom"><div class="bottomBtn">Create</div></div>
        </div>
        <div id="detailsDiv" class="screen">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle" style="margin-right: 54px;min-height:21px;"></div>
                <img class="detailMenuBtn" src="/Img/smallmenu.png" />
                <%--<img class="messageBtn" src="/Img/message.png" />--%>
                <div id="detailsEditBtn">Edit</div>
            </div>
            <div class="screenSubheader" style="background: white;">
                <img id="detailsLogo" onerror="this.style.display='none';" />
                <div id="detailsInfo"></div>
                <div id="joinBtn" class="joinBtn">+ JOIN EVENT</div>
            </div>
            <div class="screenContent" style="background: white;">
                <div id="detailsDescription"></div>
                <div id="detailsInviteBtn" >Invite Friends or Interests</div>
                <div class="separator"></div>
                <div id="detailsHowMany" style="text-align:center;margin-bottom: 12px;"></div>
                <div id="detailsInvitedFriends" class="invitedFriends" style="overflow-x: scroll;overflow-y: hidden;height: 90px;" ><div class="invitedFriendsScroll"></div></div>
                <div class="separator"></div>
                <div id="detailsAddMessage">
                    <img class="addMessagePic" style="height: 50px;width: 50px;border-radius: 25px;float: left; margin: -8px 16px 0 9px;" />
                    <div style="padding: 9px 0 20px;color: #aaa;">Say Something...</div>
                </div>
                <div class="separator" style="border-bottom:none;"></div>
                <div id="MessageResults"></div>
            </div>
        </div>
        <div id="addMessageDiv" class="screen swipe">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle"></div>
            </div>
            <img class="addMessagePic" style="height: 50px;width: 50px;border-radius: 25px;margin: 20px 12px 12px 30px;" />
            <div class="name" style="position: absolute;top: 87px;left: 100px;font-weight: bold;"></div>
            <textarea id="AddMessageTextbox" rows="4" placeholder="Post to Event" style="margin: 0 26px;width: 80%;"></textarea>
            <div class="bottomBtn">Post</div>
        </div>
<%--        <div id="messageDiv" class="screen">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle"></div>
            </div>
            <div id="MessageResults"></div>
            <div id="sendDiv">
                <textarea id="sendText" rows="1" placeholder="Message"></textarea>
                <div onclick="SendMessage();">Send</div>
                <div class="hiddenText"></div>
            </div>
        </div>--%>
        <div id="locationDiv" class="screen swipe">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle">Add Location</div>
            </div>
            <div class="screenContent">
                <input id="locationSearchTextbox" type="text" placeholder="Search" style="margin:12px 0;" />
                <div id="locationResults"></div>
            </div>
        </div>
        <div id="inviteDiv" class="screen swipe">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle">Recipients</div>
                <div id="Invite">Add</div>
            </div>
            <input id="filterFriendsTextbox" type="text" placeholder="Search" style="margin: 14px 14px;width: 85%;" />
            <div id="inviteGroups"></div>
            <div id="inviteResults" class="addressBookList"></div>
            <div id="contactResults" class="addressBookList" style="margin-bottom: 90px;"></div>
        </div>
<%--        <div id="groupLocationsDiv" class="screen swipe">
            <div class="screenHeader">
                <div class="backArrow" ></div>
                <div class="screenTitle">Add Locations</div>
            </div>
            <div class="screenContent">
                <input id="groupLocationsTextbox" type="text" placeholder="Search" style="margin:12px 0;" />
                <div id="groupLocationsResults"></div>
            </div>
        </div>--%>
         <div id="facebookLoginDiv" class="screen swipe">
             <img src="../Img/bluebackarrow.png" onclick="$('#facebookLoginDiv').hide();" style="position: absolute;height: 28px;width: 30px;left: 16px;top: 14px;" />            
             <div id="loginHeader" style="margin:15px 44px 25px;text-align: center;font-size: 20px;line-height: 28px;">Log In to Find Activities Near You Today</div>
            <img src="../Img/appScreenshot1.png" style="margin: 12px auto;height: 64%;display:block;" />
            <div style="text-align: center;position: absolute;width: 100%;top: 100%;margin-top: -80px;">
                <div onclick="FacebookLogin();" style="display:block;margin:0 auto;width: 80%;background-color:#3B5998;color:white;padding: 10px 0;border-radius: 5px;">Log In with Facebook</div>
                <div style="margin-top: 6px;font-size: 14px;">We don't post anything to Facebook</div>
            </div>
        </div>
        <div id="dateDiv">
            <div id="dateDivResults"></div>
            <div onclick='$("#dateDiv").fadeOut();$(".modal-backdrop").fadeOut();' class="smallBottomBtn" >Cancel</div>
        </div>
        <div id="clockDiv">
            <div class="time"></div>
            <div id="clockCircle"></div>
            <div class="ampm" style="float:left;">AM</div>
            <div class="ampm" style="float:right;">PM</div>
            <div onclick='$("#clockDiv").fadeOut();$(".modal-backdrop").fadeOut();' class="smallBottomBtn" >Cancel</div>
        </div>
        <div id="addGroupDiv">
            <div id="addGroupsResultsDiv"></div>
            <div class="smallBottomBtn" >Cancel</div>
        </div>
        <div id="newUserDiv">
            <div style="text-align: center;margin: 1em;font-size: 24px;font-weight: 500;">Add Interests</div>
            <div style="margin: 0 32px 24px;">Add interests to hear about new events from that interest.<br /><br />Here are some interests we think you'd like.</div>
            <div id="newUserResultsDiv"></div>
            <div class="okBtn smallBottomBtn" style="left:0;right:50%;">Join</div><div onclick="HideNewUserScreen();" class="smallBottomBtn" style="left:50%;right:0;border-left:1px solid #ccc;">Not Now</div>
        </div>
        <div id="showGroupsBtnDiv">
            <div class="arrowup"></div>
            <img src="/Img/whitegroup.png" class="fakeGroupsBtn" />
            <div style="margin: 12px 32px 60px;">Click here to find more interests or create your own.</div>
            <div class="okBtn smallBottomBtn" onclick="$('#showGroupsBtnDiv').hide();$('.modal-backdrop').hide();" >OK</div>
        </div>
        <div id="checkPasswordDiv">
            <div class="messageContent" style="margin-bottom: 12px;line-height: 1.4em;">This interest is private. Enter interest password.</div>
            <input type="text" placeholder="Group Password" style="margin-bottom:50px;width: 85%;" />
            <div class="okBtn smallBottomBtn" style="left:0;right:50%;">Ok</div><div onclick="$('#checkPasswordDiv').hide();$('.modal-backdrop').hide();" class="smallBottomBtn" style="left:50%;right:0;border-left:1px solid #ccc;">Cancel</div>
        </div>
        <div id="MessageBox">
            <div class="messageContent"></div>
            <div onclick="CloseMessageBox();" class="smallBottomBtn">OK</div>
        </div>
        <div id="ActionMessageBox">
            <div class="messageContent"></div>
            <div class="yesBtn smallBottomBtn" style="left:0;right:50%;">OK</div><div onclick="CloseMessageBox();" class="noBtn smallBottomBtn" style="left:50%;right:0;border-left:1px solid #ccc;">Cancel</div>
        </div>
        <div id="changeLatLngDiv">
            <div class="messageContent">Change Location</div>
            <input id="ChangeLatitude" type="text" placeholder="Latitude" style="margin-top: -32px;" />
            <input id="ChangeLongitude" type="text" placeholder="Longitude" style="margin-bottom: 48px;" />
            <div class="okBtn smallBottomBtn" style="left:0;right:50%;">OK</div><div onclick="$('#changeLatLngDiv').hide();$('.modal-backdrop').hide();" class="smallBottomBtn" style="left:50%;right:0;border-left:1px solid #ccc;">Cancel</div>
        </div>
    </form>
</body>
</html>

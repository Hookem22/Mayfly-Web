﻿
window.mobilecheck = function () {
    var check = false;
    (function (a) { if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(a) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4))) check = true })(navigator.userAgent || navigator.vendor || window.opera);
    return check;
}

function tabletCheck() {
    return navigator.userAgent.match(/Android|BlackBerry|iPhone|iPad|iPod|Opera Mini|IEMobile/i);
}

function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
    var regexS = "[\\?&]" + name + "=([^&#]*)";
    var regex = new RegExp(regexS);
    var results = regex.exec(window.location.search);
    if (results == null)
        return "";
    else
        return decodeURIComponent(results[1].replace(/\+/g, " "));
}

function EscapeString(val) {
    val = encodeURI(val);
    val = val.replace(/'/g, "\\'");
    return val;
}

function Post(url, data, success) {
    if (url.indexOf("aspx") <= 0)
        url = "Default.aspx/" + url;
    $.ajax({
        type: "POST",
        url: url,
        data: JSON.stringify(data),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function (val) {
            if (success)
                success(val.d);
        }
    });
}

$(function () {
    $("form").submit(function () { return false; });
});

$(function () {
    $("body").on("click", ".modal-dialog .dialogClose", function () {
        $(".modal-dialog").hide();
        $(".modal-backdrop").hide();
    });
});
function RemoveFrontBreaks(text)
{
    while (text.indexOf("<") == 0) {
        text = text.substring(text.indexOf(">") + 1);
    }
    return text;
}
function MessageBox(message)
{
    $("#MessageBox .messageContent").html(message);
    var ht = $("#MessageBox").height();
    $("#MessageBox").css("margin-top", (-.5 * ht - 25) + "px");
    $("#MessageBox").show();
    $(".modal-backdrop").show();
}

var goFunction;
var goParam;

function ActionMessageBox(message, go, param, yesBtn, noBtn) {
    $("#ActionMessageBox .messageContent").html(message);
    $("#ActionMessageBox").show();
    $(".modal-backdrop").show();
    var ht = $("#ActionMessageBox").height();
    $("#ActionMessageBox").css("margin-top", (-.5 * ht - 25) + "px");

    var yes = yesBtn || "Ok";
    var no = noBtn || "Cancel";
    $("#ActionMessageBox .yesBtn").html(yes);
    $("#ActionMessageBox .noBtn").html(no);

    goFunction = go;
    goParam = param;
}
$(function () {
    $("#ActionMessageBox .yesBtn").click(function() {
        goFunction(goParam);
        CloseMessageBox();
    });
});

function CloseMessageBox() {
    $("#MessageBox").hide();
    $("#ActionMessageBox").hide();
    $(".modal-backdrop").hide();
}
function AddToString(list, item) {
    if (list.indexOf(item) < 0) {
        if (!list)
            list = item;
        else
            list += "|" + item;
    }
    return list;
}
function RemoveFromString(list, item) {
    var newList = "";
    $(list.split("|")).each(function () {
        if (this.indexOf(item) < 0)
            newList += this + "|";
    });
    if (newList)
        newList = newList.substring(0, newList.length - 1);

    return newList;
}

function OpenFromBottom(divId) {
    $("#" + divId).show();
    $("#" + divId).animate({ top: "0" }, 350);
}

function CloseToBottom(divId, withRefresh){
    if (withRefresh)
        LoadEvents();
    $("#" + divId).animate({ top: "100%" }, 350, function () { $("#" + divId).hide() });
}
function Contains(fullString, sub) {
    if (!fullString || !sub)
        return false;

    return fullString.indexOf(sub) >= 0;
}
function ToLocalDay(dateTime, includeToday)
{
    var localDate = new Date(dateTime);
    var localDay = localDate.getDay();
    if (includeToday) {
        var today = new Date().getDay();
        if (today == localDay)
            return "Today";
        else if (localDay - today == 1)
            return "Tomorrow";
    }
    var weekDay = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][localDay];
    var month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][localDate.getMonth()];
    return weekDay + ", " + month + " " + localDate.getDate();
}
function ToLocalTime(dateTime) {
    var localTime = new Date(dateTime).toLocaleTimeString().replace(":00", "");
    if(localTime.split(" ").length > 2)
    {
        var splitTime = localTime.split(" ");
        localTime = splitTime[0] + " " + splitTime[1];
    }
    return localTime;
}
function ShowLoading()
{
    $(".modal-backdrop").show();
    $(".loading").show();
}
function HideLoading()
{
    $(".modal-backdrop").hide();
    $(".loading").hide();
}

function IsGoing(going, userId)
{
    if (!going)
        return false;
    for (var i = 0; i < going.length; i++) {
        if (going[i].UserId == userId)
            return true;
    }
    return false;
}
function IsAdmin(going, userId) {
    for (var i = 0; i < going.length; i++) {
        if (going[i].UserId == userId)
            return going[i].IsAdmin;
    }
    return false;
}
function IsMuted(going, userId) {
    for (var i = 0; i < going.length; i++) {
        if (going[i].UserId == userId)
            return going[i].IsMuted;
    }
    return false;
}

function RemoveByUserId(list, userId)
{
    for (var i = list.length - 1; i >= 0; i--) {
        if (list[i].UserId == userId)
            list.splice(i, 1);
    }
    return list;
}


/*Animations*/
function MenuClick() {
    if ($("#menuDiv").is(':visible'))
        CloseMenu();
    else
        OpenMenu();
}

function OpenMenu() {
    $("#menuDiv").removeClass("menuClose");
    $("#menuDiv").show().addClass("menuOpen");
    $(".content").removeClass("contentMenuClose");
    $(".content").addClass("contentMenuOpen");
    $("#groupsDiv").removeClass("groupOpen");
    $("#groupsDiv").addClass("groupClose");
    $("#notificationsDiv").removeClass("groupOpen");
    $("#notificationsDiv").addClass("groupClose");
    $("#menuBackground").show();
}

function CloseMenu() {
    $("#groupsDiv").removeClass("groupClose");
    $("#groupsDiv").addClass("groupOpen");

    $("#notificationsDiv").removeClass("groupClose");
    $("#notificationsDiv").addClass("groupOpen");

    $("#menuDiv").removeClass("menuOpen");
    $("#menuDiv").addClass("menuClose");
    $(".content").addClass("contentMenuClose");
    $("#menuBackground").hide();

    setTimeout(function () {
        $("#menuDiv").hide();
    }, 500);
}

function OpenEvents() {
    CloseMenu();
    $(".content").show();
    $("#groupsDiv").hide();
    $("#notificationsDiv").hide();
}

function OpenGroups() {
    CloseMenu();
    $(".content").hide();
    $("#groupsDiv").show();
    $("#notificationsDiv").hide();
}

function OpenNotifications() {
    CloseMenu();
    $(".content").hide();
    $("#groupsDiv").hide();
    $("#notificationsDiv").show();
}

function CloseRight(screen)
{
    $(screen).addClass("closeRight");

    setTimeout(function () {
        $(screen).removeClass("closeRight");
        $(screen).hide();
    }, 500);
}

function PublicClick() {
    var isPublic = $("#isPublicBtn .selected").html() == "Public";

    var addClass = isPublic ? "isPrivate" : "isPublic";
    $(".pillBtn .slider").addClass(addClass);

    setTimeout(function () {
        var idx = isPublic ? 2 : 1;
        $(".pillBtn div").removeClass("selected");
        $(".pillBtn div:eq(" + idx + ")").addClass("selected");
        $("#AddGroupPassword").attr("readonly", !isPublic);
        $("#AddGroupPassword").val("");
        if(!isPublic)
        {
            $(".pillBtn .slider").removeClass("isPrivate").removeClass("isPublic");
        }
    }, 350);
}


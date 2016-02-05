<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="AppDesign_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
   <title>Pow Wow</title>
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <link href="/Styles/App.css?i=1" rel="stylesheet" type="text/css" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script src='/Scripts/spectrum.js'></script>
    <link href="/Styles/spectrum.css" rel="stylesheet" type="text/css" />
    <script type="text/javascript">
        var icons = [[
            "https://cdn0.iconfinder.com/data/icons/weather-icons-rounded/110/Cloudy-128.png",
            "https://cdn0.iconfinder.com/data/icons/sports-icons-rounded/110/Bowling-128.png",
            "https://cdn0.iconfinder.com/data/icons/clothes-icons-rounded/110/Sunglasses-2-128.png",
            "https://cdn0.iconfinder.com/data/icons/learning-icons-rounded/110/Chalkboard-128.png",
            "https://cdn0.iconfinder.com/data/icons/party-icons-rounded/110/Party-Poppers-128.png",
            "https://cdn0.iconfinder.com/data/icons/party-icons-rounded/110/Dj-128.png",
            "https://cdn0.iconfinder.com/data/icons/symbols-icons-rounded/110/Captain-Shield-128.png",
            "https://cdn0.iconfinder.com/data/icons/transportation-icons-rounded/110/Old-Car-2-128.png",
            "https://cdn0.iconfinder.com/data/icons/rewards-icons-rounded/110/Prize-Cup-128.png",
            "https://cdn0.iconfinder.com/data/icons/video-icons-rounded/110/Movie-Slate-128.png",
            "https://cdn0.iconfinder.com/data/icons/sports-icons-rounded/110/Basketball-128.png",],

           ["https://cdn1.iconfinder.com/data/icons/android-user-interface-vol-2-1/32/91_-Brightness_full_no_light_adjust_sun_interface-128.png",
            "https://cdn2.iconfinder.com/data/icons/indoor-games-and-sports-vol-4-1/32/Game_sports_sport_bowling_pins_play-128.png",
            "https://cdn1.iconfinder.com/data/icons/user-ui-vol-1-3/25/tune_music_melody_beat_interface_UI-128.png",
            "https://cdn1.iconfinder.com/data/icons/tools-19/48/job_pen_pencil_tool_stationary_draw_write-128.png",
            "https://cdn2.iconfinder.com/data/icons/food-and-kitchen-vol-4-1/32/food_kitchen_drink_beer_alcohol_glass_cerveza-128.png",
            "https://cdn2.iconfinder.com/data/icons/indoor-games-and-sports-vol-4-1/32/Game_sport_rocket_fly_takeoff-128.png",
            "https://cdn2.iconfinder.com/data/icons/military-vol-4-1/32/air_apache_army_blades_helicopter_military_sky-128.png",
            "https://cdn2.iconfinder.com/data/icons/military-vol-4-1/32/army_gun_military_tank_vehicle_war_weapon-128.png",
            "https://cdn2.iconfinder.com/data/icons/outdoor-games-and-sports-vol-4-2/32/Game_sports_sport_football_soccer_stadium_play-128.png",
            "https://cdn2.iconfinder.com/data/icons/images-and-video-4/32/35_camera_photo_video_capture_device_streamline_photography_1-128.png",
            "https://cdn2.iconfinder.com/data/icons/indoor-games-and-sports-vol-4-1/32/Game_sports_sport_basketball_NBA_net_basket-128.png"],

            ["https://cdn3.iconfinder.com/data/icons/weather-37/512/Weather_Sun_glasses-128.png",
             "https://cdn3.iconfinder.com/data/icons/sports-and-activities-1/512/Sports_Bowling_ball-128.png",
             "https://cdn3.iconfinder.com/data/icons/music-and-movies/512/Multimedia_Headset-128.png",
             "https://cdn3.iconfinder.com/data/icons/finance-10/512/Business_Books-128.png",
             "https://cdn3.iconfinder.com/data/icons/kitchen-and-drinks/512/Food_and_Drinks_Beer-128.png",
             "https://cdn4.iconfinder.com/data/icons/holidays-and-occasions-doodles/512/Holidays-02-128.png",
             "https://cdn4.iconfinder.com/data/icons/holidays-and-occasions-doodles/512/Holidays-69-128.png",
             "https://cdn3.iconfinder.com/data/icons/transportation-14/512/Transportation_Car_front-128.png",
             "https://cdn3.iconfinder.com/data/icons/sports-and-activities-1/512/Sports_Football-128.png",
             "https://cdn3.iconfinder.com/data/icons/music-and-movies/512/Multimedia_Movie_camera-128.png",
             "https://cdn3.iconfinder.com/data/icons/sports-and-activities-1/512/Sports_Basketball-128.png"],

            ["https://cdn1.iconfinder.com/data/icons/nature-and-wildlife/137/Nature_24-10-128.png",
             "https://cdn0.iconfinder.com/data/icons/toys-and-games-1/512/Toys_Games_Bowling_ball_pin-128.png",
             "https://cdn4.iconfinder.com/data/icons/music-and-entertainment/512/Music_Entertainment_plug_music_speakers_mic-128.png",
             "https://cdn0.iconfinder.com/data/icons/education-flat-icons/137/Education_teaching_science_study_-12-128.png",
             "https://cdn4.iconfinder.com/data/icons/food-and-beverages/512/Food_Beverages_Wine_bottle_almost_empty-128.png",
             "https://cdn4.iconfinder.com/data/icons/music-and-entertainment/512/Music_Entertainment_Crowd-128.png",
             "https://cdn3.iconfinder.com/data/icons/world-monuments/137/WorldMonuments-12-128.png",
             "https://cdn4.iconfinder.com/data/icons/transportation-15/512/Transportation_Bug_car-128.png",
             "https://cdn0.iconfinder.com/data/icons/sports-and-fitness-flat-colorful-icons-svg/134/Sports_flat_round_colorful_simple_activities_athletic_colored-18-128.png",
             "https://cdn4.iconfinder.com/data/icons/music-and-entertainment/512/Music_Entertainment_filming_board_film_sign-128.png",
             "https://cdn0.iconfinder.com/data/icons/sports-and-fitness-flat-colorful-icons-svg/137/Sports_flat_round_colorful_simple_activities_athletic_colored-04-128.png"],

            ["https://cdn4.iconfinder.com/data/icons/weather-volume-1-1/48/01-128.png",
             "https://cdn4.iconfinder.com/data/icons/sports-volume-1-3/48/14-128.png",
             "https://cdn4.iconfinder.com/data/icons/music-volume-2-3/48/62-128.png",
             "https://cdn4.iconfinder.com/data/icons/education-volume-4-2/48/08-128.png",
             "https://cdn4.iconfinder.com/data/icons/hotel-and-restaurant-volume-5-3/48/215-128.png",
             "https://cdn4.iconfinder.com/data/icons/music-volume-2-3/48/73-128.png",
             "https://cdn4.iconfinder.com/data/icons/education-volume-1-2/48/80-128.png",
             "https://cdn4.iconfinder.com/data/icons/travel-volume-2-1/48/80-128.png",
             "https://cdn4.iconfinder.com/data/icons/sports-volume-1-3/48/05-128.png",
             "https://cdn4.iconfinder.com/data/icons/electronics-volume-3-2/48/105-128.png",
             "https://cdn4.iconfinder.com/data/icons/sports-volume-1-3/48/02-128.png"],

            ["https://cdn1.iconfinder.com/data/icons/hotel-and-restaurant-flat-2/128/67-128.png",
             "https://cdn1.iconfinder.com/data/icons/business-and-finance-flat-1/128/05-128.png",
             "https://cdn3.iconfinder.com/data/icons/multimedia-flat-icons-vol-1/256/04-128.png",
             "https://cdn1.iconfinder.com/data/icons/education-colored-icons-vol-3/128/103-128.png",
             "https://cdn0.iconfinder.com/data/icons/food-volume-2-3/256/32-128.png",
             "https://cdn3.iconfinder.com/data/icons/multimedia-flat-icons-vol-1/256/05-128.png",
             "https://cdn1.iconfinder.com/data/icons/education-colored-icons-vol-1/128/038-128.png",
             "https://cdn4.iconfinder.com/data/icons/transport-flat-icons-vol-1/256/38-128.png",
             "https://cdn1.iconfinder.com/data/icons/education-3-3/128/105-128.png",
             "https://cdn3.iconfinder.com/data/icons/multimedia-flat-icons-vol-1/256/07-128.png",
             "https://cdn1.iconfinder.com/data/icons/education-colored-icons-vol-3/128/123-128.png"],

            ["https://cdn3.iconfinder.com/data/icons/vector-icons-15/96/715-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-19/96/936-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-13/96/632-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-4/96/158-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-8/96/388-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-4/96/159-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-7/96/339-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-1/96/46-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-20/96/975-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-1/96/22-128.png",
             "https://cdn3.iconfinder.com/data/icons/vector-icons-19/96/935-128.png"],

            ["https://cdn4.iconfinder.com/data/icons/nature-and-ecology-colored-icons-vol-2/48/54-128.png",
             "https://cdn0.iconfinder.com/data/icons/sports-colored-icons-1/48/09-128.png",
             "https://cdn3.iconfinder.com/data/icons/electronics-3-7/48/113-128.png",
             "https://cdn3.iconfinder.com/data/icons/maps-and-navigation-colored-2/48/57-128.png",
             "https://cdn2.iconfinder.com/data/icons/food-vol-3-1/96/107-128.png",
             "https://cdn3.iconfinder.com/data/icons/electronics-1-6/48/22-128.png",
             "https://cdn4.iconfinder.com/data/icons/office-vol-1-1/48/17-128.png",
             "https://cdn3.iconfinder.com/data/icons/hotel-and-restaurant-volume-2-2/48/98-128.png",
             "https://cdn0.iconfinder.com/data/icons/sports-colored-icons-2/48/90-128.png",
             "https://cdn3.iconfinder.com/data/icons/electronics-2-7/48/79-128.png",
             "https://cdn0.iconfinder.com/data/icons/sports-colored-icons-3/48/128-128.png"],

            ["https://cdn3.iconfinder.com/data/icons/science-volume-3-2/48/145-128.png",
             "https://cdn2.iconfinder.com/data/icons/sports-colored-icons-vol-1-1/128/09-128.png",
             "https://cdn3.iconfinder.com/data/icons/music-volume-2-2/48/63-128.png",
             "https://cdn3.iconfinder.com/data/icons/education-volume-1-1/48/02-128.png",
             "https://cdn3.iconfinder.com/data/icons/food-volume-3-1/48/109-128.png",
             "https://cdn3.iconfinder.com/data/icons/music-volume-2-2/48/67-128.png",
             "https://cdn3.iconfinder.com/data/icons/hotel-and-restaurant-volume-3-2/48/136-128.png",
             "https://cdn3.iconfinder.com/data/icons/transport-volume-1-1/48/47-128.png",
             "https://cdn2.iconfinder.com/data/icons/sports-colored-icons-vol-1-1/128/23-128.png",
             "https://cdn3.iconfinder.com/data/icons/music-volume-2-2/48/99-128.png",
             "https://cdn2.iconfinder.com/data/icons/sports-colored-icons-vol-1-1/128/01-128.png"]
            ];
    </script>
    <script type="text/javascript">
        $(document).ready(function () {

            $("#picker").spectrum({
                color: "#4285F4",
                showInput: true,
                className: "full-spectrum",
                showInitial: true,
                showPalette: true,
                showSelectionPalette: true,
                maxSelectionSize: 10,
                preferredFormat: "hex",
                localStorageKey: "spectrum.demo",
                move: function (color) {
                    changeColor(color.toHexString());
                },
                show: function () {

                },
                beforeShow: function () {

                },
                hide: function () {

                },
                change: function (color) {
                    changeColor(color.toHexString());
                },
                palette: [
                    ["rgb(0, 0, 0)", "rgb(67, 67, 67)", "rgb(102, 102, 102)",
                    "rgb(204, 204, 204)", "rgb(217, 217, 217)", "rgb(255, 255, 255)"],
                    ["rgb(152, 0, 0)", "rgb(255, 0, 0)", "rgb(255, 153, 0)", "rgb(255, 255, 0)", "rgb(0, 255, 0)",
                    "rgb(0, 255, 255)", "rgb(74, 134, 232)", "rgb(0, 0, 255)", "rgb(153, 0, 255)", "rgb(255, 0, 255)"],
                    ["rgb(230, 184, 175)", "rgb(244, 204, 204)", "rgb(252, 229, 205)", "rgb(255, 242, 204)", "rgb(217, 234, 211)",
                    "rgb(208, 224, 227)", "rgb(201, 218, 248)", "rgb(207, 226, 243)", "rgb(217, 210, 233)", "rgb(234, 209, 220)",
                    "rgb(221, 126, 107)", "rgb(234, 153, 153)", "rgb(249, 203, 156)", "rgb(255, 229, 153)", "rgb(182, 215, 168)",
                    "rgb(162, 196, 201)", "rgb(164, 194, 244)", "rgb(159, 197, 232)", "rgb(180, 167, 214)", "rgb(213, 166, 189)",
                    "rgb(204, 65, 37)", "rgb(224, 102, 102)", "rgb(246, 178, 107)", "rgb(255, 217, 102)", "rgb(147, 196, 125)",
                    "rgb(118, 165, 175)", "rgb(109, 158, 235)", "rgb(111, 168, 220)", "rgb(142, 124, 195)", "rgb(194, 123, 160)",
                    "rgb(166, 28, 0)", "rgb(204, 0, 0)", "rgb(230, 145, 56)", "rgb(241, 194, 50)", "rgb(106, 168, 79)",
                    "rgb(69, 129, 142)", "rgb(60, 120, 216)", "rgb(61, 133, 198)", "rgb(103, 78, 167)", "rgb(166, 77, 121)",
                    "rgb(91, 15, 0)", "rgb(102, 0, 0)", "rgb(120, 63, 4)", "rgb(127, 96, 0)", "rgb(39, 78, 19)", "rgb(12, 52, 61)",
                    "rgb(28, 69, 135)", "rgb(7, 55, 99)", "rgb(32, 18, 77)", "rgb(76, 17, 48)", "rgb(0,51,102)", "rgb(242, 122, 33)",
                    "rgb(255, 102, 0)", "rgb(128, 0, 0)", "rgb(0, 128, 128)"]
                ]
            });

            var iconList = $(".icon");
            for (var i = 0; i < 15; i++) {
                var imageDiv = $(iconList[i]).find(".iconImages");
                var html = "";
                for (var j = 4; j < 10; j++) {
                    var index = i + 1;
                    if (index > 10)
                        index++;
                    var src = "../Img/Icons/" + "icon" + index + j + ".png";
                    html += "<img src='" + src + "'/>";
                }
                imageDiv.html(html);
            }
        });

        function changeColor(colorHex) {
            $(".header").css("background", colorHex);
            $("#addBtn").css("background", colorHex);
            $("#appLogo").css("background", colorHex);
        }

        function changeIcons(index) {
            var events = $(".event");
            for (var i = 0; i < events.length; i++) {
                var iconIdx = i + 1;
                var src = "../Img/Icons/" + "icon" + index + iconIdx + ".png";
                $(events[i]).find("img").attr("src", src);
            }
        }
    </script>
    <style>
        .form {
            min-width: 1000px;
            position: relative;
        }
        #iPhone {
            position: absolute;
            z-index: 0;
            top: -1px;
            width: 365px;
            height: 646px;
            left: 57px;
        }
        #phoneContent {
            position: absolute;
            top: 70px;
            width: 320px;
            height: 500px;
            left: 80px;
            z-index: 10;
        }
        .header, .content, #addBtn {
            position: absolute;
        }
        .content {
            overflow-x: hidden;
            padding: 50px 0 80px;
        }
        #addBtn {
            bottom: inherit;
            top: 428px;
            left: 160px;
        }
        #addBtn:hover {
            cursor: inherit;
        }
        ::-webkit-scrollbar { 
            display: none; 
        }
        .homeList .name, .homeList .day {
            font-size: 16px;
            line-height: 20px;
        }
        .homeList > img {
            border-radius: 0;
        }
        #colorPickerHeader {
            position: absolute;
            top: 30px;
            left: 630px;
            font-size: 24px;
            font-weight: bold;
        }
        #colorPickerContainer {
            position: absolute;
            top: 64px;
            left: 674px;
        }
        #appLogo {
            position: absolute;
            top: 12px;
            left: 448px;
            background: #4285F4;
            border-radius: 22px;
        }
        #appLogo img{
            height: 120px;
            width: 120px;
            margin: 12px 12px 8px;
        }
        #iconList {
            position: absolute;
            top: 163px;
            left: 448px;
            right: 15px;
        }
        #iconListHeader {
            position: absolute;
            top: 127px;
            left: 630px;
            font-size: 24px;
            font-weight: bold
        }
        .icon {
            float: left;
            border: 2px solid white;
            border-radius: 5px;
        }
        .icon:hover {
            border: 2px solid #999;
            cursor: pointer;
        }
        .iconHeader {
            width: 210px;
            text-align: center;
            margin:6px 0 0;
            padding: 0;
        }
        .icon img {
            width: 210px;
        }
        .iconImages {
            width: 210px;
            height: 176px;
        }
        .iconImages img {
            width: 60px;
            margin: 0 5px 10px;
        }

    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="form">
        <img id="iPhone" src="../Img/iPhone.png" />
        <div id="phoneContent">
            <div class="header">
                <div>
                    <img id="menuBtn" src="/Img/whitemenu.png" />
                    <img class="title" src="/Img/powwowtitle.png" />
                    <img id="groupsBtn" src="/Img/whitegroup.png" />
                </div>
            </div>
            <div class="content">
                <div id="contentResults">
                    <div class="dayHeader">
                        <div></div>
                        <div>Today</div>
                    </div>
                    <div class="homeList event first">
                        <img src="../Img/face0.png">
                        <div class="name">Zilker Chill Day</div>
                        <div class="day">2:00 PM</div>
                    </div>
                    <div class="homeList event">
                        <img src="../Img/face1.png">
                        <div class="name">Bowling Afternoon</div>
                        <div class="day">4:00 PM</div>
                    </div>
                    <div class="homeList event last">
                        <img src="../Img/face2.png">
                        <div class="name">Jam Session</div>
                        <div class="day">7:00 PM</div>
                    </div>
                    <div class="dayHeader">
                        <div></div>
                        <div>Tomorrow</div>
                    </div>
                    <div class="homeList event first">
                        <img src="../Img/face3.png">
                        <div class="name">Study Group</div>
                        <div class="day">6:00 PM</div>
                    </div>
                    <div class="homeList event">
                        <img src="../Img/face4.png">
                        <div class="name">Party</div>
                        <div class="day">10:00 PM</div>
                    </div>
                    <div class="homeList event last">
                        <img src="../Img/face5.png">
                        <div class="name">Feshmoon X spectrum presents: DJ PAYPAL</div>
                        <div class="day">10:00 PM</div>
                    </div>
                    <div class="dayHeader">
                        <div></div>
                        <div>Saturday, Feb 6</div>
                    </div>
                    <div class="homeList event first">
                        <img src="../Img/face7.png">
                        <div class="name">Voter registration</div>
                        <div class="day">10:00 AM</div>
                    </div>
                    <div class="homeList event">
                        <img src="../Img/face6.png">
                        <div class="name">Horsepower on the Hilltop</div>
                        <div class="day">12:00 PM</div>
                    </div>
                    <div class="homeList event">
                        <img src="../Img/face2.png">
                        <div class="name">SEU RUGBY GAME</div>
                        <div class="day">7:00 PM</div>
                    </div>
                    <div class="homeList event">
                        <img src="../Img/face0.png">
                        <div class="name">Incendiary: The Willingham Case Movie Screening</div>
                        <div class="day">7:30 PM</div>
                    </div>
                    <div class="homeList event last">
                        <img src="../Img/face1.png">
                        <div class="name">Men and Women Basketball double header v's. UTPB</div>
                        <div class="day">8:00 PM</div>
                    </div>
                </div>
            </div>
            <div id="addBtn"><img src="../Img/plus.png" /></div>
        </div>
        <div id="appLogo">
            <img src="../Img/whitelogo.png" />
        </div>
        <div id="colorPickerHeader">
            Pick the Color
        </div>
        <div id="colorPickerContainer">
            <input type='text' id="picker"/>
        </div>
        <div id="iconListHeader">
            Pick the Icons
        </div>
        <div id="iconList">
            <div class="icon" onclick="changeIcons(1);">
                <div class="iconHeader">Icons #1</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(2);">
                <div class="iconHeader">Icons #2</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(3);">
                <div class="iconHeader">Icons #3</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(4);">
                <div class="iconHeader">Icons #4</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(5);">
                <div class="iconHeader">Icons #5</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(6);">
                <div class="iconHeader">Icons #6</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(7);">
                <div class="iconHeader">Icons #7</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(8);">
                <div class="iconHeader">Icons #8</div>
                <div class="iconImages"></div>
            </div>  
            <div class="icon" onclick="changeIcons(9);">
                <div class="iconHeader">Icons #9</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(10);">
                <div class="iconHeader">Icons #10</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(12);">
                <div class="iconHeader">Icons #11</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(13);">
                <div class="iconHeader">Icons #12</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(14);">
                <div class="iconHeader">Icons #13</div>
                <div class="iconImages"></div>
            </div>
            <div class="icon" onclick="changeIcons(15);">
                <div class="iconHeader">Icons #14</div>
                <div class="iconImages"></div>
            </div>
        </div>
        </div>
    </form>
</body>
</html>


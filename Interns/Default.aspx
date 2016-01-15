<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="Interns_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="" />
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <style>
        body {
            font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
        }
        a {
            color:#1a0dab;
            text-decoration: none;
            line-height: 24px;
            font-size: 16px;
        }
        a:hover {
            text-decoration: underline;
            cursor: pointer;
        }
        #content {
            margin: 20px;
        }
        tr.header {
            color: white;
            background-color: #1a0dab;
        }
        tr.even {
            background-color: #f1f1f1;
        }
        .hide {
            display: none;
        }
    </style>
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script type="text/javascript">

        $(document).ready(function () {

            var success = function (results) {
                $("#content").html(results);
            };
            Post("GetInternHtml", {}, success);

            $("#content").on("click", "td a", function (e) {
                if ($(e.target).closest("td").hasClass("details"))
                    return;

                var tr = $(e.target).closest("tr");
                $(tr).find(".details").toggleClass("hide");
            });
        });

    </script>

</head>
<body>
    <form id="form1" runat="server">
        <div id="content"></div>

    </form>
</body>
</html>


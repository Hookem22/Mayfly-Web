<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="Meetup_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Pow Wow</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"/>
    <meta name="description" content="Pow Wow allows people to spontaneously create and recruit for activities, interests, and sports around them today." />
    <link rel="icon" type="image/png" href="/img/favicon.png" />
    <script src="/Scripts/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/Scripts/Helpers.js" type="text/javascript"></script>
    <script type="text/javascript">
        var meetupTokens;

        $(document).ready(function () {
            var codeParam = getParameterByName("code");
            if (codeParam && !meetupTokens) {
                Post("AuthorizeMeetup", { code: codeParam }, AuthorizationReturn);
            }
        });

        function AuthorizationReturn(dict) {
            meetupTokens = dict;
        }

    </script>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <a href="https://secure.meetup.com/oauth2/authorize?client_id=2tm7voh0nq1i3q32sjb6r94mj0&response_type=code&redirect_uri=http://localhost:49542/Meetup">Sign in with Meetup</a>
    </div>
    </form>
</body>
</html>

World Wide Connect helps foreigner students in Germany - Brandenburg. 

Create a topic and get help at WWC!

🎉 What is World Wide Connect?
World Wide Conncetion is an application that helps international students arriving in Brandenburg that face numerous practical obstacles navigating daily life.

Features

🔒 Logins Required so we can keep the community safe.

💸 Free for Everyone.
World Wide Connect is completely free to use.

📱 Perfect for Small Screens.
Designed for mobile devices screens for your everyday use.

2️⃣ World Wide Connect users can chat in real-time with other uses to solve issues together.

📷 World Wide Connect has a QR Code Scanner that helps the users scan our QR Codes around the city and get instant help.

🎯 Get Started
Create an account.
Setup your profile.
Heav over to our Scan page and Scan one of our QR Codes near by.
If you do not have a QR Code near by, search for the desired topic or create your own.
Quick, Easy, and Free!

📳 Turn your notifications on
You can choose wheter or not you receive notifications from a desired topic.

🤝 Contributing
World Wide Connection is an application that wants to help the community. Here’s how you can help as well:

Look through existing topics where people share their issues, if you have a practical way to help them do not exitate to message!
If you do not have a problem, you might have a tip that might be helpfull to other students, do not forget to share it!

❤️ Support
If you love World Wide Connect, do not forget to share it with your friends or new students!

_______________________________________________________________________________________________________________________________________________


📃 APIs used in this project:

Firebase:
    
    https://firebase.google.com/?hl=pt-br

Google Sign-in:
    
    https://developers.google.com/identity/sign-in/web/sign-in?hl=pt-br

Firebase Authentication API:

    -auth_service.dart;
    -login_page.dart;
    -register_page.dart;

Google Sign-In API:

    -landing_page.dart;

Cloud Firestore API:

    -database_service.dart;
    -home_page.dart;
    -notifications_page.dart;

Firebase Cloud Messaging (FCM) API:

    -main.dart;
    -database_service.dart;

We also used some native APIs from the devices themselves:

    -mobile_scanner;
    -url_launcher;
    -flutter/services;

______________________________________________________________________________________________


📘 Library used for our fonts:
    
    -google_fonts package;

This is because we are using two specific fonts open source fonts from Google:

    -Montserrat;
    -AR One Sans;

______________________________________________________________________________________________


📒 Library needed to generate the QR Code and how to install it:

    https://pypi.org/project/qrcode/

os is already installed with python.
In case you do not have python installed, run the following in your terminal:

    Windows: sudo apt install python3
    Linux/macOS: brew install python

To install the qrcode library, run in terminal:
    
    pip install qrcode[pil]

______________________________________________________________________________________________


🚫 Library of bad words:

    https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words

Took all the files from the library, put them at: /lib/assets/word-library.
Used our GoodBehaviorService function to detect the words being used on our application.

______________________________________________________________________________________________

📷 Where did we got our pictures from:

    -https://www.freepik.com;
    -https://www.istockphoto.com;
    -https://www.flaticon.com;
    -Personally taken photos;
    -Wikipedia;

______________________________________________________________________________________________

📥 How did we converted the icon pack from figma to our application:

We exported every single icon used in our application as SVG:

    -Profile icon;
    -Search icon;
    -Scan icon;
    -Add icon;
    -Home icon;
    -bell icon;
    -arrow icon;

we used the icons just like an image.





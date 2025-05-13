@echo off
echo Fixing FlutterLocalNotificationsPlugin.java...
set FILE_PATH=C:\Users\HFCS\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_local_notifications-16.3.3\android\src\main\java\com\dexterous\flutterlocalnotifications\FlutterLocalNotificationsPlugin.java
set TEMP_FILE=%TEMP%\FlutterLocalNotificationsPlugin.java.tmp

type %FILE_PATH% > %TEMP_FILE%

powershell -Command "(Get-Content %TEMP_FILE%) -replace 'bigPictureStyle\.bigLargeIcon\\\\\\((Bitmap\\) null\\\\\\);', 'bigPictureStyle.bigLargeIcon((Bitmap) null);' | Set-Content %FILE_PATH%"

echo Fix completed.

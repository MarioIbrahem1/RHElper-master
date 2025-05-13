$filePath = "C:\Users\HFCS\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_local_notifications-16.3.3\android\src\main\java\com\dexterous\flutterlocalnotifications\FlutterLocalNotificationsPlugin.java"

# Read the file content
$content = Get-Content -Path $filePath -Raw

# Replace the problematic line
$fixedContent = $content -replace 'bigPictureStyle\.bigLargeIcon\\((Bitmap) null\\);', 'bigPictureStyle.bigLargeIcon((Bitmap) null);'

# Write the fixed content back to the file
Set-Content -Path $filePath -Value $fixedContent

Write-Host "Fix completed."

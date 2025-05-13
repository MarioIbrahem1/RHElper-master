$filePath = "FlutterLocalNotificationsPlugin.java"
$content = Get-Content -Path $filePath -Raw
$content = $content -replace 'bigPictureStyle\.bigLargeIcon\\\\((Bitmap) null\\\\);', 'bigPictureStyle.bigLargeIcon((Bitmap) null);'
Set-Content -Path $filePath -Value $content
Write-Host "Fix completed."

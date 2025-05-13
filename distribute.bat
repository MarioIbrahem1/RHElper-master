@echo off
echo ===== Road Helper App Firebase Distribution Script =====
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Node.js is not installed. Please install Node.js from https://nodejs.org/
    exit /b 1
)

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Firebase CLI is not installed. Installing now...
    call npm install -g firebase-tools
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to install Firebase CLI. Please install it manually with: npm install -g firebase-tools
        exit /b 1
    )
)

REM Login to Firebase if not already logged in
echo Logging in to Firebase...
firebase login --interactive

REM Clean the project
echo Cleaning project...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build the APK
echo Building APK...
flutter build apk --release

echo.
echo ===== Build Complete =====
echo.
echo APK location: build\app\outputs\apk\release\app-release.apk
echo.
echo Distributing to Firebase App Distribution...
cd android
call gradlew.bat appDistributionUploadRelease

echo.
echo ===== Distribution Complete =====
echo.
echo Your app has been uploaded to Firebase App Distribution.
echo Users in the "testers" group will receive an email to download the app.

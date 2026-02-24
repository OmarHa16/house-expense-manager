@echo off
echo ==========================================
echo House Expense App - Render Deployment Script
echo ==========================================
echo.

REM Step 1: Update API URL
echo Step 1: Checking API configuration...
echo.
echo IMPORTANT: Before deploying, you need to:
echo 1. Sign up at https://render.com
echo 2. Create a new Web Service
echo 3. Get your app URL (e.g., https://house-expense.onrender.com)
echo 4. Update flutter_app/lib/services/api_service.dart
echo.
echo Open api_service.dart and uncomment:
echo   static const String productionUrl = 'https://YOUR-APP.onrender.com';
echo.
pause

REM Step 2: Build Flutter
echo.
echo Step 2: Building Flutter web app...
cd flutter_app
call flutter build web --release
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)
echo Build successful!
cd ..

REM Step 3: Copy to backend
echo.
echo Step 3: Copying build files to backend...
if exist backend\public rmdir /S /Q backend\public
xcopy /E /I /Y flutter_app\build\web backend\public
echo Files copied!

REM Step 4: Git commit and push
echo.
echo Step 4: Preparing for deployment...
echo.
echo To deploy to Render:
echo 1. Push this code to GitHub
echo 2. Connect your GitHub repo to Render
echo 3. Follow instructions in DEPLOYMENT.md
echo.
echo Would you like to create a git commit now? (Y/N)
set /p createCommit=
if /I "%createCommit%"=="Y" (
    git add .
    git commit -m "Prepare for production deployment"
    echo.
    echo Commit created! Now push to GitHub:
    echo   git push origin main
)

echo.
echo ==========================================
echo DEPLOYMENT PREPARATION COMPLETE!
echo ==========================================
echo.
echo Next steps:
echo 1. Update api_service.dart with your Render URL
echo 2. Push code to GitHub
echo 3. Follow DEPLOYMENT.md for Render setup
echo.
echo Your app will be available at:
echo   https://YOUR-APP.onrender.com
echo.
pause

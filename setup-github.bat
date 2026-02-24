@echo off
echo ==========================================
echo GitHub Repository Setup Script
echo ==========================================
echo.

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed!
    echo Please download and install Git from:
    echo https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

echo Git is installed ✓
echo.

REM Initialize git if not already done
if not exist .git (
    echo Step 1: Initializing Git repository...
    git init
    echo Git repository initialized ✓
) else (
    echo Git already initialized ✓
)
echo.

REM Create root .gitignore
echo Step 2: Creating .gitignore...
(
echo # Dependencies
echo backend/node_modules/
echo flutter_app/.dart_tool/
echo flutter_app/.flutter-plugins
echo flutter_app/.flutter-plugins-dependencies
echo flutter_app/.packages
echo flutter_app/build/
echo flutter_app/ios/Pods/
echo flutter_app/android/.gradle/
echo flutter_app/android/app/debug/
echo flutter_app/android/app/profile/
echo flutter_app/android/app/release/
echo.
echo # Database
echo backend/*.db
echo backend/*.db-journal
echo.
echo # Environment
echo backend/.env
echo .env
echo.
echo # IDE
echo .vscode/
echo .idea/
echo *.swp
echo *.swo
echo.
echo # OS
echo .DS_Store
echo Thumbs.db
echo.
echo # Logs
echo npm-debug.log*
echo yarn-debug.log*
echo yarn-error.log*
) > .gitignore
echo .gitignore created ✓
echo.

REM Stage files
echo Step 3: Staging files...
git add .
echo Files staged ✓
echo.

REM Check if already committed
git log --oneline -1 >nul 2>&1
if errorlevel 1 (
    echo Step 4: Creating initial commit...
    git commit -m "Initial commit: House Expense Manager app with Flutter frontend and Node.js backend"
    echo Initial commit created ✓
) else (
    echo Commit already exists, skipping...
)
echo.

REM Check remote
git remote -v >nul 2>&1
if errorlevel 1 (
    echo.
    echo ==========================================
    echo NEXT STEPS: Connect to GitHub
    echo ==========================================
    echo.
    echo 1. Go to https://github.com/new
    echo.
    echo 2. Create a new repository:
    echo    - Repository name: house-expense-manager
    echo    - Description: Shared house expense tracking app
    echo    - Choose Public or Private
    echo    - DO NOT check "Add a README"
    echo    - Click "Create repository"
    echo.
    echo 3. Run these commands (replace YOUR_USERNAME):
    echo.
    echo    git remote add origin https://github.com/YOUR_USERNAME/house-expense-manager.git
    echo    git branch -M main
    echo    git push -u origin main
    echo.
    echo ==========================================
) else (
    echo Remote already configured:
    git remote -v
    echo.
    echo To push to GitHub:
    echo    git push origin main
)

echo.
echo Setup complete! Check SETUP-GITHUB.md for more details.
echo.
pause

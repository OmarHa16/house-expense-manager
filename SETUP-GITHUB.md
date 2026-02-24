# 📦 GitHub Repository Setup Guide

## Prerequisites
- Git installed (download from https://git-scm.com/download/win)
- GitHub account (sign up at https://github.com)

---

## Option 1: Automatic Setup (Recommended)

### Step 1: Run the Setup Script
```bash
setup-github.bat
```

This script will:
1. Initialize git repository
2. Create proper .gitignore
3. Stage all files
4. Make initial commit
5. Guide you through pushing to GitHub

---

## Option 2: Manual Setup

### Step 1: Initialize Git
```bash
cd "c:/Users/OHass/Desktop/house app"
git init
```

### Step 2: Create .gitignore
Create `.gitignore` in the root:
```
# Dependencies
backend/node_modules/
flutter_app/.dart_tool/
flutter_app/.flutter-plugins
flutter_app/.flutter-plugins-dependencies
flutter_app/.packages
flutter_app/build/
flutter_app/ios/Pods/
flutter_app/android/.gradle/
flutter_app/android/app/debug/
flutter_app/android/app/profile/
flutter_app/android/app/release/

# Database
backend/*.db
backend/*.db-journal

# Environment
backend/.env
.env

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
```

### Step 3: Add Files and Commit
```bash
git add .
git commit -m "Initial commit: House Expense Manager app"
```

### Step 4: Create GitHub Repo
1. Go to https://github.com/new
2. **Repository name**: `house-expense-manager`
3. **Description**: `Shared house expense tracking app with Flutter frontend and Node.js backend`
4. **Public** or **Private** (your choice)
5. **DO NOT** initialize with README (we already have one)
6. Click **Create repository**

### Step 5: Connect and Push
```bash
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/house-expense-manager.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## ✅ Verify Setup

Check your repo is live:
```
https://github.com/YOUR_USERNAME/house-expense-manager
```

---

## 🚀 Next: Deploy to Render

Once on GitHub, follow **PRODUCTION-READY.md** to deploy to Render.com

The deployment will:
1. Connect to your GitHub repo
2. Auto-deploy when you push changes
3. Host your app for free

---

## 📝 Common Issues

### "git is not recognized"
Install Git: https://git-scm.com/download/win

### "Permission denied"
Use HTTPS or set up SSH keys:
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/house-expense-manager.git
```

### "Failed to push"
Pull first, then push:
```bash
git pull origin main --rebase
git push origin main

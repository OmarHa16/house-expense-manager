# 🚀 Production Deployment Guide

## Option 1: Render.com (Recommended - Free Tier with Persistent Disk)

### Step 1: Prepare Your Code

1. **Update API Base URL in Flutter App**
   Edit `flutter_app/lib/services/api_service.dart`:
   ```dart
   // Change from localhost to your Render URL
   static const String baseUrl = 'https://your-app-name.onrender.com/api';
   ```

2. **Rebuild Flutter Web**
   ```bash
   cd flutter_app
   flutter build web --release
   ```

3. **Copy build to backend**
   ```bash
   # Windows
   xcopy /E /I /Y flutter_app\build\web\* backend\public\
   
   # Or use PowerShell
   Copy-Item -Path flutter_app\build\web\* -Destination backend\public\ -Recurse -Force
   ```

### Step 2: Create Render Account & Deploy

1. **Sign up** at https://render.com (use GitHub account for easy integration)

2. **Create New Web Service**
   - Click "New +" → "Web Service"
   - Connect your GitHub repo or use "Deploy from existing repo"

3. **Configure Service**
   - **Name**: `house-expense-app`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

4. **Add Environment Variables**
   Click "Environment" tab and add:
   ```
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   NODE_ENV=production
   ```

5. **Enable Persistent Disk (IMPORTANT for SQLite)**
   - Click "Disks" tab
   - Click "Add Disk"
   - **Name**: `sqlite-data`
   - **Mount Path**: `/opt/render/project/src/data`
   - **Size**: 1 GB (Free tier max)
   
   Update `backend/database.js`:
   ```javascript
   const DB_PATH = process.env.NODE_ENV === 'production' 
     ? '/opt/render/project/src/data/house_expense.db'
     : path.join(__dirname, 'house_expense.db');
   ```

6. **Deploy**
   - Click "Create Web Service"
   - Wait for build to complete (2-3 minutes)

### Step 3: Initial Setup

1. **Access your app**: `https://your-app-name.onrender.com`

2. **Login with default admin**:
   - Username: `Omar`
   - Password: `admin123`

3. **Immediately change admin password** via the app

4. **Add other users** through Admin Panel

---

## Option 2: Railway.app (Alternative)

### Step 1: Prepare Code (same as above)

### Step 2: Deploy to Railway

1. **Sign up** at https://railway.app

2. **Create Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository

3. **Add Volume for SQLite**
   - Go to project settings
   - Add Volume: `/app/data`
   
   Update `backend/database.js`:
   ```javascript
   const DB_PATH = process.env.NODE_ENV === 'production'
     ? '/app/data/house_expense.db'
     : path.join(__dirname, 'house_expense.db');
   ```

4. **Add Environment Variables**
   ```
   JWT_SECRET=your-super-secret-jwt-key
   NODE_ENV=production
   ```

5. **Deploy**
   - Railway auto-deploys on git push

---

## Option 3: Fly.io (For Global Edge Deployment)

### Step 1: Install Fly CLI
```bash
# Windows (PowerShell)
iwr https://fly.io/install.ps1 -useb | iex
```

### Step 2: Initialize & Deploy
```bash
cd backend

# Login
fly auth login

# Create app
fly launch --name house-expense-app

# Create persistent volume
fly volumes create data --size 1

# Deploy
fly deploy
```

### Step 3: Update Database Path
```javascript
const DB_PATH = process.env.NODE_ENV === 'production'
  ? '/data/house_expense.db'
  : path.join(__dirname, 'house_expense.db');
```

---

## 🔐 Security Checklist

Before going live:

- [ ] Change default admin password (Omar/admin123)
- [ ] Set strong JWT_SECRET (32+ random characters)
- [ ] Enable HTTPS (automatic on Render/Railway/Fly)
- [ ] Remove test data
- [ ] Set up regular backups (export SQLite file weekly)

---

## 📱 Mobile App Build (Optional)

To build Android APK:

```bash
cd flutter_app

# Update API URL in api_service.dart first!
# static const String baseUrl = 'https://your-app.onrender.com/api';

# Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

Distribute APK to house members via:
- Email
- WhatsApp
- Google Drive
- Firebase App Distribution

---

## 🔄 Backup & Restore

### Backup SQLite Database
```bash
# On Render (via Shell tab)
sqlite3 /opt/render/project/src/data/house_expense.db ".backup /opt/render/project/src/data/backup.db"

# Download via Render dashboard
```

### Restore Database
Upload backup file to disk location and restart service.

---

## 📊 Free Tier Limits

| Platform | Free Tier Limits |
|----------|-----------------|
| Render | 512 MB RAM, 0.1 CPU, 1 GB disk, spins down after 15 min idle |
| Railway | $5/month credit, 512 MB RAM, 1 GB disk |
| Fly.io | 256 MB RAM, 3 GB disk, 160 GB/month bandwidth |

**Note**: Render free tier spins down after 15 minutes of inactivity. First request after idle will take 30-60 seconds to wake up.

---

## 🆘 Troubleshooting

### App won't start
- Check logs in Render/Railway dashboard
- Verify JWT_SECRET is set
- Check database path exists

### Database locked error
- Restart the service
- Check if disk is properly mounted

### CORS errors
- Verify `cors` middleware is enabled in `server.js`

### Flutter can't connect
- Check API URL is correct (https, not http)
- Verify no trailing slash in baseUrl

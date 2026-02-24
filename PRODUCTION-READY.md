# ✅ Production Deployment - Quick Start

## 🎯 Recommended: Render.com (Free Tier)

### Step-by-Step Instructions:

#### 1. **Prepare Your App** (5 minutes)
```bash
# Run the deployment script
deploy-to-render.bat
```

Or manually:
1. Edit `flutter_app/lib/services/api_service.dart`
2. Uncomment and set your URL:
   ```dart
   static const String productionUrl = 'https://your-app-name.onrender.com';
   ```
3. Build Flutter: `flutter build web --release`
4. Copy files: `xcopy flutter_app\build\web\* backend\public\ /E /I /Y`

#### 2. **Create Render Account** (2 minutes)
- Go to https://render.com
- Sign up with GitHub
- Click "New +" → "Web Service"

#### 3. **Deploy** (3 minutes)
- Connect your GitHub repo
- **Name**: `house-expense-app`
- **Environment**: `Node`
- **Build Command**: `npm install`
- **Start Command**: `npm start`
- **Plan**: Free

#### 4. **Add Environment Variables**
```
JWT_SECRET=your-super-secret-key-min-32-chars-long
NODE_ENV=production
```

#### 5. **Enable Persistent Disk** (CRITICAL for SQLite)
- Click "Disks" tab
- **Name**: `sqlite-data`
- **Mount Path**: `/opt/render/project/src/data`
- **Size**: 1 GB

#### 6. **Done!** 🎉
Your app will be live at: `https://house-expense-app.onrender.com`

---

## 🔐 First Time Setup (After Deployment)

1. **Login with default admin:**
   - Username: `Omar`
   - Password: `admin123`

2. **Immediately change password:**
   - Go to menu → Change Password
   - Set a strong password

3. **Add house members:**
   - Go to Admin Panel
   - Add users (Saleem, Omran, etc.)
   - Give them the login credentials

---

## 📱 For Mobile App (APK)

If you want an Android app:

```bash
cd flutter_app

# IMPORTANT: Update api_service.dart first with your Render URL!

flutter build apk --release
```

APK location: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

Share this APK file with your house members via WhatsApp/Email.

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| App won't load | Check Render dashboard logs |
| Database errors | Verify disk is mounted at `/opt/render/project/src/data` |
| Can't login | Reset password using `node backend/reset-password.js` locally |
| CORS errors | Backend CORS is already configured, check URL |
| First load slow | Render free tier spins down; first request wakes it up (30-60 sec) |

---

## 📊 Free Tier Limits (Render)

- **RAM**: 512 MB
- **CPU**: 0.1 (shared)
- **Disk**: 1 GB (persistent)
- **Sleep**: After 15 min idle (wakes on next request)

---

## 🔄 Backup Your Data

Weekly backup recommended:
1. Go to Render Dashboard → Shell
2. Run: `sqlite3 /opt/render/project/src/data/house_expense.db ".backup backup.db"`
3. Download `backup.db` from Disks tab

---

## 🚀 Alternative Platforms

- **Railway.app**: Similar process, $5/month credit
- **Fly.io**: Global edge deployment, 256 MB RAM free
- **Heroku**: No longer free, paid only

See `DEPLOYMENT.md` for detailed instructions on all platforms.

---

## 📞 Need Help?

1. Check `DEPLOYMENT.md` for detailed instructions
2. Check Render logs in dashboard
3. Ensure JWT_SECRET is set
4. Verify database path in `backend/database.js`

---

**Your app is ready for production!** 🎊

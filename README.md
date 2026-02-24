# 🏠 Shared House Expense Manager

A full-stack application for tracking and splitting shared expenses among house residents. Built with **Node.js/Express** backend and **Flutter** frontend.

## ✨ Features

### Core Functionality
- **User Authentication**: Secure login with JWT tokens and password hashing
- **Expense Tracking**: Add invoices with multiple items and consumers
- **Smart Splitting**: Automatic calculation of who owes what
- **Balance Management**: Real-time balance updates and debt tracking
- **Admin Controls**: User management, invoice deletion, and promotion features

### Advanced Features
- **Undo System**: 10-second window to undo deletions
- **Item Reusability**: Master item list for quick invoice creation
- **Multi-platform**: Works on Android, iOS, and Web
- **Offline Persistence**: Session management with shared preferences
- **Material Design**: Modern, intuitive UI

## 🚀 Quick Start

### Prerequisites
- Node.js (>= 16.x)
- Flutter SDK (>= 3.0.0)
- Android Studio / Xcode (for mobile)

### Backend Setup

```bash
cd backend
npm install
npm start
```

Server runs on `http://localhost:3000`

### Flutter App Setup

```bash
cd flutter_app
flutter pub get
flutter run
```

## 📱 Default Login

- **Name**: `Omar`
- **Password**: `admin123`

## 🌐 Deployment

### Local Wi-Fi Access
1. Find your computer's IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Update Flutter app's `baseUrl` to `http://YOUR_IP:3000`
3. Access from any device on the same network

### Free Hosting (Render.com)
1. Push code to GitHub
2. Connect repository to [Render.com](https://render.com)
3. Set build: `npm install`, start: `npm start`
4. Update Flutter app with your Render URL

## 📁 Project Structure

```
house-app/
├── backend/              # Node.js API
│   ├── server.js         # Entry point
│   ├── database.js       # SQLite setup
│   ├── middleware/       # Auth middleware
│   └── routes/           # API endpoints
│
├── flutter_app/          # Flutter application
│   ├── lib/
│   │   ├── models/       # Data models
│   │   ├── providers/   # State management
│   │   ├── screens/     # UI screens
│   │   └── services/    # API service
│   └── pubspec.yaml
│
└── README.md
```

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | User login |
| `/api/users` | GET/POST | List/Create users |
| `/api/items` | GET/POST | List/Create items |
| `/api/invoices` | GET/POST | List/Create invoices |
| `/api/balances` | GET | Get all balances |
| `/api/balances/me` | GET | Get my balance |

## 🛡️ Security

- ✅ Password hashing with bcrypt
- ✅ JWT token authentication
- ✅ Admin role verification
- ✅ Input validation
- ✅ SQL injection protection (parameterized queries)

## 📝 License

MIT License - feel free to use for personal or commercial projects!

## 🤝 Contributing

Contributions welcome! Please open an issue or pull request.

## 📧 Support

For issues or questions, please open a GitHub issue.

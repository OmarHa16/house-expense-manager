# House Expense Manager - Backend API

A Node.js/Express REST API with SQLite database for the House Expense Manager application.

## Features

- **RESTful API**: Clean, well-documented endpoints
- **JWT Authentication**: Secure token-based auth
- **SQLite Database**: Lightweight, file-based storage
- **Soft Deletes**: 10-second undo window for deletions
- **Expense Calculations**: Automatic balance and debt calculations
- **Admin Controls**: User management and privileged operations

## Quick Start

### Prerequisites

- Node.js (>= 16.x)
- npm or yarn

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the server:
   ```bash
   npm start
   ```

   For development with auto-reload:
   ```bash
   npm run dev
   ```

3. The server will start on `http://localhost:3000`

### Default Admin User

The server automatically creates an admin user on first run:

- **Name**: Omar
- **Password**: admin123

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with name and password |
| GET | `/api/auth/me` | Get current user info |

### Users (Admin only)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users` | List all users |
| POST | `/api/users` | Create new user |
| PUT | `/api/users/:id/promote` | Promote user to admin |
| DELETE | `/api/users/:id` | Delete user |

### Items
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/items` | List all items |
| POST | `/api/items` | Create new item |
| PUT | `/api/items/:id` | Update item |
| DELETE | `/api/items/:id` | Soft delete item (admin) |
| POST | `/api/items/:id/undo` | Undo delete (within 10s) |

### Invoices
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/invoices` | List all invoices |
| GET | `/api/invoices/:id` | Get invoice details |
| POST | `/api/invoices` | Create new invoice |
| PUT | `/api/invoices/:id/done` | Mark as done (admin) |
| DELETE | `/api/invoices/:id` | Soft delete (admin) |
| POST | `/api/invoices/:id/undo` | Undo delete (within 10s) |

### Balances
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/balances` | Get all user balances |
| GET | `/api/balances/me` | Get current user's balance |
| GET | `/api/balances/summary` | Get balance summary |

## Running on Local Network

To access from other devices on your Wi-Fi:

1. Find your computer's local IP:
   - Windows: `ipconfig`
   - Mac/Linux: `ifconfig` or `ip addr`

2. Start the server on all interfaces:
   ```bash
   # The server already binds to 0.0.0.0 by default
   npm start
   ```

3. Access from other devices using:
   ```
   http://YOUR_LOCAL_IP:3000
   ```

## Free Hosting Deployment

### Option 1: Render.com (Recommended)

1. Create a free account at [render.com](https://render.com)
2. Create a new Web Service
3. Connect your GitHub repository
4. Set build command: `npm install`
5. Set start command: `npm start`
6. Deploy!

The free tier includes:
- 512 MB RAM
- 0.1 CPU
- 750 hours/month
- Automatic HTTPS

### Option 2: Railway.app

1. Create account at [railway.app](https://railway.app)
2. Create new project from GitHub
3. Add environment variables if needed
4. Deploy automatically

### Option 3: Fly.io

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Launch
fly launch

# Deploy
fly deploy
```

## Environment Variables

Create a `.env` file (optional):

```env
PORT=3000
JWT_SECRET=your-secret-key-here
NODE_ENV=production
```

## Database

The SQLite database (`house_expense.db`) is created automatically. It includes:

- **users**: User accounts with hashed passwords
- **items**: Master list of reusable items
- **invoices**: Invoice headers
- **invoice_items**: Individual line items
- **payments**: Who paid what

## Project Structure

```
backend/
├── server.js           # Main entry point
├── database.js         # Database setup and helpers
├── package.json        # Dependencies
├── middleware/
│   └── auth.js         # JWT authentication
└── routes/
    ├── auth.js         # Auth endpoints
    ├── users.js        # User management
    ├── items.js        # Item CRUD
    ├── invoices.js     # Invoice management
    └── balances.js     # Balance calculations
```

## Security Notes

- Passwords are hashed with bcrypt (10 rounds)
- JWT tokens expire after 7 days
- All sensitive routes require authentication
- Admin routes check for admin flag
- CORS enabled for all origins (configure for production)

## License

MIT

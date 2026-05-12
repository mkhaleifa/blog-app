# 📝 BlogApp — Full Stack Blog Platform

A full-stack blog application built with **React**, **Node.js**, **Express**, and **MongoDB**. Features JWT authentication, full CRUD for articles, likes, pagination, and search.

## 🚀 Live Demo

- **Frontend:** [your-app.vercel.app](#) ← replace with your Vercel link
- **Backend API:** [your-api.railway.app](#) ← replace with your Railway link

---

## ✨ Features

- 🔐 JWT Authentication (register, login, protected routes)
- 📝 Full CRUD for blog posts (create, read, update, delete)
- 🔍 Search posts by title, content, and tags
- ❤️ Like / unlike posts
- 📄 Pagination
- 🏷️ Tag support
- 📊 Author dashboard with post stats (total, published, drafts)
- 🔒 Author-only edit & delete protection
- 📱 Fully responsive design

---

## 🛠️ Tech Stack

### Frontend
| Tech | Purpose |
|------|---------|
| React 18 + TypeScript | UI framework |
| Vite | Build tool |
| Tailwind CSS | Styling |
| React Router v6 | Client-side routing |
| TanStack Query | Server state & caching |
| Zustand | Auth state management |
| React Hook Form + Zod | Form validation |
| Axios | HTTP client |

### Backend
| Tech | Purpose |
|------|---------|
| Node.js + Express | REST API |
| TypeScript | Type safety |
| MongoDB + Mongoose | Database |
| JWT + bcryptjs | Authentication & password hashing |
| express-validator | Input validation |
| Morgan | HTTP request logging |

---

## 📁 Project Structure

```
blog-app/
├── backend/
│   └── src/
│       ├── config/         # MongoDB connection
│       ├── controllers/    # Route handlers (auth, posts)
│       ├── middleware/     # JWT auth middleware
│       ├── models/         # Mongoose schemas (User, Post)
│       └── routes/         # Express route definitions
└── frontend/
    └── src/
        ├── api/            # Axios API functions
        ├── components/     # Navbar, ProtectedRoute
        ├── pages/          # HomePage, PostPage, Dashboard, etc.
        ├── store/          # Zustand auth store
        └── types/          # TypeScript interfaces
```

---

## ⚙️ Getting Started

### Prerequisites
- Node.js 18+
- MongoDB — local install or free [MongoDB Atlas](https://www.mongodb.com/atlas) cluster

### 1. Clone the repo
```bash
git clone https://github.com/mkhaleifa/blog-app.git
cd blog-app
```

### 2. Set up the backend
```bash
cd backend
cp .env.example .env
```

Edit `backend/.env` and add your values:
```env
PORT=5000
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/blog-app?retryWrites=true&w=majority
JWT_SECRET=any_long_random_string_here
JWT_EXPIRES_IN=7d
NODE_ENV=development
```

```bash
npm install
npm run dev
```

You should see:
```
🚀 Server running on http://localhost:5000
✅ MongoDB connected successfully
```

### 3. Set up the frontend
```bash
# Open a new terminal
cd frontend
npm install
npm run dev
```

Open **http://localhost:5173** in your browser.

---

## 🔌 API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login |
| GET | `/api/auth/me` | Get current user (auth required) |

### Posts
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/posts` | — | List all published posts |
| GET | `/api/posts/:slug` | — | Get a single post |
| GET | `/api/posts/my` | ✅ | Get current user's posts |
| POST | `/api/posts` | ✅ | Create a new post |
| PUT | `/api/posts/:id` | ✅ | Update a post |
| DELETE | `/api/posts/:id` | ✅ | Delete a post |
| POST | `/api/posts/:id/like` | ✅ | Toggle like on a post |

### Health Check
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Check if API is running |

---

## 📸 Screenshots

> Add screenshots of your app here after deploying

---

## 🚢 Deployment

### Backend → Railway
1. Push code to GitHub
2. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub
3. Add environment variables (same as `.env`)
4. Deploy ✅

### Frontend → Vercel
1. Go to [vercel.com](https://vercel.com) → New Project → Import from GitHub
2. Set root directory to `frontend`
3. Deploy ✅

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first.

---

## 👨‍💻 Author

**Mohamed Khaleifa** — Full Stack Developer

[![GitHub](https://img.shields.io/badge/GitHub-mkhaleifa-181717?style=flat&logo=github)](https://github.com/mkhaleifa)
[![Portfolio](https://img.shields.io/badge/Portfolio-Visit-0A66C2?style=flat&logo=vercel)](https://mk-portfolio-jade.vercel.app)

---

## 📄 License

[MIT](LICENSE)

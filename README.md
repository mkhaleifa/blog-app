# 📝 BlogApp — Full Stack Blog Platform

A full-stack blog application built with React, Node.js, Express, and MongoDB. Features JWT authentication, full CRUD for articles, likes, pagination, and search.

## 🚀 Live Demo

- **Frontend:** [your-app.vercel.app](#)
- **Backend API:** [your-api.railway.app](#)

---

## ✨ Features

- 🔐 JWT Authentication (register, login, protected routes)
- 📝 Full CRUD for blog posts (create, read, update, delete)
- 🔍 Search posts by title/content/tags
- ❤️ Like / unlike posts
- 📄 Pagination
- 🏷️ Tag filtering
- 📊 Author dashboard with post stats
- 🔒 Author-only edit/delete protection
- 📱 Responsive design

---

## 🛠️ Tech Stack

### Frontend
| Tech | Purpose |
|------|---------|
| React 18 + TypeScript | UI framework |
| Vite | Build tool |
| Tailwind CSS | Styling |
| React Router v6 | Client-side routing |
| TanStack Query | Server state management |
| Zustand | Client state (auth) |
| React Hook Form + Zod | Form validation |
| Axios | HTTP client |

### Backend
| Tech | Purpose |
|------|---------|
| Node.js + Express | REST API |
| TypeScript | Type safety |
| MongoDB + Mongoose | Database |
| JWT + bcryptjs | Authentication |
| express-validator | Input validation |
| Morgan | HTTP logging |

---

## 📁 Project Structure

```
blog-app/
├── backend/
│   └── src/
│       ├── config/       # DB connection
│       ├── controllers/  # Route handlers
│       ├── middleware/   # Auth middleware
│       ├── models/       # Mongoose schemas
│       └── routes/       # Express routes
└── frontend/
    └── src/
        ├── api/          # Axios API calls
        ├── components/   # Reusable UI
        ├── pages/        # Route pages
        ├── store/        # Zustand store
        └── types/        # TypeScript types
```

---

## ⚙️ Getting Started

### Prerequisites
- Node.js 18+
- MongoDB (local or [MongoDB Atlas](https://www.mongodb.com/atlas))

### 1. Clone the repo
```bash
git clone https://github.com/mkhaleifa/blog-app.git
cd blog-app
```

### 2. Set up the backend
```bash
cd backend
cp .env.example .env
# Edit .env with your MongoDB URI and JWT secret
npm install
npm run dev
```

### 3. Set up the frontend
```bash
cd frontend
npm install
npm run dev
```

Backend runs on `http://localhost:5000`  
Frontend runs on `http://localhost:5173`

---

## 🔌 API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| GET | `/api/auth/me` | Get current user |

### Posts
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/posts` | — | List published posts |
| GET | `/api/posts/:slug` | — | Get single post |
| GET | `/api/posts/my` | ✅ | Get my posts |
| POST | `/api/posts` | ✅ | Create post |
| PUT | `/api/posts/:id` | ✅ | Update post |
| DELETE | `/api/posts/:id` | ✅ | Delete post |
| POST | `/api/posts/:id/like` | ✅ | Toggle like |

---

## 🚢 Deployment

**Backend** → [Railway](https://railway.app) (free tier, supports Node.js + MongoDB)  
**Frontend** → [Vercel](https://vercel.com) (free tier, perfect for React/Vite)

---

## 👨‍💻 Author

**Mohamed Khaleifa** — Full Stack Developer  
[GitHub](https://github.com/mkhaleifa) · [Portfolio](https://mk-portfolio-jade.vercel.app)

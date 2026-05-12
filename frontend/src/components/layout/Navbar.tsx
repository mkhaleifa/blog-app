import { Link, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'

export default function Navbar() {
  const { isAuthenticated, user, logout } = useAuthStore()
  const navigate = useNavigate()

  const handleLogout = () => { logout(); navigate('/') }

  return (
    <nav className="border-b border-gray-200 bg-white sticky top-0 z-50">
      <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <Link to="/" className="text-xl font-semibold text-gray-900">📝 BlogApp</Link>
        <div className="flex items-center gap-4">
          <Link to="/" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Home</Link>
          {isAuthenticated ? (
            <>
              <Link to="/new" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">New Post</Link>
              <Link to="/dashboard" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Dashboard</Link>
              <span className="text-sm text-gray-500">Hi, {user?.name?.split(' ')[0]}</span>
              <button onClick={handleLogout} className="text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1.5 rounded-lg transition-colors">Logout</button>
            </>
          ) : (
            <>
              <Link to="/login" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Login</Link>
              <Link to="/register" className="text-sm bg-gray-900 hover:bg-gray-700 text-white px-3 py-1.5 rounded-lg transition-colors">Sign Up</Link>
            </>
          )}
        </div>
      </div>
    </nav>
  )
}

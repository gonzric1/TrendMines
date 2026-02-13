import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import HomePage from './pages/HomePage'
import SignalsPage from './pages/SignalsPage'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-background">
        <nav className="border-b">
          <div className="container mx-auto px-4 py-4">
            <div className="flex gap-6">
              <Link to="/" className="text-foreground hover:text-primary font-medium">
                Home
              </Link>
              <Link to="/signals" className="text-foreground hover:text-primary font-medium">
                Signals
              </Link>
            </div>
          </div>
        </nav>

        <main className="container mx-auto px-4 py-8">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/signals" element={<SignalsPage />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}

export default App

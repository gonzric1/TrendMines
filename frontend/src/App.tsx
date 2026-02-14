import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AppLayout } from './components/layout/AppLayout'
import HomePage from './pages/HomePage'
import SignalsPage from './pages/SignalsPage'
import PipelinePage from './pages/PipelinePage'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<AppLayout />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/signals" element={<SignalsPage />} />
          <Route path="/pipeline" element={<PipelinePage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App

import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AppLayout } from './components/layout/AppLayout'
import SignalsPage from './pages/SignalsPage'
import PipelinePage from './pages/PipelinePage'
import CulturalTokensPage from './pages/CulturalTokensPage'
import SettingsPage from './pages/SettingsPage'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<AppLayout />}>
          <Route path="/" element={<SignalsPage />} />
          <Route path="/signals" element={<SignalsPage />} />
          <Route path="/pipeline" element={<PipelinePage />} />
          <Route path="/tokens" element={<CulturalTokensPage />} />
          <Route path="/settings" element={<SettingsPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App

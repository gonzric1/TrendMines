import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import api, { type PaginatedResponse } from '@/lib/api'

interface TrendSignal {
  id: number
  source: string
  topic: string
  description: string
  momentum_score: number
  status: string
  first_seen: string
}

export default function SignalsPage() {
  const [signals, setSignals] = useState<TrendSignal[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchSignals = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<PaginatedResponse<TrendSignal>>('/trend_signals')
      setSignals(response.data.data)
    } catch (err) {
      setError('Failed to fetch signals. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchSignals()
  }, [])

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Trend Signals</h1>
          <p className="text-muted-foreground mt-1">
            Real-time trending topics from various sources
          </p>
        </div>
        <Button onClick={fetchSignals}>Refresh</Button>
      </div>

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading signals...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && signals.length === 0 && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">No signals found</p>
        </div>
      )}

      {!loading && !error && signals.length > 0 && (
        <div className="space-y-4">
          {signals.map((signal) => (
            <div key={signal.id} className="border rounded-lg p-6">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <span className="inline-block px-2 py-1 bg-primary/10 text-primary text-xs font-medium rounded mb-2">
                    {signal.source}
                  </span>
                  <h3 className="text-lg font-semibold">{signal.topic}</h3>
                </div>
                <div className="text-right">
                  <div className="text-2xl font-bold">{signal.momentum_score.toFixed(1)}</div>
                  <div className="text-xs text-muted-foreground">Momentum</div>
                </div>
              </div>
              <p className="text-sm text-muted-foreground">{signal.description}</p>
              <div className="mt-4 flex gap-2">
                <span className="text-xs px-2 py-1 bg-secondary rounded">
                  {signal.status}
                </span>
                <span className="text-xs text-muted-foreground">
                  First seen: {new Date(signal.first_seen).toLocaleDateString()}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

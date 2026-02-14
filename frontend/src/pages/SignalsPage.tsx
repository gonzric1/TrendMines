import { useEffect, useState, useCallback, useRef } from 'react'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'
import type { PaginatedResponse } from '@/lib/api'
import type { TrendSignal, SignalStatus } from '@/types/signal'
import { SignalCard } from '@/components/signals/SignalCard'
import { FilterToolbar } from '@/components/signals/FilterToolbar'
import type { SortField } from '@/components/signals/FilterToolbar'
import { PromoteToNicheDialog } from '@/components/signals/PromoteToNicheDialog'

export default function SignalsPage() {
  const [signals, setSignals] = useState<TrendSignal[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Filters
  const [selectedSources, setSelectedSources] = useState<string[]>([])
  const [selectedStatus, setSelectedStatus] = useState<SignalStatus | 'all'>('all')
  const [sortField, setSortField] = useState<SortField>('momentum_score')

  // Auto-refresh
  const [autoRefresh, setAutoRefresh] = useState(true)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // Promote dialog
  const [promoteSignal, setPromoteSignal] = useState<TrendSignal | null>(null)

  const fetchSignals = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      const params: Record<string, string> = {
        sort: `${sortField} DESC`,
      }
      if (selectedSources.length === 1) {
        params.source = selectedSources[0]
      }
      if (selectedStatus !== 'all') {
        params.status = selectedStatus
      }

      const response = await api.get<PaginatedResponse<TrendSignal>>(
        '/trend_signals',
        { params }
      )
      setSignals(response.data.data)
    } catch (err) {
      setError('Failed to fetch signals. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [sortField, selectedSources, selectedStatus])

  useEffect(() => {
    fetchSignals()
  }, [fetchSignals])

  // Auto-refresh interval
  useEffect(() => {
    if (autoRefresh) {
      intervalRef.current = setInterval(fetchSignals, 30000)
    }
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
        intervalRef.current = null
      }
    }
  }, [autoRefresh, fetchSignals])

  const handlePromoteSuccess = () => {
    setPromoteSignal(null)
    fetchSignals()
  }

  // Client-side multi-source filtering (API only supports single source)
  const filteredSignals =
    selectedSources.length > 1
      ? signals.filter((s) => selectedSources.includes(s.source))
      : signals

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Signal Radar</h1>
          <p className="text-muted-foreground mt-1">
            Real-time trending topics from various sources
          </p>
        </div>
        <div className="flex items-center gap-3">
          <label className="flex items-center gap-2 text-sm text-muted-foreground">
            <input
              type="checkbox"
              checked={autoRefresh}
              onChange={(e) => setAutoRefresh(e.target.checked)}
              className="rounded"
            />
            Auto-refresh
          </label>
          <Button onClick={fetchSignals}>Refresh</Button>
        </div>
      </div>

      <FilterToolbar
        selectedSources={selectedSources}
        onSourcesChange={setSelectedSources}
        selectedStatus={selectedStatus}
        onStatusChange={setSelectedStatus}
        sortField={sortField}
        onSortChange={setSortField}
      />

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

      {!loading && !error && filteredSignals.length === 0 && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">No signals found</p>
        </div>
      )}

      {!loading && !error && filteredSignals.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filteredSignals.map((signal) => (
            <SignalCard
              key={signal.id}
              signal={signal}
              onPromote={setPromoteSignal}
            />
          ))}
        </div>
      )}

      {promoteSignal && (
        <PromoteToNicheDialog
          signal={promoteSignal}
          onClose={() => setPromoteSignal(null)}
          onSuccess={handlePromoteSuccess}
        />
      )}
    </div>
  )
}

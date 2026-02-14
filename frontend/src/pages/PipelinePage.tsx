import { useEffect, useState, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'
import type { PaginatedResponse } from '@/lib/api'
import type { Niche, NicheStatus } from '@/types/niche'
import { KanbanBoard } from '@/components/pipeline/KanbanBoard'
import { NicheDetailPanel } from '@/components/pipeline/NicheDetailPanel'

export default function PipelinePage() {
  const [niches, setNiches] = useState<Niche[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedNiche, setSelectedNiche] = useState<Niche | null>(null)

  const fetchNiches = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<PaginatedResponse<Niche>>('/niches', {
        params: { per_page: 100 },
      })
      setNiches(response.data.data)
    } catch (err) {
      setError('Failed to fetch niches. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchNiches()
  }, [])

  const handleStatusChange = useCallback(
    async (nicheId: number, newStatus: NicheStatus) => {
      // Optimistic update
      setNiches((prev) =>
        prev.map((n) => (n.id === nicheId ? { ...n, status: newStatus } : n))
      )

      // Update selected niche if it's the one being moved
      setSelectedNiche((prev) =>
        prev && prev.id === nicheId ? { ...prev, status: newStatus } : prev
      )

      try {
        await api.patch(`/niches/${nicheId}`, { niche: { status: newStatus } })
      } catch (err) {
        console.error('Failed to update niche status:', err)
        // Revert on failure
        fetchNiches()
      }
    },
    []
  )

  const handleNicheClick = useCallback((niche: Niche) => {
    setSelectedNiche(niche)
  }, [])

  const handleClosePanel = useCallback(() => {
    setSelectedNiche(null)
  }, [])

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Niche Pipeline</h1>
          <p className="text-muted-foreground mt-1">
            Drag niches between stages to update their pipeline status
          </p>
        </div>
        <Button onClick={fetchNiches}>Refresh</Button>
      </div>

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading pipeline...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && niches.length === 0 && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">
            No niches in the pipeline yet. Create a niche to get started.
          </p>
        </div>
      )}

      {!loading && !error && niches.length > 0 && (
        <KanbanBoard
          niches={niches}
          onStatusChange={handleStatusChange}
          onNicheClick={handleNicheClick}
        />
      )}

      <NicheDetailPanel niche={selectedNiche} onClose={handleClosePanel} />
    </div>
  )
}

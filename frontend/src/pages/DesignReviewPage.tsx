import { useEffect, useState, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'
import type { PaginatedResponse } from '@/lib/api'
import type { Design, DesignStatus } from '@/types/design'
import { useKeyboardNavigation } from '@/hooks/useKeyboardNavigation'
import { DesignGrid } from '@/components/designs/DesignGrid'
import { DesignViewer } from '@/components/designs/DesignViewer'
import { ComparisonMode } from '@/components/designs/ComparisonMode'
import { RegenerateDialog } from '@/components/designs/RegenerateDialog'
import { ReviewProgress } from '@/components/designs/ReviewProgress'

type FilterTab = 'all' | DesignStatus

export default function DesignReviewPage() {
  const [designs, setDesigns] = useState<Design[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeFilter, setActiveFilter] = useState<FilterTab>('all')
  const [selectedIndex, setSelectedIndex] = useState(-1)
  const [showComparison, setShowComparison] = useState(false)
  const [showRegenerate, setShowRegenerate] = useState(false)

  const fetchDesigns = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<PaginatedResponse<Design>>('/designs', {
        params: { sort: 'created_at DESC' },
      })
      setDesigns(response.data.data)
    } catch (err) {
      setError('Failed to fetch designs. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchDesigns()
  }, [fetchDesigns])

  const filteredDesigns =
    activeFilter === 'all'
      ? designs
      : designs.filter((d) => d.status === activeFilter)

  const selectedDesign =
    selectedIndex >= 0 && selectedIndex < filteredDesigns.length
      ? filteredDesigns[selectedIndex]
      : null

  const viewerOpen = selectedDesign !== null

  const handleDesignClick = (design: Design) => {
    const idx = filteredDesigns.findIndex((d) => d.id === design.id)
    setSelectedIndex(idx)
    setShowComparison(false)
  }

  const handleApprove = useCallback(async () => {
    if (!selectedDesign) return
    try {
      await api.patch(`/designs/${selectedDesign.id}`, {
        design: { status: 'approved' },
      })
      setDesigns((prev) =>
        prev.map((d) =>
          d.id === selectedDesign.id ? { ...d, status: 'approved' } : d
        )
      )
    } catch (err) {
      console.error('Failed to approve design:', err)
    }
  }, [selectedDesign])

  const handleReject = useCallback(async () => {
    if (!selectedDesign) return
    try {
      await api.patch(`/designs/${selectedDesign.id}`, {
        design: { status: 'rejected' },
      })
      setDesigns((prev) =>
        prev.map((d) =>
          d.id === selectedDesign.id ? { ...d, status: 'rejected' } : d
        )
      )
    } catch (err) {
      console.error('Failed to reject design:', err)
    }
  }, [selectedDesign])

  const handleRegenerate = useCallback(() => {
    setShowRegenerate(true)
  }, [])

  const handleRegenerateConfirm = async (templateId?: number) => {
    if (!selectedDesign) return
    try {
      await api.post(`/designs/${selectedDesign.id}/regenerate`, {
        ...(templateId ? { template_id: templateId } : {}),
      })
      setShowRegenerate(false)
    } catch (err) {
      console.error('Failed to regenerate design:', err)
    }
  }

  const handleToggleCompare = useCallback(() => {
    setShowComparison((prev) => !prev)
  }, [])

  const handleCloseViewer = useCallback(() => {
    setSelectedIndex(-1)
    setShowComparison(false)
    setShowRegenerate(false)
  }, [])

  const handleNavigate = useCallback(
    (index: number) => {
      if (index >= 0 && index < filteredDesigns.length) {
        setSelectedIndex(index)
        setShowComparison(false)
      }
    },
    [filteredDesigns.length]
  )

  useKeyboardNavigation({
    designs: filteredDesigns,
    selectedIndex,
    onNavigate: handleNavigate,
    onApprove: handleApprove,
    onReject: handleReject,
    onRegenerate: handleRegenerate,
    onToggleCompare: handleToggleCompare,
    onClose: handleCloseViewer,
    enabled: viewerOpen && !showRegenerate,
  })

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Design Review</h1>
          <p className="text-muted-foreground mt-1">
            Review, approve, and manage generated designs
          </p>
        </div>
        <Button onClick={fetchDesigns}>Refresh</Button>
      </div>

      {!loading && !error && designs.length > 0 && (
        <ReviewProgress designs={designs} />
      )}

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading designs...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && (
        <DesignGrid
          designs={designs}
          activeFilter={activeFilter}
          onFilterChange={setActiveFilter}
          onDesignClick={handleDesignClick}
        />
      )}

      {viewerOpen && selectedDesign && !showComparison && (
        <DesignViewer
          design={selectedDesign}
          hasPrev={selectedIndex > 0}
          hasNext={selectedIndex < filteredDesigns.length - 1}
          onPrev={() => handleNavigate(selectedIndex - 1)}
          onNext={() => handleNavigate(selectedIndex + 1)}
          onApprove={handleApprove}
          onReject={handleReject}
          onRegenerate={handleRegenerate}
          onClose={handleCloseViewer}
        />
      )}

      {showComparison &&
        selectedDesign &&
        selectedIndex < filteredDesigns.length - 1 && (
          <ComparisonMode
            left={selectedDesign}
            right={filteredDesigns[selectedIndex + 1]}
            onClose={handleToggleCompare}
          />
        )}

      {showRegenerate && selectedDesign && (
        <RegenerateDialog
          design={selectedDesign}
          onConfirm={handleRegenerateConfirm}
          onCancel={() => setShowRegenerate(false)}
        />
      )}
    </div>
  )
}

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'
import type { TrendSignal } from '@/types/signal'

interface PromoteToNicheDialogProps {
  signal: TrendSignal
  onClose: () => void
  onSuccess: () => void
}

export function PromoteToNicheDialog({
  signal,
  onClose,
  onSuccess,
}: PromoteToNicheDialogProps) {
  const [name, setName] = useState(signal.topic)
  const [description, setDescription] = useState(signal.description)
  const [communityType, setCommunityType] = useState(signal.community_type || 'fandom')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)

    try {
      await api.patch(`/trend_signals/${signal.id}`, {
        trend_signal: { status: 'promoted' },
      })
      await api.post('/niches', {
        niche: {
          trend_signal_id: signal.id,
          name,
          description,
          community_type: communityType,
          status: 'discovered',
        },
      })
      onSuccess()
    } catch (err) {
      setError('Failed to promote signal. Please try again.')
      console.error(err)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-label="Promote to Niche"
    >
      <div
        className="bg-background border rounded-lg p-6 w-full max-w-md shadow-lg"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="text-xl font-semibold mb-4">Promote to Niche</h2>
        <p className="text-sm text-muted-foreground mb-4">
          Create a new niche from the signal "{signal.topic}"
        </p>

        {error && (
          <div className="bg-destructive/10 border border-destructive text-destructive px-3 py-2 rounded text-sm mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="niche-name" className="block text-sm font-medium mb-1">
              Name
            </label>
            <input
              id="niche-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full border rounded-md px-3 py-2 text-sm bg-background"
              required
            />
          </div>

          <div>
            <label htmlFor="niche-description" className="block text-sm font-medium mb-1">
              Description
            </label>
            <textarea
              id="niche-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full border rounded-md px-3 py-2 text-sm bg-background"
              rows={3}
              required
            />
          </div>

          <div>
            <label htmlFor="niche-community-type" className="block text-sm font-medium mb-1">
              Community Type
            </label>
            <select
              id="niche-community-type"
              value={communityType}
              onChange={(e) => setCommunityType(e.target.value)}
              className="w-full border rounded-md px-3 py-2 text-sm bg-background"
            >
              <option value="fandom">Fandom</option>
              <option value="activist">Activist</option>
              <option value="meme">Meme</option>
              <option value="professional">Professional</option>
            </select>
          </div>

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? 'Promoting...' : 'Promote'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}

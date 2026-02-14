import { useState } from 'react'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'
import { STATUS_LABELS } from '@/types/cultural-token'
import type { CulturalTokenFull } from '@/types/cultural-token'

interface TokenDetailPanelProps {
  token: CulturalTokenFull | null
  onClose: () => void
}

function ScoreBar({ label, score }: { label: string; score: number }) {
  const color =
    score > 80
      ? 'bg-green-500'
      : score > 60
        ? 'bg-yellow-500'
        : 'bg-red-500'

  return (
    <div className="space-y-1">
      <div className="flex justify-between text-sm">
        <span className="text-muted-foreground">{label}</span>
        <span className="font-medium">{score.toFixed(1)}</span>
      </div>
      <div className="h-2 w-full rounded-full bg-muted">
        <div
          className={cn('h-2 rounded-full', color)}
          style={{ width: `${Math.min(score, 100)}%` }}
        />
      </div>
    </div>
  )
}

export function TokenDetailPanel({ token, onClose }: TokenDetailPanelProps) {
  const [generating, setGenerating] = useState(false)

  const handleGenerate = async () => {
    if (!token) return
    setGenerating(true)
    try {
      await api.post(`/cultural_tokens/${token.id}/generate`)
    } catch (err) {
      console.error('Failed to generate design:', err)
    } finally {
      setGenerating(false)
    }
  }

  return (
    <div
      className={cn(
        'fixed right-0 top-16 w-96 h-[calc(100vh-4rem)] z-50',
        'bg-background border-l shadow-lg',
        'transform transition-transform duration-300 ease-in-out',
        'overflow-y-auto',
        token ? 'translate-x-0' : 'translate-x-full'
      )}
      data-testid="token-detail-panel"
      aria-label="Token details"
    >
      {token && (
        <div className="p-4 space-y-6">
          <div className="flex items-start justify-between gap-2">
            <div>
              <h2 className="text-lg font-bold">{token.value}</h2>
              <span className="text-xs text-muted-foreground capitalize">
                {token.token_type}
              </span>
            </div>
            <button
              onClick={onClose}
              className="p-1 rounded hover:bg-muted"
              aria-label="Close detail panel"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div>
            <span className="inline-block rounded-full bg-muted px-2 py-0.5 text-xs">
              {STATUS_LABELS[token.status]}
            </span>
          </div>

          {token.context && (
            <div className="space-y-1">
              <h3 className="text-sm font-semibold border-b pb-1">Context</h3>
              <p className="text-sm text-muted-foreground">{token.context}</p>
            </div>
          )}

          <div className="space-y-3">
            <h3 className="text-sm font-semibold border-b pb-1">Scores</h3>
            <ScoreBar label="Frequency" score={token.frequency_score} />
            <ScoreBar label="Emotional Intensity" score={token.emotional_intensity} />
            <ScoreBar label="Visual Potential" score={token.visual_potential} />
            <ScoreBar label="Uniqueness" score={token.uniqueness_score} />
            <ScoreBar label="Composite" score={token.composite_score} />
          </div>

          {token.source_references && (
            <div className="space-y-1">
              <h3 className="text-sm font-semibold border-b pb-1">Source References</h3>
              <pre className="text-xs text-muted-foreground bg-muted/50 p-2 rounded overflow-x-auto">
                {JSON.stringify(token.source_references, null, 2)}
              </pre>
            </div>
          )}

          <Button
            onClick={handleGenerate}
            disabled={generating}
            className="w-full"
          >
            {generating ? 'Generating...' : 'Generate Design'}
          </Button>
        </div>
      )}
    </div>
  )
}

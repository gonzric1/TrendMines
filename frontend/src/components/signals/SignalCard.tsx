import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { SourceBadge } from './SourceBadge'
import { SparklineChart } from './SparklineChart'
import { STATUS_LABELS, STATUS_COLORS } from '@/types/signal'
import type { TrendSignal, SignalStatus, MomentumHistoryPoint } from '@/types/signal'
import api from '@/lib/api'
import type { MomentumHistoryResponse } from '@/types/signal'

interface SignalCardProps {
  signal: TrendSignal
  onPromote: (signal: TrendSignal) => void
}

function MomentumIndicator({ score }: { score: number }) {
  const color =
    score > 80 ? 'text-green-600 dark:text-green-400' :
    score > 50 ? 'text-yellow-600 dark:text-yellow-400' :
    'text-red-600 dark:text-red-400'

  return (
    <div className="text-right">
      <div className={cn('text-2xl font-bold', color)}>
        {score.toFixed(1)}
      </div>
      <div className="text-xs text-muted-foreground">Momentum</div>
    </div>
  )
}

function TrendArrow({ history }: { history: MomentumHistoryPoint[] }) {
  if (history.length < 2) return null

  const recent = history[history.length - 1].momentum_score
  const previous = history[history.length - 2].momentum_score
  const diff = recent - previous

  if (Math.abs(diff) < 1) {
    return <span className="text-muted-foreground text-sm" title="Flat">&#8594;</span>
  }

  if (diff > 0) {
    return <span className="text-green-600 dark:text-green-400 text-sm" title="Trending up">&#8593;</span>
  }

  return <span className="text-red-600 dark:text-red-400 text-sm" title="Trending down">&#8595;</span>
}

export function SignalCard({ signal, onPromote }: SignalCardProps) {
  const [history, setHistory] = useState<MomentumHistoryPoint[]>([])

  useEffect(() => {
    let cancelled = false
    api
      .get<MomentumHistoryResponse>(
        `/trend_signals/${signal.id}/history`,
        { params: { period: '7d', granularity: 'daily' } }
      )
      .then((res) => {
        if (!cancelled) setHistory(res.data.data)
      })
      .catch(() => {
        // Silently fail — sparkline is optional
      })
    return () => {
      cancelled = true
    }
  }, [signal.id])

  const statusLabel = STATUS_LABELS[signal.status as SignalStatus] ?? signal.status
  const statusColor =
    STATUS_COLORS[signal.status as SignalStatus] ??
    'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'

  const canPromote = signal.status === 'new' || signal.status === 'watching'

  return (
    <div className="border rounded-lg p-4 hover:border-primary/50 hover:shadow-sm transition-all">
      <div className="flex justify-between items-start gap-2 mb-2">
        <div className="space-y-1.5">
          <div className="flex items-center gap-2">
            <SourceBadge source={signal.source} />
            <span
              className={cn(
                'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
                statusColor
              )}
            >
              {statusLabel}
            </span>
          </div>
          <h3 className="text-lg font-semibold leading-tight">{signal.topic}</h3>
        </div>
        <div className="flex items-center gap-2">
          <TrendArrow history={history} />
          <MomentumIndicator score={signal.momentum_score} />
        </div>
      </div>

      <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
        {signal.description}
      </p>

      {history.length >= 2 && (
        <div className="mb-3">
          <SparklineChart data={history} />
        </div>
      )}

      <div className="flex items-center justify-between">
        <span className="text-xs text-muted-foreground">
          First seen: {new Date(signal.first_seen).toLocaleDateString()}
        </span>
        {canPromote && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => onPromote(signal)}
          >
            Promote to Niche
          </Button>
        )}
      </div>
    </div>
  )
}

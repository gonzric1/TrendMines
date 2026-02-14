import { cn } from '@/lib/utils'
import type { DecayAnalysis } from '@/types/product'

interface DecayChartProps {
  decay: DecayAnalysis
  width?: number
  height?: number
}

function TrendBar({ label, changePct }: { label: string; changePct: number }) {
  const isPositive = changePct > 0
  const absVal = Math.min(Math.abs(changePct), 100)

  return (
    <div className="space-y-1">
      <div className="flex justify-between text-xs">
        <span className="text-muted-foreground">{label}</span>
        <span className={cn(
          'font-medium',
          isPositive ? 'text-green-600 dark:text-green-400' : changePct < -5 ? 'text-red-600 dark:text-red-400' : 'text-muted-foreground'
        )}>
          {isPositive ? '+' : ''}{changePct.toFixed(1)}%
        </span>
      </div>
      <div className="relative h-2 bg-muted rounded-full overflow-hidden">
        <div className="absolute inset-0 flex">
          <div className="w-1/2" />
          <div className="w-1/2" />
        </div>
        {isPositive ? (
          <div
            className="absolute top-0 h-full bg-green-500 rounded-full"
            style={{ left: '50%', width: `${absVal / 2}%` }}
          />
        ) : (
          <div
            className="absolute top-0 h-full bg-red-500 rounded-full"
            style={{ right: '50%', width: `${absVal / 2}%` }}
          />
        )}
        <div className="absolute top-0 left-1/2 w-px h-full bg-border" />
      </div>
    </div>
  )
}

export function DecayChart({ decay }: DecayChartProps) {
  const hasTrends = decay.trends.sales || decay.trends.views || decay.trends.favorites

  if (!hasTrends) {
    return (
      <div className="text-center py-6 text-muted-foreground text-sm">
        No trend data available
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h4 className="text-sm font-medium">Metric Trends ({decay.period})</h4>
        <div className="flex items-center gap-3 text-xs text-muted-foreground">
          <span className="flex items-center gap-1">
            <span className="inline-block w-2 h-2 rounded-full bg-green-500" /> Growth
          </span>
          <span className="flex items-center gap-1">
            <span className="inline-block w-2 h-2 rounded-full bg-red-500" /> Decline
          </span>
        </div>
      </div>

      <div className="space-y-3">
        {decay.trends.sales && (
          <TrendBar label="Sales" changePct={decay.trends.sales.change_pct} />
        )}
        {decay.trends.views && (
          <TrendBar label="Views" changePct={decay.trends.views.change_pct} />
        )}
        {decay.trends.favorites && (
          <TrendBar label="Favorites" changePct={decay.trends.favorites.change_pct} />
        )}
      </div>

      <div className="pt-2 border-t">
        <div className="flex items-center justify-between">
          <span className="text-xs text-muted-foreground">Overall Decay Score</span>
          <div className="flex items-center gap-2">
            <div className="w-24 bg-muted rounded-full h-2">
              <div
                className={cn(
                  'h-2 rounded-full transition-all',
                  decay.decay_score >= 70 ? 'bg-red-500' :
                  decay.decay_score >= 40 ? 'bg-orange-500' :
                  decay.decay_score >= 20 ? 'bg-yellow-500' : 'bg-green-500'
                )}
                style={{ width: `${Math.min(decay.decay_score, 100)}%` }}
              />
            </div>
            <span className={cn(
              'text-sm font-bold',
              decay.decay_score >= 70 ? 'text-red-600 dark:text-red-400' :
              decay.decay_score >= 40 ? 'text-orange-600 dark:text-orange-400' : 'text-green-600 dark:text-green-400'
            )}>
              {decay.decay_score.toFixed(1)}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

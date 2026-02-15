import { cn } from '@/lib/utils'
import type { FunnelStage } from '@/types/analytics'

const STAGE_LABELS: Record<string, string> = {
  total_signals: 'Signals',
  promoted_signals: 'Promoted',
  niches: 'Niches',
  tokens_with_designs: 'Designs',
  products: 'Products',
  active_listings: 'Listings',
  listings_with_sales: 'Sales',
}

interface ConversionFunnelProps {
  stages: FunnelStage[]
}

export function ConversionFunnel({ stages }: ConversionFunnelProps) {
  if (stages.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        No funnel data available
      </div>
    )
  }

  const maxCount = Math.max(stages[0]?.count ?? 1, 1)

  return (
    <div className="space-y-2">
      {stages.map((stage, i) => {
        const widthPct = Math.max(10, (stage.count / maxCount) * 100)
        const prevCount = i > 0 ? stages[i - 1].count : null
        const conversionRate =
          prevCount && prevCount > 0
            ? ((stage.count / prevCount) * 100).toFixed(1)
            : null

        return (
          <div key={stage.stage} className="flex items-center gap-3">
            <div className="w-24 text-sm text-right text-muted-foreground shrink-0">
              {STAGE_LABELS[stage.stage] ?? stage.stage}
            </div>
            <div className="flex-1 relative">
              <div
                className={cn(
                  'h-8 rounded flex items-center px-3 text-sm font-medium transition-all',
                  i === 0
                    ? 'bg-primary/20 text-primary'
                    : i === stages.length - 1
                      ? 'bg-green-500/20 text-green-700 dark:text-green-300'
                      : 'bg-muted text-foreground'
                )}
                style={{ width: `${widthPct}%` }}
              >
                {stage.count.toLocaleString()}
              </div>
            </div>
            <div className="w-16 text-xs text-muted-foreground shrink-0">
              {conversionRate ? `${conversionRate}%` : ''}
            </div>
          </div>
        )
      })}
    </div>
  )
}

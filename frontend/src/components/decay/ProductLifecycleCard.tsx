import { cn } from '@/lib/utils'
import type { DecayProduct, LifecycleStage, DecayAnalysis } from '@/types/product'
import { TrendingDown, TrendingUp, Minus, AlertTriangle } from 'lucide-react'

const STAGE_CONFIG: Record<LifecycleStage, { label: string; color: string; bgColor: string }> = {
  launching: { label: 'Launching', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/40 border-blue-300 dark:border-blue-700' },
  growing: { label: 'Growing', color: 'text-green-700 dark:text-green-300', bgColor: 'bg-green-100 dark:bg-green-900/40 border-green-300 dark:border-green-700' },
  plateau: { label: 'Plateau', color: 'text-yellow-700 dark:text-yellow-300', bgColor: 'bg-yellow-100 dark:bg-yellow-900/40 border-yellow-300 dark:border-yellow-700' },
  declining: { label: 'Declining', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/40 border-orange-300 dark:border-orange-700' },
  urgent: { label: 'Urgent', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/40 border-red-300 dark:border-red-700' },
}

const ALERT_COLORS: Record<string, string> = {
  watch: 'border-l-yellow-500',
  declining: 'border-l-orange-500',
  urgent: 'border-l-red-500',
}

function TrendIndicator({ label, direction, changePct }: { label: string; direction: string; changePct: number }) {
  const Icon = direction === 'increasing' ? TrendingUp : direction === 'declining' ? TrendingDown : Minus
  const color = direction === 'increasing' ? 'text-green-600 dark:text-green-400' : direction === 'declining' ? 'text-red-600 dark:text-red-400' : 'text-muted-foreground'

  return (
    <div className="flex items-center gap-1.5">
      <Icon className={cn('h-3.5 w-3.5', color)} />
      <span className="text-xs text-muted-foreground">{label}</span>
      <span className={cn('text-xs font-medium', color)}>
        {changePct > 0 ? '+' : ''}{changePct.toFixed(1)}%
      </span>
    </div>
  )
}

function getAlertSeverity(decay: DecayAnalysis): string | null {
  if (decay.decay_score >= 70) return 'urgent'
  if (decay.decay_score >= 40) return 'declining'
  if (decay.decay_score >= 20) return 'watch'
  return null
}

interface ProductLifecycleCardProps {
  product: DecayProduct
  onClick?: (product: DecayProduct) => void
}

export function ProductLifecycleCard({ product, onClick }: ProductLifecycleCardProps) {
  const stage = product.lifecycle_stage ?? 'launching'
  const config = STAGE_CONFIG[stage]
  const decay = product.decay
  const alertSeverity = decay ? getAlertSeverity(decay) : null
  const alertBorder = alertSeverity ? ALERT_COLORS[alertSeverity] : ''

  return (
    <div
      className={cn(
        'border rounded-lg p-4 hover:shadow-sm transition-all cursor-pointer border-l-4',
        alertBorder || 'border-l-transparent'
      )}
      onClick={() => onClick?.(product)}
    >
      <div className="flex justify-between items-start mb-3">
        <div className="space-y-1">
          <h3 className="font-semibold leading-tight">{product.name}</h3>
          <p className="text-xs text-muted-foreground">{product.product_type}</p>
        </div>
        <div className="flex items-center gap-2">
          {alertSeverity === 'urgent' && (
            <AlertTriangle className="h-4 w-4 text-red-500" />
          )}
          <span className={cn('inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border', config.bgColor, config.color)}>
            {config.label}
          </span>
        </div>
      </div>

      {decay && decay.recommendation !== 'insufficient_data' ? (
        <>
          <div className="mb-3">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-muted-foreground">Decay Score</span>
              <span className={cn('text-sm font-bold', decay.decay_score >= 70 ? 'text-red-600 dark:text-red-400' : decay.decay_score >= 40 ? 'text-orange-600 dark:text-orange-400' : 'text-green-600 dark:text-green-400')}>
                {decay.decay_score.toFixed(1)}
              </span>
            </div>
            <div className="w-full bg-muted rounded-full h-1.5">
              <div
                className={cn(
                  'h-1.5 rounded-full transition-all',
                  decay.decay_score >= 70 ? 'bg-red-500' : decay.decay_score >= 40 ? 'bg-orange-500' : decay.decay_score >= 20 ? 'bg-yellow-500' : 'bg-green-500'
                )}
                style={{ width: `${Math.min(decay.decay_score, 100)}%` }}
              />
            </div>
          </div>

          <div className="space-y-1">
            {decay.trends.sales && <TrendIndicator label="Sales" direction={decay.trends.sales.direction} changePct={decay.trends.sales.change_pct} />}
            {decay.trends.views && <TrendIndicator label="Views" direction={decay.trends.views.direction} changePct={decay.trends.views.change_pct} />}
            {decay.trends.favorites && <TrendIndicator label="Favs" direction={decay.trends.favorites.direction} changePct={decay.trends.favorites.change_pct} />}
          </div>
        </>
      ) : (
        <p className="text-xs text-muted-foreground italic">Insufficient data for decay analysis</p>
      )}

      <div className="mt-3 pt-2 border-t flex items-center justify-between">
        <span className="text-xs text-muted-foreground">
          ${product.target_price?.toFixed(2) ?? '0.00'} / {product.margin_pct?.toFixed(0) ?? '0'}% margin
        </span>
        <span className="text-xs text-muted-foreground">
          {decay?.snapshot_count ?? 0} snapshots
        </span>
      </div>
    </div>
  )
}

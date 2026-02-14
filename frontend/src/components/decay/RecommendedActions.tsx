import { cn } from '@/lib/utils'
import type { DecayProduct } from '@/types/product'
import { AlertTriangle, ArrowRightLeft, MinusCircle, Eye, CheckCircle } from 'lucide-react'

const RECOMMENDATION_CONFIG: Record<string, { label: string; icon: typeof AlertTriangle; color: string; bgColor: string }> = {
  retire: {
    label: 'Retire Product',
    icon: MinusCircle,
    color: 'text-red-700 dark:text-red-300',
    bgColor: 'bg-red-50 dark:bg-red-950/30 border-red-200 dark:border-red-800',
  },
  monitor_closely: {
    label: 'Monitor Closely',
    icon: Eye,
    color: 'text-orange-700 dark:text-orange-300',
    bgColor: 'bg-orange-50 dark:bg-orange-950/30 border-orange-200 dark:border-orange-800',
  },
  maintain: {
    label: 'Maintain',
    icon: CheckCircle,
    color: 'text-green-700 dark:text-green-300',
    bgColor: 'bg-green-50 dark:bg-green-950/30 border-green-200 dark:border-green-800',
  },
  insufficient_data: {
    label: 'Insufficient Data',
    icon: AlertTriangle,
    color: 'text-muted-foreground',
    bgColor: 'bg-muted border-border',
  },
}

function generateActions(product: DecayProduct): string[] {
  const decay = product.decay
  if (!decay || decay.recommendation === 'insufficient_data') {
    return ['Collect more metric data before making decisions']
  }

  const actions: string[] = []

  if (decay.recommendation === 'retire') {
    actions.push('Begin phasing out production')
    actions.push('Reallocate printer capacity to higher-performing products')
    actions.push('Consider clearance pricing to move remaining inventory')
    if (decay.trends.sales?.change_pct && decay.trends.sales.change_pct < -30) {
      actions.push('Halt new print orders immediately')
    }
  } else if (decay.recommendation === 'monitor_closely') {
    actions.push('Review pricing strategy for competitiveness')
    if (decay.trends.views?.direction === 'declining') {
      actions.push('Refresh listing photos and keywords')
    }
    if (decay.trends.favorites?.direction === 'declining') {
      actions.push('Consider design refresh or variation')
    }
    actions.push('Re-evaluate in 7 days')
  } else {
    actions.push('Continue current strategy')
    if (decay.trends.sales?.direction === 'increasing') {
      actions.push('Consider scaling up production')
    }
  }

  return actions
}

interface RecommendedActionsProps {
  product: DecayProduct
}

export function RecommendedActions({ product }: RecommendedActionsProps) {
  const recommendation = product.decay?.recommendation ?? 'insufficient_data'
  const config = RECOMMENDATION_CONFIG[recommendation] ?? RECOMMENDATION_CONFIG.insufficient_data
  const actions = generateActions(product)
  const Icon = config.icon

  return (
    <div className={cn('border rounded-lg p-4', config.bgColor)}>
      <div className="flex items-center gap-2 mb-3">
        <Icon className={cn('h-5 w-5', config.color)} />
        <h4 className={cn('font-semibold', config.color)}>{config.label}</h4>
      </div>

      <ul className="space-y-2">
        {actions.map((action, i) => (
          <li key={i} className="flex items-start gap-2">
            <ArrowRightLeft className="h-3.5 w-3.5 mt-0.5 text-muted-foreground flex-shrink-0" />
            <span className="text-sm">{action}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}

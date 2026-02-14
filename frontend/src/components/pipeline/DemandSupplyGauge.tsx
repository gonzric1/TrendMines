import { cn } from '@/lib/utils'

interface DemandSupplyGaugeProps {
  ratio: number | null | undefined
}

export function DemandSupplyGauge({ ratio }: DemandSupplyGaugeProps) {
  if (ratio == null) {
    return (
      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-muted text-muted-foreground">
        N/A
      </span>
    )
  }

  const color =
    ratio >= 3.0
      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
      : ratio >= 1.5
        ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
        : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'

  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
        color
      )}
      title={`Demand/Supply Ratio: ${ratio.toFixed(2)}`}
    >
      {ratio.toFixed(1)}x
    </span>
  )
}

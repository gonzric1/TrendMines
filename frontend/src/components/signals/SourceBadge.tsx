import { cn } from '@/lib/utils'
import { SOURCE_COLORS, SOURCE_LABELS } from '@/types/signal'

interface SourceBadgeProps {
  source: string
}

export function SourceBadge({ source }: SourceBadgeProps) {
  const colorClass =
    SOURCE_COLORS[source] ??
    'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'

  const label = SOURCE_LABELS[source] ?? source

  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
        colorClass
      )}
    >
      {label}
    </span>
  )
}

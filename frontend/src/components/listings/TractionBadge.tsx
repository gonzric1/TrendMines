import { cn } from '@/lib/utils'
import type { TractionLabel } from '@/types/listing'

interface TractionBadgeProps {
  label: TractionLabel
  className?: string
}

const config: Record<TractionLabel, { text: string; bg: string; fg: string; icon: string }> = {
  scaling: {
    text: 'Scaling',
    bg: 'bg-green-100 dark:bg-green-950/30',
    fg: 'text-green-700 dark:text-green-300',
    icon: '\u{1F680}',
  },
  promising: {
    text: 'Promising',
    bg: 'bg-blue-100 dark:bg-blue-950/30',
    fg: 'text-blue-700 dark:text-blue-300',
    icon: '\u2197',
  },
  no_signal: {
    text: 'No Signal',
    bg: 'bg-red-100 dark:bg-red-950/30',
    fg: 'text-red-700 dark:text-red-300',
    icon: '\u26A0',
  },
  new: {
    text: 'New',
    bg: 'bg-gray-100 dark:bg-gray-800/30',
    fg: 'text-gray-700 dark:text-gray-300',
    icon: '\u{1F552}',
  },
}

export function TractionBadge({ label, className }: TractionBadgeProps) {
  const c = config[label]
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium',
        c.bg,
        c.fg,
        className
      )}
    >
      <span>{c.icon}</span>
      {c.text}
    </span>
  )
}

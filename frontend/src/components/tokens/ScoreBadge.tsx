import { cn } from '@/lib/utils'

interface ScoreBadgeProps {
  score: number
}

export function ScoreBadge({ score }: ScoreBadgeProps) {
  const bg =
    score > 80
      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
      : score > 60
        ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
        : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'

  return (
    <span className={cn('inline-block rounded-full px-2 py-0.5 text-xs font-medium', bg)}>
      {score.toFixed(1)}
    </span>
  )
}

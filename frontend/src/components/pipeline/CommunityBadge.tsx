import { cn } from '@/lib/utils'
import { COMMUNITY_COLORS } from '@/types/niche'

interface CommunityBadgeProps {
  type: string | null | undefined
}

export function CommunityBadge({ type }: CommunityBadgeProps) {
  if (!type) return null

  const colorClass =
    COMMUNITY_COLORS[type] ??
    'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'

  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize',
        colorClass
      )}
    >
      {type}
    </span>
  )
}

import { cn } from '@/lib/utils'
import type { Design, DesignStatus } from '@/types/design'

interface DesignCardProps {
  design: Design
  onClick: (design: Design) => void
}

const statusColors: Record<DesignStatus, string> = {
  pending_review:
    'bg-yellow-100 text-yellow-800 dark:bg-yellow-950/30 dark:text-yellow-300',
  approved:
    'bg-green-100 text-green-800 dark:bg-green-950/30 dark:text-green-300',
  rejected: 'bg-red-100 text-red-800 dark:bg-red-950/30 dark:text-red-300',
  needs_revision:
    'bg-orange-100 text-orange-800 dark:bg-orange-950/30 dark:text-orange-300',
}

const statusLabels: Record<DesignStatus, string> = {
  pending_review: 'Pending Review',
  approved: 'Approved',
  rejected: 'Rejected',
  needs_revision: 'Needs Revision',
}

export function DesignCard({ design, onClick }: DesignCardProps) {
  return (
    <button
      className="border rounded-lg overflow-hidden hover:shadow-md transition-shadow text-left w-full"
      onClick={() => onClick(design)}
    >
      <div className="aspect-square bg-muted flex items-center justify-center overflow-hidden">
        {design.image_url ? (
          <img
            src={design.image_url}
            alt={`Design ${design.id}`}
            className="w-full h-full object-cover"
          />
        ) : (
          <span className="text-muted-foreground text-sm">No image</span>
        )}
      </div>
      <div className="p-3 space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium capitalize">
            {design.design_type}
          </span>
          <span
            className={cn(
              'text-xs px-2 py-0.5 rounded-full font-medium',
              statusColors[design.status]
            )}
          >
            {statusLabels[design.status]}
          </span>
        </div>
        {design.style && (
          <p className="text-xs text-muted-foreground truncate">
            {design.style}
          </p>
        )}
      </div>
    </button>
  )
}

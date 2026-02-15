import { cn } from '@/lib/utils'
import type { Design, DesignStatus } from '@/types/design'
import { DesignCard } from './DesignCard'

type FilterTab = 'all' | DesignStatus

interface DesignGridProps {
  designs: Design[]
  activeFilter: FilterTab
  onFilterChange: (filter: FilterTab) => void
  onDesignClick: (design: Design) => void
}

const filterTabs: { value: FilterTab; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'pending_review', label: 'Pending Review' },
  { value: 'approved', label: 'Approved' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'needs_revision', label: 'Needs Revision' },
]

export function DesignGrid({
  designs,
  activeFilter,
  onFilterChange,
  onDesignClick,
}: DesignGridProps) {
  const counts: Record<FilterTab, number> = {
    all: designs.length,
    pending_review: designs.filter((d) => d.status === 'pending_review').length,
    approved: designs.filter((d) => d.status === 'approved').length,
    rejected: designs.filter((d) => d.status === 'rejected').length,
    needs_revision: designs.filter((d) => d.status === 'needs_revision').length,
  }

  const filtered =
    activeFilter === 'all'
      ? designs
      : designs.filter((d) => d.status === activeFilter)

  return (
    <div className="space-y-4">
      <div className="flex gap-1 border-b">
        {filterTabs.map((tab) => (
          <button
            key={tab.value}
            className={cn(
              'px-4 py-2 text-sm font-medium border-b-2 transition-colors -mb-px',
              activeFilter === tab.value
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
            onClick={() => onFilterChange(tab.value)}
          >
            {tab.label} ({counts[tab.value]})
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-muted-foreground">No designs found</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {filtered.map((design) => (
            <DesignCard
              key={design.id}
              design={design}
              onClick={onDesignClick}
            />
          ))}
        </div>
      )}
    </div>
  )
}

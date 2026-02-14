import { cn } from '@/lib/utils'
import { SOURCE_LABELS } from '@/types/signal'
import type { SignalStatus } from '@/types/signal'

const SOURCES = Object.keys(SOURCE_LABELS)
const STATUS_OPTIONS: { value: SignalStatus | 'all'; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'new', label: 'New' },
  { value: 'watching', label: 'Watching' },
  { value: 'promoted', label: 'Promoted' },
  { value: 'archived', label: 'Archived' },
]

const SORT_OPTIONS = [
  { value: 'momentum_score', label: 'Momentum' },
  { value: 'first_seen', label: 'First Seen' },
] as const

export type SortField = (typeof SORT_OPTIONS)[number]['value']

interface FilterToolbarProps {
  selectedSources: string[]
  onSourcesChange: (sources: string[]) => void
  selectedStatus: SignalStatus | 'all'
  onStatusChange: (status: SignalStatus | 'all') => void
  sortField: SortField
  onSortChange: (sort: SortField) => void
}

export function FilterToolbar({
  selectedSources,
  onSourcesChange,
  selectedStatus,
  onStatusChange,
  sortField,
  onSortChange,
}: FilterToolbarProps) {
  const toggleSource = (source: string) => {
    if (selectedSources.includes(source)) {
      onSourcesChange(selectedSources.filter((s) => s !== source))
    } else {
      onSourcesChange([...selectedSources, source])
    }
  }

  return (
    <div className="flex flex-wrap items-center gap-4" role="toolbar" aria-label="Signal filters">
      <div className="flex items-center gap-2">
        <span className="text-sm font-medium text-muted-foreground">Source:</span>
        <div className="flex flex-wrap gap-1">
          {SOURCES.map((source) => (
            <button
              key={source}
              onClick={() => toggleSource(source)}
              className={cn(
                'px-2 py-1 text-xs rounded-md border transition-colors',
                selectedSources.includes(source)
                  ? 'bg-primary text-primary-foreground border-primary'
                  : 'bg-background text-muted-foreground border-border hover:border-primary/50'
              )}
            >
              {SOURCE_LABELS[source]}
            </button>
          ))}
        </div>
      </div>

      <div className="flex items-center gap-2">
        <span className="text-sm font-medium text-muted-foreground">Status:</span>
        <select
          value={selectedStatus}
          onChange={(e) => onStatusChange(e.target.value as SignalStatus | 'all')}
          className="text-sm border rounded-md px-2 py-1 bg-background"
          aria-label="Filter by status"
        >
          {STATUS_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <div className="flex items-center gap-2">
        <span className="text-sm font-medium text-muted-foreground">Sort:</span>
        <select
          value={sortField}
          onChange={(e) => onSortChange(e.target.value as SortField)}
          className="text-sm border rounded-md px-2 py-1 bg-background"
          aria-label="Sort signals"
        >
          {SORT_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>
    </div>
  )
}

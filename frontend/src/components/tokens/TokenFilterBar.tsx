import type { TokenType, TokenStatus } from '@/types/cultural-token'
import { TOKEN_TYPES, TOKEN_STATUSES, STATUS_LABELS } from '@/types/cultural-token'

interface TokenFilterBarProps {
  typeFilter: TokenType | 'all'
  statusFilter: TokenStatus | 'all'
  onTypeChange: (type: TokenType | 'all') => void
  onStatusChange: (status: TokenStatus | 'all') => void
}

export function TokenFilterBar({
  typeFilter,
  statusFilter,
  onTypeChange,
  onStatusChange,
}: TokenFilterBarProps) {
  return (
    <div className="flex items-center gap-4" data-testid="token-filter-bar">
      <div className="flex items-center gap-2">
        <label htmlFor="type-filter" className="text-sm text-muted-foreground">
          Type
        </label>
        <select
          id="type-filter"
          value={typeFilter}
          onChange={(e) => onTypeChange(e.target.value as TokenType | 'all')}
          className="rounded border bg-background px-2 py-1 text-sm"
        >
          <option value="all">All</option>
          {TOKEN_TYPES.map((t) => (
            <option key={t} value={t}>
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </option>
          ))}
        </select>
      </div>

      <div className="flex items-center gap-2">
        <label htmlFor="status-filter" className="text-sm text-muted-foreground">
          Status
        </label>
        <select
          id="status-filter"
          value={statusFilter}
          onChange={(e) => onStatusChange(e.target.value as TokenStatus | 'all')}
          className="rounded border bg-background px-2 py-1 text-sm"
        >
          <option value="all">All</option>
          {TOKEN_STATUSES.map((s) => (
            <option key={s} value={s}>
              {STATUS_LABELS[s]}
            </option>
          ))}
        </select>
      </div>
    </div>
  )
}

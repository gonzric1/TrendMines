import { cn } from '@/lib/utils'
import { ScoreBadge } from './ScoreBadge'
import { STATUS_LABELS } from '@/types/cultural-token'
import type { CulturalTokenFull, SortColumn, SortDirection } from '@/types/cultural-token'

interface TokenTableProps {
  tokens: CulturalTokenFull[]
  selectedId: number | null
  sortColumn: SortColumn
  sortDirection: SortDirection
  onSort: (column: SortColumn) => void
  onSelect: (token: CulturalTokenFull) => void
}

const columns: { key: SortColumn; label: string }[] = [
  { key: 'value', label: 'Value' },
  { key: 'token_type', label: 'Type' },
  { key: 'frequency_score', label: 'Frequency' },
  { key: 'emotional_intensity', label: 'Emotional' },
  { key: 'visual_potential', label: 'Visual' },
  { key: 'uniqueness_score', label: 'Uniqueness' },
  { key: 'composite_score', label: 'Score' },
  { key: 'status', label: 'Status' },
]

function SortIndicator({ column, sortColumn, sortDirection }: { column: SortColumn; sortColumn: SortColumn; sortDirection: SortDirection }) {
  if (column !== sortColumn) return null
  return <span className="ml-1">{sortDirection === 'ASC' ? '\u2191' : '\u2193'}</span>
}

export function TokenTable({
  tokens,
  selectedId,
  sortColumn,
  sortDirection,
  onSort,
  onSelect,
}: TokenTableProps) {
  return (
    <div className="overflow-x-auto" data-testid="token-table">
      <table className="w-full">
        <thead>
          <tr className="border-b">
            {columns.map((col) => (
              <th
                key={col.key}
                onClick={() => onSort(col.key)}
                className="text-left text-sm font-medium text-muted-foreground cursor-pointer hover:text-foreground px-4 py-3"
              >
                {col.label}
                <SortIndicator column={col.key} sortColumn={sortColumn} sortDirection={sortDirection} />
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {tokens.map((token) => (
            <tr
              key={token.id}
              onClick={() => onSelect(token)}
              className={cn(
                'border-b cursor-pointer hover:bg-muted/50 transition-colors',
                selectedId === token.id && 'bg-muted'
              )}
            >
              <td className="px-4 py-3 text-sm font-medium">{token.value}</td>
              <td className="px-4 py-3 text-sm capitalize">{token.token_type}</td>
              <td className="px-4 py-3"><ScoreBadge score={token.frequency_score} /></td>
              <td className="px-4 py-3"><ScoreBadge score={token.emotional_intensity} /></td>
              <td className="px-4 py-3"><ScoreBadge score={token.visual_potential} /></td>
              <td className="px-4 py-3"><ScoreBadge score={token.uniqueness_score} /></td>
              <td className="px-4 py-3"><ScoreBadge score={token.composite_score} /></td>
              <td className="px-4 py-3">
                <span className="inline-block rounded-full bg-muted px-2 py-0.5 text-xs">
                  {STATUS_LABELS[token.status]}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

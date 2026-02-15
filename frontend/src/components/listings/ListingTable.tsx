import { useState } from 'react'
import { cn } from '@/lib/utils'
import { TractionBadge } from './TractionBadge'
import type { ListingWithMetrics } from '@/types/listing'

interface ListingTableProps {
  listings: ListingWithMetrics[]
  selectedId: number | null
  onSelect: (listing: ListingWithMetrics) => void
}

type SortKey = 'title' | 'status' | 'price' | 'views' | 'favorites' | 'sales' | 'revenue' | 'fav_view_ratio'
type SortDir = 'asc' | 'desc'

function getSortValue(listing: ListingWithMetrics, key: SortKey): string | number {
  switch (key) {
    case 'title': return listing.title.toLowerCase()
    case 'status': return listing.status
    case 'price': return listing.price
    case 'views': return listing.latestMetrics?.views ?? 0
    case 'favorites': return listing.latestMetrics?.favorites ?? 0
    case 'sales': return listing.latestMetrics?.sales ?? 0
    case 'revenue': return listing.latestMetrics?.revenue ?? 0
    case 'fav_view_ratio': return listing.latestMetrics?.fav_view_ratio ?? 0
  }
}

const columns: { key: SortKey; label: string; align?: 'right' }[] = [
  { key: 'title', label: 'Title' },
  { key: 'status', label: 'Status' },
  { key: 'price', label: 'Price', align: 'right' },
  { key: 'views', label: 'Views', align: 'right' },
  { key: 'favorites', label: 'Favs', align: 'right' },
  { key: 'sales', label: 'Sales', align: 'right' },
  { key: 'revenue', label: 'Revenue', align: 'right' },
  { key: 'fav_view_ratio', label: 'Fav/View %', align: 'right' },
]

export function ListingTable({ listings, selectedId, onSelect }: ListingTableProps) {
  const [sortKey, setSortKey] = useState<SortKey>('revenue')
  const [sortDir, setSortDir] = useState<SortDir>('desc')

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc')
    } else {
      setSortKey(key)
      setSortDir('desc')
    }
  }

  const sorted = [...listings].sort((a, b) => {
    const va = getSortValue(a, sortKey)
    const vb = getSortValue(b, sortKey)
    const cmp = typeof va === 'string' ? va.localeCompare(vb as string) : (va as number) - (vb as number)
    return sortDir === 'asc' ? cmp : -cmp
  })

  if (listings.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">No listings found</p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b">
            {columns.map((col) => (
              <th
                key={col.key}
                className={cn(
                  'py-3 px-4 font-medium text-muted-foreground cursor-pointer hover:text-foreground select-none',
                  col.align === 'right' ? 'text-right' : 'text-left'
                )}
                onClick={() => handleSort(col.key)}
              >
                {col.label}
                {sortKey === col.key && (
                  <span className="ml-1">{sortDir === 'asc' ? '\u2191' : '\u2193'}</span>
                )}
              </th>
            ))}
            <th className="py-3 px-4 font-medium text-muted-foreground text-left">Traction</th>
          </tr>
        </thead>
        <tbody>
          {sorted.map((listing) => (
            <tr
              key={listing.id}
              className={cn(
                'border-b cursor-pointer transition-colors',
                selectedId === listing.id
                  ? 'bg-primary/5'
                  : 'hover:bg-muted/50'
              )}
              onClick={() => onSelect(listing)}
            >
              <td className="py-3 px-4 font-medium">{listing.title}</td>
              <td className="py-3 px-4">
                <span className={cn(
                  'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                  listing.status === 'active' ? 'bg-green-100 dark:bg-green-950/30 text-green-700 dark:text-green-300' :
                  listing.status === 'sold_out' ? 'bg-orange-100 dark:bg-orange-950/30 text-orange-700 dark:text-orange-300' :
                  listing.status === 'paused' ? 'bg-yellow-100 dark:bg-yellow-950/30 text-yellow-700 dark:text-yellow-300' :
                  'bg-gray-100 dark:bg-gray-800/30 text-gray-700 dark:text-gray-300'
                )}>
                  {listing.status}
                </span>
              </td>
              <td className="py-3 px-4 text-right">${listing.price.toFixed(2)}</td>
              <td className="py-3 px-4 text-right">{listing.latestMetrics?.views ?? '-'}</td>
              <td className="py-3 px-4 text-right">{listing.latestMetrics?.favorites ?? '-'}</td>
              <td className="py-3 px-4 text-right">{listing.latestMetrics?.sales ?? '-'}</td>
              <td className="py-3 px-4 text-right">
                {listing.latestMetrics ? `$${listing.latestMetrics.revenue.toFixed(2)}` : '-'}
              </td>
              <td className="py-3 px-4 text-right">
                {listing.latestMetrics ? `${(listing.latestMetrics.fav_view_ratio * 100).toFixed(1)}%` : '-'}
              </td>
              <td className="py-3 px-4">
                {listing.traction && <TractionBadge label={listing.traction} />}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

import { useState } from 'react'
import { cn } from '@/lib/utils'
import type { ListingAlert, AlertType } from '@/types/listing'

interface AlertsPanelProps {
  alerts: ListingAlert[]
}

const filterOptions: { value: AlertType | 'all'; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'first_sale', label: 'First Sale' },
  { value: 'promising', label: 'Promising' },
  { value: 'no_signal', label: 'No Signal' },
]

export function AlertsPanel({ alerts }: AlertsPanelProps) {
  const [filter, setFilter] = useState<AlertType | 'all'>('all')

  const filtered = filter === 'all' ? alerts : alerts.filter((a) => a.alert_type === filter)

  if (alerts.length === 0) {
    return (
      <div className="border rounded-lg p-6 text-center">
        <p className="text-muted-foreground">No alerts</p>
      </div>
    )
  }

  return (
    <div className="border rounded-lg p-4 space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold">Alerts ({alerts.length})</h3>
        <select
          className="text-xs border rounded px-2 py-1 bg-background"
          value={filter}
          onChange={(e) => setFilter(e.target.value as AlertType | 'all')}
          aria-label="Filter alerts"
        >
          {filterOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-2 max-h-80 overflow-y-auto">
        {filtered.map((alert, i) => (
          <div
            key={`${alert.listing_id}-${alert.alert_type}-${i}`}
            className="border rounded p-3 space-y-1"
          >
            <div className="flex items-center gap-2">
              <span
                className="inline-block w-2 h-2 rounded-full flex-shrink-0"
                style={{ backgroundColor: alert.color }}
              />
              <span className="text-sm font-medium truncate">{alert.title}</span>
            </div>
            <p className="text-xs text-muted-foreground">{alert.threshold_crossed}</p>
            <p className="text-xs text-muted-foreground italic">{alert.recommended_action}</p>
          </div>
        ))}
        {filtered.length === 0 && (
          <p className="text-xs text-muted-foreground text-center py-2">
            No alerts matching filter
          </p>
        )}
      </div>
    </div>
  )
}

import type { ListingWithMetrics, ListingAlert } from '@/types/listing'

interface SummaryStatsRowProps {
  listings: ListingWithMetrics[]
  alerts: ListingAlert[]
}

function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="border rounded-lg p-4 flex-1 min-w-0">
      <p className="text-xs text-muted-foreground truncate">{label}</p>
      <p className="text-2xl font-bold mt-1">{value}</p>
    </div>
  )
}

export function SummaryStatsRow({ listings, alerts }: SummaryStatsRowProps) {
  const activeCount = listings.filter((l) => l.status === 'active').length

  const totalRevenue = listings.reduce(
    (sum, l) => sum + (l.latestMetrics?.revenue ?? 0),
    0
  )

  const ratios = listings
    .map((l) => l.latestMetrics?.fav_view_ratio)
    .filter((r): r is number => r != null)
  const avgRatio = ratios.length > 0
    ? ratios.reduce((a, b) => a + b, 0) / ratios.length
    : 0

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      <StatCard label="Active Listings" value={activeCount} />
      <StatCard label="Total Revenue" value={`$${totalRevenue.toFixed(2)}`} />
      <StatCard label="Avg Fav/View %" value={`${(avgRatio * 100).toFixed(1)}%`} />
      <StatCard label="Alerts" value={alerts.length} />
    </div>
  )
}

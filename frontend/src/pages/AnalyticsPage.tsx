import { useEffect, useState, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import api from '@/lib/api'
import type {
  RevenueResponse,
  FunnelResponse,
  SourcesResponse,
  CostsResponse,
  RevenueDataPoint,
  FunnelStage,
  SourceStats,
  CostBreakdown,
} from '@/types/analytics'
import { RevenueChart } from '@/components/analytics/RevenueChart'
import { ConversionFunnel } from '@/components/analytics/ConversionFunnel'
import { SourceROI } from '@/components/analytics/SourceROI'
import { CostBreakdownCard } from '@/components/analytics/CostBreakdown'

type Period = 'daily' | 'weekly' | 'monthly'
type DateRange = '7d' | '30d' | '90d'

function getDateRange(range: DateRange): { start_date: string; end_date: string } {
  const end = new Date()
  const start = new Date()
  const days = range === '7d' ? 7 : range === '30d' ? 30 : 90
  start.setDate(start.getDate() - days)
  return {
    start_date: start.toISOString().split('T')[0],
    end_date: end.toISOString().split('T')[0],
  }
}

function exportRevenueCSV(data: RevenueDataPoint[]) {
  const header = 'Period,Revenue'
  const rows = data.map((d) => `${d.period},${d.revenue.toFixed(2)}`)
  const csv = [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `revenue-${new Date().toISOString().split('T')[0]}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

export default function AnalyticsPage() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [period, setPeriod] = useState<Period>('daily')
  const [dateRange, setDateRange] = useState<DateRange>('30d')

  const [revenueData, setRevenueData] = useState<RevenueDataPoint[]>([])
  const [totalRevenue, setTotalRevenue] = useState(0)
  const [funnel, setFunnel] = useState<FunnelStage[]>([])
  const [sources, setSources] = useState<SourceStats[]>([])
  const [costs, setCosts] = useState<CostBreakdown | null>(null)
  const [costsRevenue, setCostsRevenue] = useState(0)

  const fetchData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      const { start_date, end_date } = getDateRange(dateRange)

      const [revenueRes, funnelRes, sourcesRes, costsRes] = await Promise.all([
        api.get<RevenueResponse>('/analytics/revenue', {
          params: { period, start_date, end_date },
        }),
        api.get<FunnelResponse>('/analytics/funnel'),
        api.get<SourcesResponse>('/analytics/sources'),
        api.get<CostsResponse>('/analytics/costs'),
      ])

      setRevenueData(revenueRes.data.data)
      setTotalRevenue(revenueRes.data.total_revenue)
      setFunnel(funnelRes.data.funnel)
      setSources(sourcesRes.data.sources)
      setCosts(costsRes.data.costs)
      setCostsRevenue(costsRes.data.total_revenue)
    } catch (err) {
      setError('Failed to fetch analytics data. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [period, dateRange])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Analytics & Revenue</h1>
          <p className="text-muted-foreground mt-1">
            Revenue trends, conversion funnel, and cost analysis
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => exportRevenueCSV(revenueData)} disabled={revenueData.length === 0}>
            Export CSV
          </Button>
          <Button onClick={fetchData}>Refresh</Button>
        </div>
      </div>

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading analytics...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && (
        <div className="space-y-6">
          {/* Revenue Section */}
          <div className="border rounded-lg p-4">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold">Revenue</h2>
              <div className="flex gap-1">
                {/* Period selector */}
                {(['daily', 'weekly', 'monthly'] as Period[]).map((p) => (
                  <button
                    key={p}
                    className={cn(
                      'px-3 py-1 text-xs font-medium rounded transition-colors',
                      period === p
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-muted text-muted-foreground hover:text-foreground'
                    )}
                    onClick={() => setPeriod(p)}
                  >
                    {p.charAt(0).toUpperCase() + p.slice(1)}
                  </button>
                ))}
                <span className="mx-1 border-l" />
                {/* Date range selector */}
                {(['7d', '30d', '90d'] as DateRange[]).map((r) => (
                  <button
                    key={r}
                    className={cn(
                      'px-3 py-1 text-xs font-medium rounded transition-colors',
                      dateRange === r
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-muted text-muted-foreground hover:text-foreground'
                    )}
                    onClick={() => setDateRange(r)}
                  >
                    {r}
                  </button>
                ))}
              </div>
            </div>
            <RevenueChart data={revenueData} totalRevenue={totalRevenue} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Conversion Funnel */}
            <div className="border rounded-lg p-4">
              <h2 className="text-lg font-semibold mb-4">Conversion Funnel</h2>
              <ConversionFunnel stages={funnel} />
            </div>

            {/* Cost Breakdown */}
            <div className="border rounded-lg p-4">
              <h2 className="text-lg font-semibold mb-4">Cost Breakdown</h2>
              {costs ? (
                <CostBreakdownCard costs={costs} totalRevenue={costsRevenue} />
              ) : (
                <div className="text-center py-8 text-muted-foreground">
                  No cost data available
                </div>
              )}
            </div>
          </div>

          {/* Source ROI */}
          <div className="border rounded-lg p-4">
            <h2 className="text-lg font-semibold mb-4">Source ROI Analysis</h2>
            <SourceROI sources={sources} />
          </div>
        </div>
      )}
    </div>
  )
}

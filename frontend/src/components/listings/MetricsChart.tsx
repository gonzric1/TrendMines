import { cn } from '@/lib/utils'
import type { MetricSnapshot } from '@/types/listing'

interface MetricsChartProps {
  snapshots: MetricSnapshot[]
}

interface LineConfig {
  key: 'views' | 'sales' | 'revenue'
  label: string
  color: string
}

const lines: LineConfig[] = [
  { key: 'views', label: 'Views', color: '#3b82f6' },
  { key: 'sales', label: 'Sales', color: '#10b981' },
  { key: 'revenue', label: 'Revenue', color: '#f59e0b' },
]

const CHART_W = 400
const CHART_H = 200
const PAD_L = 50
const PAD_R = 10
const PAD_T = 10
const PAD_B = 30
const PLOT_W = CHART_W - PAD_L - PAD_R
const PLOT_H = CHART_H - PAD_T - PAD_B

function buildPath(
  sorted: MetricSnapshot[],
  key: 'views' | 'sales' | 'revenue',
  maxVal: number
): string {
  if (sorted.length === 0 || maxVal === 0) return ''
  return sorted
    .map((s, i) => {
      const x = PAD_L + (i / Math.max(sorted.length - 1, 1)) * PLOT_W
      const y = PAD_T + PLOT_H - (s[key] / maxVal) * PLOT_H
      return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`
    })
    .join(' ')
}

export function MetricsChart({ snapshots }: MetricsChartProps) {
  if (snapshots.length === 0) {
    return (
      <div className="text-center py-6 text-muted-foreground text-sm">
        No metric history available
      </div>
    )
  }

  // Sort oldest to newest for chart
  const sorted = [...snapshots].sort(
    (a, b) => new Date(a.captured_at).getTime() - new Date(b.captured_at).getTime()
  )

  // Compute per-line max for normalized rendering
  const maxViews = Math.max(...sorted.map((s) => s.views), 1)
  const maxSales = Math.max(...sorted.map((s) => s.sales), 1)
  const maxRevenue = Math.max(...sorted.map((s) => s.revenue), 1)
  const maxMap: Record<string, number> = { views: maxViews, sales: maxSales, revenue: maxRevenue }

  const firstDate = new Date(sorted[0].captured_at)
  const lastDate = new Date(sorted[sorted.length - 1].captured_at)

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-3 text-xs text-muted-foreground">
        {lines.map((l) => (
          <span key={l.key} className="flex items-center gap-1">
            <span
              className="inline-block w-3 h-0.5 rounded"
              style={{ backgroundColor: l.color }}
            />
            {l.label}
          </span>
        ))}
      </div>

      <svg
        viewBox={`0 0 ${CHART_W} ${CHART_H}`}
        className="w-full"
        role="img"
        aria-label="Metrics chart"
      >
        {/* Y-axis line */}
        <line
          x1={PAD_L}
          y1={PAD_T}
          x2={PAD_L}
          y2={PAD_T + PLOT_H}
          stroke="currentColor"
          className="text-border"
          strokeWidth="1"
        />
        {/* X-axis line */}
        <line
          x1={PAD_L}
          y1={PAD_T + PLOT_H}
          x2={PAD_L + PLOT_W}
          y2={PAD_T + PLOT_H}
          stroke="currentColor"
          className="text-border"
          strokeWidth="1"
        />

        {/* Horizontal grid lines */}
        {[0.25, 0.5, 0.75].map((frac) => (
          <line
            key={frac}
            x1={PAD_L}
            y1={PAD_T + PLOT_H * (1 - frac)}
            x2={PAD_L + PLOT_W}
            y2={PAD_T + PLOT_H * (1 - frac)}
            stroke="currentColor"
            className="text-border"
            strokeWidth="0.5"
            strokeDasharray="4 4"
          />
        ))}

        {/* Data lines */}
        {lines.map((l) => (
          <path
            key={l.key}
            d={buildPath(sorted, l.key, maxMap[l.key])}
            fill="none"
            stroke={l.color}
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        ))}

        {/* X-axis date labels */}
        <text
          x={PAD_L}
          y={CHART_H - 4}
          className="text-muted-foreground"
          fill="currentColor"
          fontSize="9"
          textAnchor="start"
        >
          {firstDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
        </text>
        <text
          x={PAD_L + PLOT_W}
          y={CHART_H - 4}
          className="text-muted-foreground"
          fill="currentColor"
          fontSize="9"
          textAnchor="end"
        >
          {lastDate.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
        </text>
      </svg>
    </div>
  )
}

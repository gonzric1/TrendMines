import { useMemo } from 'react'
import type { RevenueDataPoint } from '@/types/analytics'

interface RevenueChartProps {
  data: RevenueDataPoint[]
  totalRevenue: number
}

export function RevenueChart({ data, totalRevenue }: RevenueChartProps) {
  const chartData = useMemo(() => {
    if (data.length === 0) return { bars: [], maxRevenue: 0 }
    const maxRevenue = Math.max(...data.map((d) => d.revenue), 1)
    const bars = data.map((d) => ({
      label: d.period,
      revenue: d.revenue,
      heightPct: (d.revenue / maxRevenue) * 100,
    }))
    return { bars, maxRevenue }
  }, [data])

  if (data.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        No revenue data for this period
      </div>
    )
  }

  const chartHeight = 200
  const barGap = 2
  const barWidth = Math.max(8, Math.min(40, (600 - barGap * data.length) / data.length))

  return (
    <div>
      <div className="text-2xl font-bold mb-4">
        ${totalRevenue.toFixed(2)}
        <span className="text-sm font-normal text-muted-foreground ml-2">total revenue</span>
      </div>
      <div className="overflow-x-auto">
        <svg
          width={Math.max(300, data.length * (barWidth + barGap) + 60)}
          height={chartHeight + 40}
          role="img"
          aria-label="Revenue chart"
          className="w-full"
        >
          {/* Y-axis gridlines */}
          {[0, 0.25, 0.5, 0.75, 1].map((pct) => {
            const y = chartHeight - pct * chartHeight
            return (
              <g key={pct}>
                <line
                  x1={50}
                  y1={y}
                  x2={Math.max(300, data.length * (barWidth + barGap) + 60)}
                  y2={y}
                  stroke="currentColor"
                  strokeOpacity={0.1}
                />
                <text
                  x={46}
                  y={y + 4}
                  textAnchor="end"
                  className="fill-muted-foreground"
                  fontSize={10}
                >
                  ${(chartData.maxRevenue * pct).toFixed(0)}
                </text>
              </g>
            )
          })}
          {/* Bars */}
          {chartData.bars.map((bar, i) => {
            const barHeight = (bar.heightPct / 100) * chartHeight
            const x = 54 + i * (barWidth + barGap)
            const y = chartHeight - barHeight
            return (
              <g key={i}>
                <rect
                  x={x}
                  y={y}
                  width={barWidth}
                  height={barHeight}
                  rx={2}
                  className="fill-primary"
                />
                {/* X-axis labels - show every Nth label to avoid crowding */}
                {(data.length <= 14 || i % Math.ceil(data.length / 14) === 0) && (
                  <text
                    x={x + barWidth / 2}
                    y={chartHeight + 14}
                    textAnchor="middle"
                    className="fill-muted-foreground"
                    fontSize={9}
                  >
                    {bar.label.length > 10 ? bar.label.slice(5) : bar.label}
                  </text>
                )}
                <title>
                  {bar.label}: ${bar.revenue.toFixed(2)}
                </title>
              </g>
            )
          })}
        </svg>
      </div>
    </div>
  )
}

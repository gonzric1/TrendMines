interface SparklineChartProps {
  data: { date: string; momentum_score: number }[]
  width?: number
  height?: number
}

export function SparklineChart({
  data,
  width = 120,
  height = 40,
}: SparklineChartProps) {
  if (data.length < 2) return null

  const scores = data.map((d) => d.momentum_score)
  const min = Math.min(...scores)
  const max = Math.max(...scores)
  const range = max - min || 1

  const padding = 2
  const chartWidth = width - padding * 2
  const chartHeight = height - padding * 2

  const points = scores.map((score, i) => {
    const x = padding + (i / (scores.length - 1)) * chartWidth
    const y = padding + chartHeight - ((score - min) / range) * chartHeight
    return `${x},${y}`
  })

  const trending = scores[scores.length - 1] >= scores[0]
  const strokeColor = trending ? '#22c55e' : '#ef4444'

  return (
    <svg
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      className="inline-block"
      aria-label="Momentum sparkline"
    >
      <polyline
        points={points.join(' ')}
        fill="none"
        stroke={strokeColor}
        strokeWidth={1.5}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

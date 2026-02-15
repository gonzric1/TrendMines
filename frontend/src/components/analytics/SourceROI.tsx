import type { SourceStats } from '@/types/analytics'

interface SourceROIProps {
  sources: SourceStats[]
}

export function SourceROI({ sources }: SourceROIProps) {
  if (sources.length === 0) {
    return (
      <div className="text-center py-8 text-muted-foreground">
        No source data available
      </div>
    )
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-muted-foreground">
            <th className="text-left py-2 font-medium">Source</th>
            <th className="text-right py-2 font-medium">Signals</th>
            <th className="text-right py-2 font-medium">Products</th>
            <th className="text-right py-2 font-medium">Revenue</th>
            <th className="text-right py-2 font-medium">ROI/Signal</th>
          </tr>
        </thead>
        <tbody>
          {sources.map((source) => {
            const roi =
              source.signal_count > 0
                ? source.total_revenue / source.signal_count
                : 0
            return (
              <tr key={source.source} className="border-b last:border-0">
                <td className="py-2 capitalize font-medium">{source.source}</td>
                <td className="py-2 text-right">{source.signal_count.toLocaleString()}</td>
                <td className="py-2 text-right">{source.product_count.toLocaleString()}</td>
                <td className="py-2 text-right">${source.total_revenue.toFixed(2)}</td>
                <td className="py-2 text-right">${roi.toFixed(2)}</td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

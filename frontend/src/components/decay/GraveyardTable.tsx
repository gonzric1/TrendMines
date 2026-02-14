import { cn } from '@/lib/utils'
import type { DecayProduct } from '@/types/product'
import { Skull } from 'lucide-react'

interface GraveyardTableProps {
  products: DecayProduct[]
}

function formatDuration(created: string): string {
  const start = new Date(created)
  const now = new Date()
  const days = Math.floor((now.getTime() - start.getTime()) / (1000 * 60 * 60 * 24))

  if (days < 30) return `${days}d`
  if (days < 365) return `${Math.floor(days / 30)}mo`
  return `${(days / 365).toFixed(1)}yr`
}

export function GraveyardTable({ products }: GraveyardTableProps) {
  if (products.length === 0) {
    return (
      <div className="text-center py-12">
        <Skull className="h-12 w-12 mx-auto text-muted-foreground/30 mb-3" />
        <p className="text-muted-foreground">No retired products yet</p>
        <p className="text-xs text-muted-foreground mt-1">
          Products moved to retired status will appear here with post-mortem data
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b">
            <th className="text-left py-3 px-4 font-medium text-muted-foreground">Product</th>
            <th className="text-left py-3 px-4 font-medium text-muted-foreground">Type</th>
            <th className="text-right py-3 px-4 font-medium text-muted-foreground">Lifespan</th>
            <th className="text-right py-3 px-4 font-medium text-muted-foreground">Final Decay Score</th>
            <th className="text-right py-3 px-4 font-medium text-muted-foreground">Snapshots</th>
            <th className="text-right py-3 px-4 font-medium text-muted-foreground">Target Price</th>
            <th className="text-right py-3 px-4 font-medium text-muted-foreground">Margin</th>
            <th className="text-left py-3 px-4 font-medium text-muted-foreground">Retired</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id} className="border-b hover:bg-muted/50 transition-colors">
              <td className="py-3 px-4">
                <span className="font-medium">{product.name}</span>
              </td>
              <td className="py-3 px-4 text-muted-foreground">{product.product_type}</td>
              <td className="py-3 px-4 text-right">{formatDuration(product.created_at)}</td>
              <td className="py-3 px-4 text-right">
                <span className={cn(
                  'font-medium',
                  (product.decay?.decay_score ?? 0) >= 70 ? 'text-red-600 dark:text-red-400' :
                  (product.decay?.decay_score ?? 0) >= 40 ? 'text-orange-600 dark:text-orange-400' : 'text-muted-foreground'
                )}>
                  {product.decay?.decay_score?.toFixed(1) ?? 'N/A'}
                </span>
              </td>
              <td className="py-3 px-4 text-right text-muted-foreground">
                {product.decay?.snapshot_count ?? 0}
              </td>
              <td className="py-3 px-4 text-right">
                ${product.target_price?.toFixed(2) ?? '0.00'}
              </td>
              <td className="py-3 px-4 text-right">
                {product.margin_pct?.toFixed(0) ?? '0'}%
              </td>
              <td className="py-3 px-4 text-muted-foreground">
                {new Date(product.updated_at).toLocaleDateString()}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

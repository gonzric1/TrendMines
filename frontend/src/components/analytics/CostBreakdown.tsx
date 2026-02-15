import type { CostBreakdown as CostBreakdownType } from '@/types/analytics'

interface CostBreakdownProps {
  costs: CostBreakdownType
  totalRevenue: number
}

interface CostLineProps {
  label: string
  amount: number
  total: number
}

function CostLine({ label, amount, total }: CostLineProps) {
  const pct = total > 0 ? (amount / total) * 100 : 0
  return (
    <div className="space-y-1">
      <div className="flex justify-between text-sm">
        <span>{label}</span>
        <span className="font-medium">${amount.toFixed(2)}</span>
      </div>
      <div className="h-2 bg-muted rounded-full overflow-hidden">
        <div
          className="h-full bg-primary/60 rounded-full"
          style={{ width: `${Math.min(pct, 100)}%` }}
        />
      </div>
    </div>
  )
}

export function CostBreakdownCard({ costs, totalRevenue }: CostBreakdownProps) {
  const netProfit = totalRevenue - costs.total_estimated
  const profitMargin =
    totalRevenue > 0 ? ((netProfit / totalRevenue) * 100).toFixed(1) : '0.0'

  return (
    <div className="space-y-4">
      <div className="space-y-3">
        <CostLine
          label="Design Generation"
          amount={costs.design_generation}
          total={costs.total_estimated}
        />
        <CostLine
          label="Material Costs"
          amount={costs.material_costs}
          total={costs.total_estimated}
        />
        <CostLine
          label="Etsy Transaction Fees"
          amount={costs.etsy_transaction_fees}
          total={costs.total_estimated}
        />
        <CostLine
          label="Etsy Listing Fees"
          amount={costs.etsy_listing_fees}
          total={costs.total_estimated}
        />
      </div>

      <div className="border-t pt-3 space-y-2">
        <div className="flex justify-between text-sm">
          <span>Total Costs</span>
          <span className="font-medium">${costs.total_estimated.toFixed(2)}</span>
        </div>
        <div className="flex justify-between text-sm">
          <span>Total Revenue</span>
          <span className="font-medium">${totalRevenue.toFixed(2)}</span>
        </div>
        <div className="flex justify-between font-semibold text-base border-t pt-2">
          <span>Net Profit</span>
          <span className={netProfit >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}>
            ${netProfit.toFixed(2)} ({profitMargin}%)
          </span>
        </div>
      </div>
    </div>
  )
}

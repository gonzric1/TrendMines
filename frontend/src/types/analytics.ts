export interface RevenueDataPoint {
  period: string
  revenue: number
}

export interface RevenueResponse {
  period: string
  start_date: string
  end_date: string
  total_revenue: number
  data: RevenueDataPoint[]
}

export interface FunnelStage {
  stage: string
  count: number
}

export interface FunnelResponse {
  funnel: FunnelStage[]
}

export interface SourceStats {
  source: string
  signal_count: number
  product_count: number
  total_revenue: number
}

export interface SourcesResponse {
  sources: SourceStats[]
}

export interface CostBreakdown {
  design_generation: number
  material_costs: number
  etsy_transaction_fees: number
  etsy_listing_fees: number
  total_estimated: number
}

export interface CostsResponse {
  costs: CostBreakdown
  total_revenue: number
}

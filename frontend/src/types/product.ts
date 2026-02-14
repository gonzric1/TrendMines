export type ProductStatus = 'prototype' | 'listed' | 'scaling' | 'declining' | 'retired'

export interface Product {
  id: number
  design_id: number
  product_type: string
  name: string
  unit_cost: number
  target_price: number
  margin_pct: number
  print_time_minutes: number
  units_per_batch: number
  stl_file_url: string | null
  status: ProductStatus
  created_at: string
  updated_at: string
}

export type TrendDirection = 'increasing' | 'stable' | 'declining'

export interface TrendInfo {
  direction: TrendDirection
  change_pct: number
}

export interface DecayAnalysis {
  product_id: number
  product_name: string
  status: ProductStatus
  decay_score: number
  trends: {
    sales?: TrendInfo
    views?: TrendInfo
    favorites?: TrendInfo
  }
  recommendation: 'maintain' | 'monitor_closely' | 'retire' | 'insufficient_data'
  thresholds: {
    sales_decline_threshold: number
    view_decline_ratio: number
  }
  snapshot_count: number
  period: string
}

export type LifecycleStage = 'launching' | 'growing' | 'plateau' | 'declining' | 'urgent'

export interface DecayProduct extends Product {
  decay?: DecayAnalysis
  lifecycle_stage?: LifecycleStage
}

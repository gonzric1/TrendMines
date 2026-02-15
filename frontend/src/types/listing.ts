export type ListingStatus = 'draft' | 'active' | 'sold_out' | 'paused'

export type TractionLabel = 'scaling' | 'promising' | 'no_signal' | 'new'

export type AlertType = 'first_sale' | 'promising' | 'no_signal'

export interface Listing {
  id: number
  product_id: number
  etsy_listing_id: string | null
  title: string
  status: ListingStatus
  price: number
  listed_at: string | null
  created_at: string
  updated_at: string
}

export interface MetricSnapshot {
  id: number
  listing_id: number
  views: number
  favorites: number
  sales: number
  revenue: number
  fav_view_ratio: number
  captured_at: string
}

export interface ListingAlert {
  listing_id: number
  title: string
  alert_type: AlertType
  label: TractionLabel
  icon: string
  color: string
  threshold_crossed: string
  timestamp: string
  recommended_action: string
}

export interface ListingWithMetrics extends Listing {
  latestMetrics?: MetricSnapshot
  traction?: TractionLabel
}

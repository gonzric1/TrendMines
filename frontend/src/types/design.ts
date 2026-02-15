export type DesignStatus = 'pending_review' | 'approved' | 'rejected' | 'needs_revision'
export type DesignType = 'graphic' | 'pattern' | 'illustration'

export interface Design {
  id: number
  cultural_token_id: number
  design_type: DesignType
  style: string | null
  prompt_used: string | null
  image_url: string | null
  generation_cost: number | null
  status: DesignStatus
  created_at: string
  updated_at: string
}

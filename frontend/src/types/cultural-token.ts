export const TOKEN_TYPES = ['quote', 'symbol', 'character', 'meme'] as const
export type TokenType = (typeof TOKEN_TYPES)[number]

export const TOKEN_STATUSES = [
  'extracted',
  'designs_pending',
  'designs_ready',
  'in_production',
  'listed',
] as const
export type TokenStatus = (typeof TOKEN_STATUSES)[number]

export const STATUS_LABELS: Record<TokenStatus, string> = {
  extracted: 'Extracted',
  designs_pending: 'Designs Pending',
  designs_ready: 'Designs Ready',
  in_production: 'In Production',
  listed: 'Listed',
}

export interface CulturalTokenFull {
  id: number
  niche_id: number
  token_type: TokenType
  value: string
  status: TokenStatus
  composite_score: number
  frequency_score: number
  emotional_intensity: number
  visual_potential: number
  uniqueness_score: number
  source_references: unknown
  context: string
  created_at: string
  updated_at: string
}

export type SortColumn =
  | 'value'
  | 'token_type'
  | 'frequency_score'
  | 'emotional_intensity'
  | 'visual_potential'
  | 'uniqueness_score'
  | 'composite_score'
  | 'status'

export type SortDirection = 'ASC' | 'DESC'

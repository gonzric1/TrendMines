export const NICHE_STATUSES = [
  'discovered',
  'evaluating',
  'mining_tokens',
  'generating_designs',
  'active',
  'declining',
  'archived',
] as const

export type NicheStatus = (typeof NICHE_STATUSES)[number]

export const STATUS_LABELS: Record<NicheStatus, string> = {
  discovered: 'Discovered',
  evaluating: 'Evaluating',
  mining_tokens: 'Mining Tokens',
  generating_designs: 'Generating Designs',
  active: 'Active',
  declining: 'Declining',
  archived: 'Archived',
}

export const STATUS_COLORS: Record<NicheStatus, string> = {
  discovered: 'border-l-blue-400',
  evaluating: 'border-l-amber-400',
  mining_tokens: 'border-l-purple-400',
  generating_designs: 'border-l-pink-400',
  active: 'border-l-green-400',
  declining: 'border-l-orange-400',
  archived: 'border-l-gray-400',
}

export const STATUS_BG_COLORS: Record<NicheStatus, string> = {
  discovered: 'bg-blue-400/10',
  evaluating: 'bg-amber-400/10',
  mining_tokens: 'bg-purple-400/10',
  generating_designs: 'bg-pink-400/10',
  active: 'bg-green-400/10',
  declining: 'bg-orange-400/10',
  archived: 'bg-gray-400/10',
}

export type CommunityType = 'fandom' | 'activist' | 'meme' | 'professional'

export const COMMUNITY_COLORS: Record<string, string> = {
  fandom: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
  activist: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  meme: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
  professional: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
}

export interface Niche {
  id: number
  trend_signal_id: number
  name: string
  description: string
  community_type: string
  demand_score: number
  supply_score: number
  demand_supply_ratio: number
  ao3_works_count: number
  ao3_growth_rate: number
  etsy_listing_count: number
  status: NicheStatus
  discovered_at: string
  created_at: string
  updated_at: string
}

export interface NicheScorecard {
  niche: Niche
  demand_score: number
  supply_score: number
  demand_supply_ratio: number
  ao3_metrics: {
    works_count: number
    growth_rate: number
  }
  etsy_listing_count: number
}

export interface CulturalToken {
  id: number
  niche_id: number
  name: string
  token_type: string
  description: string
  relevance_score: number
  status: string
  created_at: string
  updated_at: string
}

export interface Design {
  id: number
  cultural_token_id: number
  name: string
  description: string
  image_url: string
  status: string
  created_at: string
  updated_at: string
}

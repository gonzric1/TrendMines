export const SIGNAL_STATUSES = ['new', 'watching', 'promoted', 'archived'] as const

export type SignalStatus = (typeof SIGNAL_STATUSES)[number]

export const STATUS_LABELS: Record<SignalStatus, string> = {
  new: 'New',
  watching: 'Watching',
  promoted: 'Promoted',
  archived: 'Archived',
}

export const STATUS_COLORS: Record<SignalStatus, string> = {
  new: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
  watching: 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200',
  promoted: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  archived: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
}

export type SignalSource =
  | 'twitter'
  | 'reddit'
  | 'tiktok'
  | 'ao3'
  | 'tumblr'
  | 'google_trends'

export const SOURCE_COLORS: Record<string, string> = {
  twitter: 'bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200',
  reddit: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
  tiktok: 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200',
  ao3: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  tumblr: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200',
  google_trends: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200',
}

export const SOURCE_LABELS: Record<string, string> = {
  twitter: 'Twitter',
  reddit: 'Reddit',
  tiktok: 'TikTok',
  ao3: 'AO3',
  tumblr: 'Tumblr',
  google_trends: 'Google Trends',
}

export interface TrendSignal {
  id: number
  source: string
  topic: string
  description: string
  momentum_score: number
  status: SignalStatus
  first_seen: string
  last_updated: string
  raw_data: Record<string, unknown>
  community_type: string
}

export interface MomentumHistoryPoint {
  date: string
  momentum_score: number
  source_metrics: Record<string, unknown>
}

export interface MomentumHistoryResponse {
  signal_id: number
  period: string
  granularity: string
  data: MomentumHistoryPoint[]
}

import { useEffect, useState } from 'react'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils'
import api from '@/lib/api'
import type { Niche, NicheScorecard, CulturalToken, Design } from '@/types/niche'
import { STATUS_LABELS } from '@/types/niche'
import { DemandSupplyGauge } from './DemandSupplyGauge'
import { CommunityBadge } from './CommunityBadge'

interface NicheDetailPanelProps {
  niche: Niche | null
  onClose: () => void
}

export function NicheDetailPanel({ niche, onClose }: NicheDetailPanelProps) {
  const [scorecard, setScorecard] = useState<NicheScorecard | null>(null)
  const [tokens, setTokens] = useState<CulturalToken[]>([])
  const [designs, setDesigns] = useState<Design[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (!niche) {
      setScorecard(null)
      setTokens([])
      setDesigns([])
      return
    }

    let cancelled = false
    setLoading(true)

    Promise.allSettled([
      api.get<NicheScorecard>(`/niches/${niche.id}/scorecard`),
      api.get<CulturalToken[]>(`/niches/${niche.id}/tokens`),
      api.get<Design[]>(`/niches/${niche.id}/designs`),
    ]).then(([scorecardResult, tokensResult, designsResult]) => {
      if (cancelled) return

      if (scorecardResult.status === 'fulfilled' && scorecardResult.value.data?.ao3_metrics) {
        setScorecard(scorecardResult.value.data)
      }
      if (tokensResult.status === 'fulfilled') {
        setTokens(tokensResult.value.data)
      }
      if (designsResult.status === 'fulfilled') {
        setDesigns(designsResult.value.data)
      }
      setLoading(false)
    })

    return () => {
      cancelled = true
    }
  }, [niche])

  return (
    <div
      className={cn(
        'fixed right-0 top-16 w-96 h-[calc(100vh-4rem)] z-50',
        'bg-background border-l shadow-lg',
        'transform transition-transform duration-300 ease-in-out',
        'overflow-y-auto',
        niche ? 'translate-x-0' : 'translate-x-full'
      )}
      data-testid="niche-detail-panel"
      aria-label="Niche details"
    >
      {niche && (
        <div className="p-4 space-y-6">
          {/* Header */}
          <div className="flex items-start justify-between gap-2">
            <div>
              <h2 className="text-lg font-bold">{niche.name}</h2>
              <span className="text-xs text-muted-foreground">
                {STATUS_LABELS[niche.status]}
              </span>
            </div>
            <button
              onClick={onClose}
              className="p-1 rounded hover:bg-muted"
              aria-label="Close detail panel"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {niche.description && (
            <p className="text-sm text-muted-foreground">{niche.description}</p>
          )}

          <div className="flex items-center gap-2">
            <CommunityBadge type={niche.community_type} />
            <DemandSupplyGauge ratio={niche.demand_supply_ratio} />
          </div>

          {loading && (
            <p className="text-sm text-muted-foreground">Loading details...</p>
          )}

          {/* Scorecard Section */}
          {scorecard && (
            <div className="space-y-2">
              <h3 className="text-sm font-semibold border-b pb-1">Scorecard</h3>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span className="text-muted-foreground">Demand</span>
                  <p className="font-medium">{scorecard.demand_score?.toFixed(1) ?? 'N/A'}</p>
                </div>
                <div>
                  <span className="text-muted-foreground">Supply</span>
                  <p className="font-medium">{scorecard.supply_score?.toFixed(1) ?? 'N/A'}</p>
                </div>
                <div>
                  <span className="text-muted-foreground">AO3 Works</span>
                  <p className="font-medium">
                    {scorecard.ao3_metrics.works_count?.toLocaleString() ?? 'N/A'}
                  </p>
                </div>
                <div>
                  <span className="text-muted-foreground">AO3 Growth</span>
                  <p className="font-medium">
                    {scorecard.ao3_metrics.growth_rate != null
                      ? `${(scorecard.ao3_metrics.growth_rate * 100).toFixed(1)}%`
                      : 'N/A'}
                  </p>
                </div>
                <div>
                  <span className="text-muted-foreground">Etsy Listings</span>
                  <p className="font-medium">
                    {scorecard.etsy_listing_count?.toLocaleString() ?? 'N/A'}
                  </p>
                </div>
                <div>
                  <span className="text-muted-foreground">D/S Ratio</span>
                  <p className="font-medium">
                    {scorecard.demand_supply_ratio?.toFixed(2) ?? 'N/A'}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Tokens Section */}
          {tokens.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-sm font-semibold border-b pb-1">
                Cultural Tokens ({tokens.length})
              </h3>
              <div className="space-y-1">
                {tokens.map((token) => (
                  <div
                    key={token.id}
                    className="flex items-center justify-between text-sm p-1.5 rounded bg-muted/50"
                  >
                    <span>{token.name}</span>
                    <span className="text-xs text-muted-foreground">
                      {token.relevance_score?.toFixed(1)}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Designs Section */}
          {designs.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-sm font-semibold border-b pb-1">
                Designs ({designs.length})
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {designs.map((design) => (
                  <div key={design.id} className="rounded border overflow-hidden">
                    {design.image_url ? (
                      <img
                        src={design.image_url}
                        alt={design.name}
                        className="w-full h-20 object-cover"
                      />
                    ) : (
                      <div className="w-full h-20 bg-muted flex items-center justify-center text-xs text-muted-foreground">
                        No image
                      </div>
                    )}
                    <p className="text-xs p-1 truncate">{design.name}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

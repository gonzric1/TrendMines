import { useDraggable } from '@dnd-kit/core'
import { CSS } from '@dnd-kit/utilities'
import { cn } from '@/lib/utils'
import type { Niche } from '@/types/niche'
import { DemandSupplyGauge } from './DemandSupplyGauge'
import { CommunityBadge } from './CommunityBadge'

interface NicheCardProps {
  niche: Niche
  onClick: (niche: Niche) => void
}

function daysSince(dateString: string | null | undefined): number | null {
  if (!dateString) return null
  const diff = Date.now() - new Date(dateString).getTime()
  return Math.floor(diff / (1000 * 60 * 60 * 24))
}

export function NicheCard({ niche, onClick }: NicheCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    isDragging,
  } = useDraggable({
    id: niche.id,
    data: { niche },
  })

  const style = {
    transform: CSS.Translate.toString(transform),
  }

  const days = daysSince(niche.discovered_at)

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      role="button"
      tabIndex={0}
      className={cn(
        'bg-card border rounded-lg p-3 cursor-grab active:cursor-grabbing',
        'hover:border-primary/50 hover:shadow-sm transition-all',
        isDragging && 'opacity-50 shadow-lg'
      )}
      onClick={() => onClick(niche)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onClick(niche)
        }
      }}
      aria-label={`Niche: ${niche.name}`}
    >
      <div className="flex justify-between items-start gap-2 mb-2">
        <h4 className="text-sm font-medium leading-tight line-clamp-2">
          {niche.name}
        </h4>
        <DemandSupplyGauge ratio={niche.demand_supply_ratio} />
      </div>

      <div className="flex items-center gap-2 text-xs text-muted-foreground mb-2">
        {niche.ao3_works_count != null && (
          <span title="AO3 Works">AO3: {niche.ao3_works_count.toLocaleString()}</span>
        )}
        {niche.etsy_listing_count != null && (
          <span title="Etsy Listings">Etsy: {niche.etsy_listing_count.toLocaleString()}</span>
        )}
      </div>

      <div className="flex items-center justify-between">
        <CommunityBadge type={niche.community_type} />
        {days != null && (
          <span className="text-xs text-muted-foreground" title="Days since discovery">
            {days}d ago
          </span>
        )}
      </div>
    </div>
  )
}

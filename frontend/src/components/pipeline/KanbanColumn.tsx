import { useDroppable } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { cn } from '@/lib/utils'
import type { Niche, NicheStatus } from '@/types/niche'
import { STATUS_LABELS, STATUS_COLORS, STATUS_BG_COLORS } from '@/types/niche'
import { NicheCard } from './NicheCard'

interface KanbanColumnProps {
  status: NicheStatus
  niches: Niche[]
  onNicheClick: (niche: Niche) => void
}

export function KanbanColumn({ status, niches, onNicheClick }: KanbanColumnProps) {
  const { isOver, setNodeRef } = useDroppable({ id: status })

  return (
    <div
      ref={setNodeRef}
      className={cn(
        'flex flex-col min-w-[280px] w-[280px] rounded-lg border-l-4 bg-muted/30',
        STATUS_COLORS[status],
        isOver && 'ring-2 ring-primary/50 bg-primary/5'
      )}
      data-testid={`column-${status}`}
    >
      <div className={cn('px-3 py-2 rounded-tr-lg', STATUS_BG_COLORS[status])}>
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-semibold">{STATUS_LABELS[status]}</h3>
          <span className="text-xs text-muted-foreground font-medium bg-background/50 px-1.5 py-0.5 rounded">
            {niches.length}
          </span>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-2 space-y-2 min-h-[200px]">
        <SortableContext
          items={niches.map((n) => n.id)}
          strategy={verticalListSortingStrategy}
        >
          {niches.map((niche) => (
            <NicheCard key={niche.id} niche={niche} onClick={onNicheClick} />
          ))}
        </SortableContext>

        {niches.length === 0 && (
          <div className="flex items-center justify-center h-20 text-xs text-muted-foreground">
            No niches
          </div>
        )}
      </div>
    </div>
  )
}

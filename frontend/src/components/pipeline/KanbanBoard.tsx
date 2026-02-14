import { useState, useCallback } from 'react'
import {
  DndContext,
  DragOverlay,
  closestCorners,
  PointerSensor,
  useSensor,
  useSensors,
  type DragStartEvent,
  type DragEndEvent,
} from '@dnd-kit/core'
import type { Niche, NicheStatus } from '@/types/niche'
import { NICHE_STATUSES } from '@/types/niche'
import { KanbanColumn } from './KanbanColumn'
import { NicheCard } from './NicheCard'

interface KanbanBoardProps {
  niches: Niche[]
  onStatusChange: (nicheId: number, newStatus: NicheStatus) => void
  onNicheClick: (niche: Niche) => void
}

export function groupNichesByStatus(niches: Niche[]): Record<NicheStatus, Niche[]> {
  const groups = Object.fromEntries(
    NICHE_STATUSES.map((s) => [s, [] as Niche[]])
  ) as Record<NicheStatus, Niche[]>

  for (const niche of niches) {
    if (groups[niche.status]) {
      groups[niche.status].push(niche)
    }
  }

  return groups
}

export function KanbanBoard({ niches, onStatusChange, onNicheClick }: KanbanBoardProps) {
  const [activeNiche, setActiveNiche] = useState<Niche | null>(null)

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 8 },
    })
  )

  const grouped = groupNichesByStatus(niches)

  const handleDragStart = useCallback(
    (event: DragStartEvent) => {
      const niche = niches.find((n) => n.id === event.active.id) ?? null
      setActiveNiche(niche)
    },
    [niches]
  )

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      setActiveNiche(null)
      const { active, over } = event
      if (!over) return

      const nicheId = active.id as number
      const targetStatus = over.id as NicheStatus

      if (!NICHE_STATUSES.includes(targetStatus)) return

      const niche = niches.find((n) => n.id === nicheId)
      if (!niche || niche.status === targetStatus) return

      onStatusChange(nicheId, targetStatus)
    },
    [niches, onStatusChange]
  )

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="flex gap-4 overflow-x-auto pb-4" data-testid="kanban-board">
        {NICHE_STATUSES.map((status) => (
          <KanbanColumn
            key={status}
            status={status}
            niches={grouped[status]}
            onNicheClick={onNicheClick}
          />
        ))}
      </div>

      <DragOverlay>
        {activeNiche ? (
          <div className="rotate-3 opacity-90">
            <NicheCard niche={activeNiche} onClick={() => {}} />
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  )
}

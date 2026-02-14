import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { DndContext } from '@dnd-kit/core'
import { SortableContext } from '@dnd-kit/sortable'
import type { Niche } from '@/types/niche'
import { NicheCard } from './NicheCard'

const mockNiche: Niche = {
  id: 1,
  trend_signal_id: 10,
  name: 'Cottagecore Fashion',
  description: 'A cozy aesthetic niche',
  community_type: 'fandom',
  demand_score: 85.0,
  supply_score: 30.0,
  demand_supply_ratio: 2.83,
  ao3_works_count: 1500,
  ao3_growth_rate: 0.15,
  etsy_listing_count: 320,
  status: 'evaluating',
  discovered_at: '2026-01-01T00:00:00Z',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-15T00:00:00Z',
}

function renderWithDnd(ui: React.ReactElement) {
  return render(
    <DndContext>
      <SortableContext items={[mockNiche.id]}>{ui}</SortableContext>
    </DndContext>
  )
}

describe('NicheCard', () => {
  it('renders niche name', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    expect(screen.getByText('Cottagecore Fashion')).toBeInTheDocument()
  })

  it('renders demand/supply gauge', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    expect(screen.getByText('2.8x')).toBeInTheDocument()
  })

  it('renders AO3 count', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    expect(screen.getByText('AO3: 1,500')).toBeInTheDocument()
  })

  it('renders Etsy count', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    expect(screen.getByText('Etsy: 320')).toBeInTheDocument()
  })

  it('renders community badge', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    expect(screen.getByText('fandom')).toBeInTheDocument()
  })

  it('renders days since discovery', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    // Should show some "Xd ago" text
    const card = screen.getByLabelText('Niche: Cottagecore Fashion')
    expect(card.textContent).toMatch(/\d+d ago/)
  })

  it('calls onClick when clicked', () => {
    const onClick = vi.fn()

    renderWithDnd(<NicheCard niche={mockNiche} onClick={onClick} />)

    // Use fireEvent.click — userEvent fires pointer events that dnd-kit intercepts in jsdom
    fireEvent.click(screen.getByLabelText('Niche: Cottagecore Fashion'))
    expect(onClick).toHaveBeenCalledWith(mockNiche)
  })

  it('has accessible aria-label', () => {
    renderWithDnd(<NicheCard niche={mockNiche} onClick={() => {}} />)
    expect(screen.getByLabelText('Niche: Cottagecore Fashion')).toBeInTheDocument()
  })
})

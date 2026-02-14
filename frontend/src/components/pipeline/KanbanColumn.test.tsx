import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { DndContext } from '@dnd-kit/core'
import type { Niche } from '@/types/niche'
import { KanbanColumn } from './KanbanColumn'

const mockNiches: Niche[] = [
  {
    id: 1,
    trend_signal_id: 10,
    name: 'Cottagecore',
    description: '',
    community_type: 'fandom',
    demand_score: 85,
    supply_score: 30,
    demand_supply_ratio: 2.83,
    ao3_works_count: 1500,
    ao3_growth_rate: 0.15,
    etsy_listing_count: 320,
    status: 'discovered',
    discovered_at: '2026-01-01T00:00:00Z',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: 2,
    trend_signal_id: 11,
    name: 'Dark Academia',
    description: '',
    community_type: 'fandom',
    demand_score: 70,
    supply_score: 25,
    demand_supply_ratio: 2.8,
    ao3_works_count: 800,
    ao3_growth_rate: 0.1,
    etsy_listing_count: 200,
    status: 'discovered',
    discovered_at: '2026-01-05T00:00:00Z',
    created_at: '2026-01-05T00:00:00Z',
    updated_at: '2026-01-05T00:00:00Z',
  },
]

function renderWithDnd(ui: React.ReactElement) {
  return render(<DndContext>{ui}</DndContext>)
}

describe('KanbanColumn', () => {
  it('renders the correct status label', () => {
    renderWithDnd(
      <KanbanColumn status="discovered" niches={[]} onNicheClick={vi.fn()} />
    )
    expect(screen.getByText('Discovered')).toBeInTheDocument()
  })

  it('displays the count of niches', () => {
    renderWithDnd(
      <KanbanColumn status="discovered" niches={mockNiches} onNicheClick={vi.fn()} />
    )
    expect(screen.getByText('2')).toBeInTheDocument()
  })

  it('renders all niche cards', () => {
    renderWithDnd(
      <KanbanColumn status="discovered" niches={mockNiches} onNicheClick={vi.fn()} />
    )
    expect(screen.getByText('Cottagecore')).toBeInTheDocument()
    expect(screen.getByText('Dark Academia')).toBeInTheDocument()
  })

  it('shows "No niches" when column is empty', () => {
    renderWithDnd(
      <KanbanColumn status="archived" niches={[]} onNicheClick={vi.fn()} />
    )
    expect(screen.getByText('No niches')).toBeInTheDocument()
  })

  it('has the correct data-testid', () => {
    renderWithDnd(
      <KanbanColumn status="mining_tokens" niches={[]} onNicheClick={vi.fn()} />
    )
    expect(screen.getByTestId('column-mining_tokens')).toBeInTheDocument()
  })

  it('shows 0 count for empty column', () => {
    renderWithDnd(
      <KanbanColumn status="active" niches={[]} onNicheClick={vi.fn()} />
    )
    expect(screen.getByText('0')).toBeInTheDocument()
  })
})

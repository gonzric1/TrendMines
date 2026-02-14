import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import type { Niche, NicheStatus } from '@/types/niche'
import { NICHE_STATUSES } from '@/types/niche'
import { KanbanBoard, groupNichesByStatus } from './KanbanBoard'

const makeMockNiche = (overrides: Partial<Niche> = {}): Niche => ({
  id: 1,
  trend_signal_id: 10,
  name: 'Test Niche',
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
  ...overrides,
})

const mockNiches: Niche[] = [
  makeMockNiche({ id: 1, name: 'Niche A', status: 'discovered' }),
  makeMockNiche({ id: 2, name: 'Niche B', status: 'discovered' }),
  makeMockNiche({ id: 3, name: 'Niche C', status: 'evaluating' }),
  makeMockNiche({ id: 4, name: 'Niche D', status: 'active' }),
  makeMockNiche({ id: 5, name: 'Niche E', status: 'archived' }),
]

describe('groupNichesByStatus', () => {
  it('groups niches correctly by status', () => {
    const grouped = groupNichesByStatus(mockNiches)

    expect(grouped.discovered).toHaveLength(2)
    expect(grouped.evaluating).toHaveLength(1)
    expect(grouped.mining_tokens).toHaveLength(0)
    expect(grouped.generating_designs).toHaveLength(0)
    expect(grouped.active).toHaveLength(1)
    expect(grouped.declining).toHaveLength(0)
    expect(grouped.archived).toHaveLength(1)
  })

  it('returns empty arrays for all statuses when no niches', () => {
    const grouped = groupNichesByStatus([])
    for (const status of NICHE_STATUSES) {
      expect(grouped[status]).toEqual([])
    }
  })

  it('preserves niche data in groups', () => {
    const grouped = groupNichesByStatus(mockNiches)
    expect(grouped.evaluating[0].name).toBe('Niche C')
  })
})

describe('KanbanBoard', () => {
  it('renders all 7 columns', () => {
    render(
      <KanbanBoard niches={[]} onStatusChange={vi.fn()} onNicheClick={vi.fn()} />
    )

    for (const status of NICHE_STATUSES) {
      expect(screen.getByTestId(`column-${status}`)).toBeInTheDocument()
    }
  })

  it('renders niches in their correct columns', () => {
    render(
      <KanbanBoard
        niches={mockNiches}
        onStatusChange={vi.fn()}
        onNicheClick={vi.fn()}
      />
    )

    expect(screen.getByText('Niche A')).toBeInTheDocument()
    expect(screen.getByText('Niche B')).toBeInTheDocument()
    expect(screen.getByText('Niche C')).toBeInTheDocument()
    expect(screen.getByText('Niche D')).toBeInTheDocument()
    expect(screen.getByText('Niche E')).toBeInTheDocument()
  })

  it('has the kanban-board testid', () => {
    render(
      <KanbanBoard niches={[]} onStatusChange={vi.fn()} onNicheClick={vi.fn()} />
    )
    expect(screen.getByTestId('kanban-board')).toBeInTheDocument()
  })

  it('renders status labels for all columns', () => {
    render(
      <KanbanBoard niches={[]} onStatusChange={vi.fn()} onNicheClick={vi.fn()} />
    )

    const labels = [
      'Discovered',
      'Evaluating',
      'Mining Tokens',
      'Generating Designs',
      'Active',
      'Declining',
      'Archived',
    ]
    for (const label of labels) {
      expect(screen.getByText(label)).toBeInTheDocument()
    }
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import type { Niche } from '@/types/niche'
import { NicheDetailPanel } from './NicheDetailPanel'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
  },
}))

const mockNiche: Niche = {
  id: 1,
  trend_signal_id: 10,
  name: 'Cottagecore Fashion',
  description: 'A cozy aesthetic niche',
  community_type: 'fandom',
  demand_score: 85,
  supply_score: 30,
  demand_supply_ratio: 2.83,
  ao3_works_count: 1500,
  ao3_growth_rate: 0.15,
  etsy_listing_count: 320,
  status: 'evaluating',
  discovered_at: '2026-01-01T00:00:00Z',
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-15T00:00:00Z',
}

describe('NicheDetailPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('is hidden when no niche is selected', () => {
    render(<NicheDetailPanel niche={null} onClose={vi.fn()} />)

    const panel = screen.getByTestId('niche-detail-panel')
    expect(panel.className).toContain('translate-x-full')
  })

  it('is visible when a niche is selected', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    const panel = screen.getByTestId('niche-detail-panel')
    expect(panel.className).toContain('translate-x-0')

    await waitFor(() => {
      expect(api.get).toHaveBeenCalled()
    })
  })

  it('displays niche name and status', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    expect(screen.getByText('Cottagecore Fashion')).toBeInTheDocument()
    expect(screen.getByText('Evaluating')).toBeInTheDocument()

    await waitFor(() => {
      expect(api.get).toHaveBeenCalled()
    })
  })

  it('displays niche description', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    expect(screen.getByText('A cozy aesthetic niche')).toBeInTheDocument()

    await waitFor(() => {
      expect(api.get).toHaveBeenCalled()
    })
  })

  it('calls onClose when close button is clicked', async () => {
    const onClose = vi.fn()
    const user = userEvent.setup()
    vi.mocked(api.get).mockResolvedValue({ data: {} })

    render(<NicheDetailPanel niche={mockNiche} onClose={onClose} />)

    await user.click(screen.getByLabelText('Close detail panel'))
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('fetches scorecard, tokens, and designs on open', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    await waitFor(() => {
      expect(api.get).toHaveBeenCalledWith('/niches/1/scorecard')
      expect(api.get).toHaveBeenCalledWith('/niches/1/tokens')
      expect(api.get).toHaveBeenCalledWith('/niches/1/designs')
    })
  })

  it('displays scorecard data when loaded', async () => {
    vi.mocked(api.get).mockImplementation((url: string) => {
      if (url.includes('/scorecard')) {
        return Promise.resolve({
          data: {
            niche: mockNiche,
            demand_score: 85,
            supply_score: 30,
            demand_supply_ratio: 2.83,
            ao3_metrics: { works_count: 1500, growth_rate: 0.15 },
            etsy_listing_count: 320,
          },
        })
      }
      return Promise.resolve({ data: [] })
    })

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    await waitFor(() => {
      expect(screen.getByText('Scorecard')).toBeInTheDocument()
    })
  })

  it('displays tokens when loaded', async () => {
    vi.mocked(api.get).mockImplementation((url: string) => {
      if (url.includes('/tokens')) {
        return Promise.resolve({
          data: [
            {
              id: 1,
              niche_id: 1,
              name: 'Floral Patterns',
              token_type: 'visual',
              description: '',
              relevance_score: 0.9,
              status: 'active',
              created_at: '',
              updated_at: '',
            },
          ],
        })
      }
      return Promise.resolve({ data: {} })
    })

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    await waitFor(() => {
      expect(screen.getByText('Floral Patterns')).toBeInTheDocument()
    })
  })

  it('shows loading state while fetching details', () => {
    vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

    render(<NicheDetailPanel niche={mockNiche} onClose={vi.fn()} />)

    expect(screen.getByText('Loading details...')).toBeInTheDocument()
  })
})

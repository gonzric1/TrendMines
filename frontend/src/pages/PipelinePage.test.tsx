import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import PipelinePage from './PipelinePage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
  },
}))

const mockNiches = [
  {
    id: 1,
    trend_signal_id: 10,
    name: 'Cottagecore',
    description: 'Cozy aesthetic',
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
    description: 'Scholarly vibes',
    community_type: 'fandom',
    demand_score: 70,
    supply_score: 25,
    demand_supply_ratio: 2.8,
    ao3_works_count: 800,
    ao3_growth_rate: 0.1,
    etsy_listing_count: 200,
    status: 'evaluating',
    discovered_at: '2026-01-05T00:00:00Z',
    created_at: '2026-01-05T00:00:00Z',
    updated_at: '2026-01-05T00:00:00Z',
  },
]

describe('PipelinePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Loading State', () => {
    it('shows loading message while fetching', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<PipelinePage />)
      expect(screen.getByText('Loading pipeline...')).toBeInTheDocument()
    })
  })

  describe('Error State', () => {
    it('displays error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValueOnce(new Error('Network error'))

      render(<PipelinePage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch niches. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })
  })

  describe('Empty State', () => {
    it('shows empty message when no niches exist', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<PipelinePage />)

      await waitFor(() => {
        expect(
          screen.getByText('No niches in the pipeline yet. Create a niche to get started.')
        ).toBeInTheDocument()
      })
    })
  })

  describe('Success State', () => {
    it('renders the kanban board with niches', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockNiches } })

      render(<PipelinePage />)

      await waitFor(() => {
        expect(screen.getByText('Cottagecore')).toBeInTheDocument()
      })
      expect(screen.getByText('Dark Academia')).toBeInTheDocument()
      expect(screen.getByTestId('kanban-board')).toBeInTheDocument()
    })

    it('calls API with per_page=100', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<PipelinePage />)

      expect(api.get).toHaveBeenCalledWith('/niches', { params: { per_page: 100 } })

      await waitFor(() => {
        expect(screen.queryByText('Loading pipeline...')).not.toBeInTheDocument()
      })
    })
  })

  describe('Page Structure', () => {
    it('renders page title and description', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<PipelinePage />)

      expect(screen.getByText('Niche Pipeline')).toBeInTheDocument()
      expect(
        screen.getByText('Drag niches between stages to update their pipeline status')
      ).toBeInTheDocument()

      await waitFor(() => {
        expect(screen.queryByText('Loading pipeline...')).not.toBeInTheDocument()
      })
    })

    it('has a Refresh button', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<PipelinePage />)

      expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument()

      await waitFor(() => {
        expect(screen.queryByText('Loading pipeline...')).not.toBeInTheDocument()
      })
    })

    it('refetches niches on Refresh click', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get)
        .mockResolvedValueOnce({ data: { data: mockNiches } })
        .mockResolvedValueOnce({ data: { data: mockNiches } })

      render(<PipelinePage />)

      await waitFor(() => {
        expect(screen.getByText('Cottagecore')).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', { name: 'Refresh' }))

      expect(api.get).toHaveBeenCalledTimes(2)
    })
  })

  describe('Niche Detail Panel', () => {
    it('renders the detail panel container', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockNiches } })

      render(<PipelinePage />)

      await waitFor(() => {
        expect(screen.getByTestId('niche-detail-panel')).toBeInTheDocument()
      })
    })
  })
})

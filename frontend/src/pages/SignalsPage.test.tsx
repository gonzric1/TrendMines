import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SignalsPage from './SignalsPage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockSignals = [
  {
    id: 1,
    source: 'reddit',
    topic: 'Mechanical Keyboards',
    description: 'Custom keycaps are trending',
    momentum_score: 85.5,
    status: 'watching',
    first_seen: '2024-01-15T10:00:00Z',
    last_updated: '2024-01-20T10:00:00Z',
    raw_data: {},
    community_type: 'fandom',
  },
  {
    id: 2,
    source: 'tiktok',
    topic: 'Desk Setup',
    description: 'Ergonomic accessories gaining traction',
    momentum_score: 42.3,
    status: 'new',
    first_seen: '2024-01-14T08:30:00Z',
    last_updated: '2024-01-19T08:30:00Z',
    raw_data: {},
    community_type: 'professional',
  },
]

describe('SignalsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers({ shouldAdvanceTime: true })
    // Default: history endpoint returns empty for sparklines
    vi.mocked(api.get).mockImplementation((url: string) => {
      if (typeof url === 'string' && url.includes('/history')) {
        return Promise.resolve({ data: { data: [] } })
      }
      return Promise.resolve({ data: { data: mockSignals } })
    })
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('Loading State', () => {
    it('should display loading message when fetching signals', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<SignalsPage />)

      expect(screen.getByText('Loading signals...')).toBeInTheDocument()
    })
  })

  describe('Success State', () => {
    it('should display signal cards when API call succeeds', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      expect(screen.getByText('Custom keycaps are trending')).toBeInTheDocument()
      expect(screen.getByText('Desk Setup')).toBeInTheDocument()
      expect(screen.getByText('Ergonomic accessories gaining traction')).toBeInTheDocument()
    })

    it('should display momentum scores with correct formatting', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('85.5')).toBeInTheDocument()
      })

      expect(screen.getByText('42.3')).toBeInTheDocument()
    })

    it('should display source badges', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        // "Reddit" and "TikTok" appear in both filter toolbar and signal cards
        expect(screen.getAllByText('Reddit').length).toBeGreaterThanOrEqual(1)
      })

      expect(screen.getAllByText('TikTok').length).toBeGreaterThanOrEqual(1)
    })

    it('should render signals in a grid layout', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      const grid = screen.getByText('Mechanical Keyboards').closest('.grid')
      expect(grid).toBeInTheDocument()
    })
  })

  describe('Error State', () => {
    it('should display error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValue(new Error('Network error'))

      render(<SignalsPage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch signals. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })

    it('should not display signals when there is an error', async () => {
      vi.mocked(api.get).mockRejectedValue(new Error('Network error'))

      render(<SignalsPage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch signals. Make sure the backend is running.')
        ).toBeInTheDocument()
      })

      expect(screen.queryByText('Mechanical Keyboards')).not.toBeInTheDocument()
    })
  })

  describe('Empty State', () => {
    it('should display "No signals found" when data is empty', async () => {
      vi.mocked(api.get).mockImplementation((url: string) => {
        if (typeof url === 'string' && url.includes('/history')) {
          return Promise.resolve({ data: { data: [] } })
        }
        return Promise.resolve({ data: { data: [] } })
      })

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('No signals found')).toBeInTheDocument()
      })
    })
  })

  describe('Filter Toolbar', () => {
    it('should render the filter toolbar', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByRole('toolbar', { name: 'Signal filters' })).toBeInTheDocument()
      })
    })

    it('should have source filter buttons', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      // Filter toolbar source buttons
      const toolbar = screen.getByRole('toolbar', { name: 'Signal filters' })
      expect(toolbar).toBeInTheDocument()
    })

    it('should have status and sort selects', async () => {
      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByLabelText('Filter by status')).toBeInTheDocument()
      })

      expect(screen.getByLabelText('Sort signals')).toBeInTheDocument()
    })
  })

  describe('Auto-refresh', () => {
    it('should have auto-refresh toggle checked by default', async () => {
      render(<SignalsPage />)

      const checkbox = screen.getByRole('checkbox')
      expect(checkbox).toBeChecked()
    })

    it('should toggle auto-refresh off when unchecked', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })

      render(<SignalsPage />)

      const checkbox = screen.getByRole('checkbox')
      await user.click(checkbox)

      expect(checkbox).not.toBeChecked()
    })
  })

  describe('Component Structure', () => {
    it('should display page title and description', async () => {
      render(<SignalsPage />)

      expect(screen.getByText('Signal Radar')).toBeInTheDocument()
      expect(
        screen.getByText('Real-time trending topics from various sources')
      ).toBeInTheDocument()
    })

    it('should have a Refresh button', async () => {
      render(<SignalsPage />)

      expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument()
    })

    it('should call API with correct endpoint on mount', () => {
      render(<SignalsPage />)

      expect(api.get).toHaveBeenCalledWith('/trend_signals', {
        params: { sort: 'momentum_score DESC' },
      })
    })
  })
})

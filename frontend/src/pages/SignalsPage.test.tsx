import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SignalsPage from './SignalsPage'
import api from '@/lib/api'

// Mock the API module
vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
  },
}))

describe('SignalsPage', () => {
  const mockSignals = [
    {
      id: 1,
      source: 'Reddit',
      topic: 'Mechanical Keyboards',
      description: 'Custom keycaps are trending',
      momentum_score: 85.5,
      status: 'active',
      first_seen: '2024-01-15T10:00:00Z',
    },
    {
      id: 2,
      source: 'TikTok',
      topic: 'Desk Setup',
      description: 'Ergonomic accessories gaining traction',
      momentum_score: 72.3,
      status: 'trending',
      first_seen: '2024-01-14T08:30:00Z',
    },
  ]

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Loading State', () => {
    it('should display loading message when fetching signals', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<SignalsPage />)

      expect(screen.getByText('Loading signals...')).toBeInTheDocument()
    })
  })

  describe('Success State', () => {
    it('should display signals when API call succeeds', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: mockSignals },
      })

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      expect(screen.getByText('Custom keycaps are trending')).toBeInTheDocument()
      expect(screen.getByText('Desk Setup')).toBeInTheDocument()
      expect(screen.getByText('Ergonomic accessories gaining traction')).toBeInTheDocument()
    })

    it('should display signal metadata correctly', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: mockSignals },
      })

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('Reddit')).toBeInTheDocument()
      })

      expect(screen.getByText('TikTok')).toBeInTheDocument()
      expect(screen.getByText('85.5')).toBeInTheDocument()
      expect(screen.getByText('72.3')).toBeInTheDocument()
      expect(screen.getByText('active')).toBeInTheDocument()
      expect(screen.getByText('trending')).toBeInTheDocument()
    })

    it('should format dates correctly', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: mockSignals },
      })

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      const dateElements = screen.getAllByText((content, element) => {
        return element?.textContent?.includes('First seen:') || false
      })
      expect(dateElements.length).toBeGreaterThan(0)
    })
  })

  describe('Empty State', () => {
    it('should display "No signals found" when data is empty', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: [] },
      })

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByText('No signals found')).toBeInTheDocument()
      })
    })
  })

  describe('Error State', () => {
    it('should display error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValueOnce(new Error('Network error'))

      render(<SignalsPage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch signals. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })

    it('should not display signals when there is an error', async () => {
      vi.mocked(api.get).mockRejectedValueOnce(new Error('Network error'))

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.queryByText('Mechanical Keyboards')).not.toBeInTheDocument()
      })
    })
  })

  describe('User Interactions', () => {
    it('should have a Refresh button', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: mockSignals },
      })

      render(<SignalsPage />)

      await waitFor(() => {
        expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument()
      })
    })

    it('should refetch signals when Refresh button is clicked', async () => {
      const user = userEvent.setup()

      vi.mocked(api.get)
        .mockResolvedValueOnce({
          data: { data: mockSignals },
        })
        .mockResolvedValueOnce({
          data: { data: [...mockSignals, {
            id: 3,
            source: 'AO3',
            topic: 'Fan Fiction',
            description: 'New fandom emerging',
            momentum_score: 90.0,
            status: 'hot',
            first_seen: '2024-01-16T12:00:00Z',
          }] },
        })

      render(<SignalsPage />)

      // Wait for initial load
      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      // Click refresh
      const refreshButton = screen.getByRole('button', { name: 'Refresh' })
      await user.click(refreshButton)

      // Wait for new data
      await waitFor(() => {
        expect(screen.getByText('Fan Fiction')).toBeInTheDocument()
      })

      expect(api.get).toHaveBeenCalledTimes(2)
    })

    it('should show loading state when refreshing', async () => {
      const user = userEvent.setup()

      vi.mocked(api.get)
        .mockResolvedValueOnce({
          data: { data: mockSignals },
        })
        .mockImplementationOnce(() => new Promise(() => {}))

      render(<SignalsPage />)

      // Wait for initial load
      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      // Click refresh
      const refreshButton = screen.getByRole('button', { name: 'Refresh' })
      await user.click(refreshButton)

      // Should show loading
      expect(screen.getByText('Loading signals...')).toBeInTheDocument()
    })

    it('should clear error when refreshing after error', async () => {
      const user = userEvent.setup()

      vi.mocked(api.get)
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValueOnce({
          data: { data: mockSignals },
        })

      render(<SignalsPage />)

      // Wait for error
      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch signals. Make sure the backend is running.')
        ).toBeInTheDocument()
      })

      // Click refresh
      const refreshButton = screen.getByRole('button', { name: 'Refresh' })
      await user.click(refreshButton)

      // Wait for success
      await waitFor(() => {
        expect(screen.getByText('Mechanical Keyboards')).toBeInTheDocument()
      })

      // Error should be gone
      expect(
        screen.queryByText('Failed to fetch signals. Make sure the backend is running.')
      ).not.toBeInTheDocument()
    })
  })

  describe('Component Structure', () => {
    it('should display page title and description', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: [] },
      })

      render(<SignalsPage />)

      expect(screen.getByText('Trend Signals')).toBeInTheDocument()
      expect(
        screen.getByText('Real-time trending topics from various sources')
      ).toBeInTheDocument()
    })

    it('should call API with correct endpoint on mount', () => {
      vi.mocked(api.get).mockResolvedValueOnce({
        data: { data: [] },
      })

      render(<SignalsPage />)

      expect(api.get).toHaveBeenCalledWith('/trend_signals')
    })
  })
})

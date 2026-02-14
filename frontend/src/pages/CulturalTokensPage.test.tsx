import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CulturalTokensPage from './CulturalTokensPage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

const mockTokens = [
  {
    id: 1,
    niche_id: 10,
    token_type: 'quote',
    value: 'Not all who wander are lost',
    status: 'extracted',
    composite_score: 85.3,
    frequency_score: 78.1,
    emotional_intensity: 92.0,
    visual_potential: 70.5,
    uniqueness_score: 65.2,
    source_references: { ao3: 'tag:wanderlust' },
    context: 'Popular in travel and adventure communities',
    created_at: '2026-01-10T00:00:00Z',
    updated_at: '2026-01-10T00:00:00Z',
  },
  {
    id: 2,
    niche_id: 11,
    token_type: 'meme',
    value: 'This is fine',
    status: 'designs_pending',
    composite_score: 55.0,
    frequency_score: 90.2,
    emotional_intensity: 45.0,
    visual_potential: 88.7,
    uniqueness_score: 30.0,
    source_references: null,
    context: 'Ironic humor meme',
    created_at: '2026-01-12T00:00:00Z',
    updated_at: '2026-01-12T00:00:00Z',
  },
]

describe('CulturalTokensPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Loading State', () => {
    it('shows loading message while fetching', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<CulturalTokensPage />)
      expect(screen.getByText('Loading tokens...')).toBeInTheDocument()
    })
  })

  describe('Error State', () => {
    it('displays error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValueOnce(new Error('Network error'))

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch cultural tokens. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })
  })

  describe('Empty State', () => {
    it('shows empty message when no tokens exist', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('No cultural tokens found.')).toBeInTheDocument()
      })
    })
  })

  describe('Success State', () => {
    it('renders the token table with data', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      })
      expect(screen.getByText('This is fine')).toBeInTheDocument()
      expect(screen.getByTestId('token-table')).toBeInTheDocument()
    })

    it('calls API with sort params', () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<CulturalTokensPage />)

      expect(api.get).toHaveBeenCalledWith('/cultural_tokens', {
        params: { per_page: 50, sort: 'composite_score DESC' },
      })
    })
  })

  describe('Table Headers', () => {
    it('renders all column headers', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      })

      const table = screen.getByTestId('token-table')
      expect(within(table).getByText('Value')).toBeInTheDocument()
      expect(within(table).getByText('Type')).toBeInTheDocument()
      expect(within(table).getByText('Frequency')).toBeInTheDocument()
      expect(within(table).getByText('Emotional')).toBeInTheDocument()
      expect(within(table).getByText('Visual')).toBeInTheDocument()
      expect(within(table).getByText('Uniqueness')).toBeInTheDocument()
      expect(within(table).getByText('Score')).toBeInTheDocument()
      expect(within(table).getByText('Status')).toBeInTheDocument()
    })
  })

  describe('Sort by Column Header', () => {
    it('toggles sort direction when clicking the current sort column', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get)
        .mockResolvedValueOnce({ data: { data: mockTokens } })
        .mockResolvedValueOnce({ data: { data: [...mockTokens].reverse() } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      })

      // Click Score header (already sorted by composite_score DESC, should toggle to ASC)
      const table = screen.getByTestId('token-table')
      await user.click(within(table).getByText('Score'))

      await waitFor(() => {
        expect(api.get).toHaveBeenCalledWith('/cultural_tokens', {
          params: { per_page: 50, sort: 'composite_score ASC' },
        })
      })
    })

    it('changes sort column when clicking a different column', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get)
        .mockResolvedValueOnce({ data: { data: mockTokens } })
        .mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      })

      const table = screen.getByTestId('token-table')
      await user.click(within(table).getByText('Frequency'))

      await waitFor(() => {
        expect(api.get).toHaveBeenCalledWith('/cultural_tokens', {
          params: { per_page: 50, sort: 'frequency_score DESC' },
        })
      })
    })
  })

  describe('Filter Toolbar', () => {
    it('renders the filter bar', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByTestId('token-filter-bar')).toBeInTheDocument()
      })
    })

    it('filters tokens by type', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      })

      await user.selectOptions(screen.getByLabelText('Type'), 'quote')

      expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      expect(screen.queryByText('This is fine')).not.toBeInTheDocument()
    })

    it('filters tokens by status', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('This is fine')).toBeInTheDocument()
      })

      await user.selectOptions(screen.getByLabelText('Status'), 'designs_pending')

      expect(screen.getByText('This is fine')).toBeInTheDocument()
      expect(screen.queryByText('Not all who wander are lost')).not.toBeInTheDocument()
    })
  })

  describe('Detail Panel', () => {
    it('renders the detail panel container', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByTestId('token-detail-panel')).toBeInTheDocument()
      })
    })

    it('shows token details when a row is clicked', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: mockTokens } })

      render(<CulturalTokensPage />)

      await waitFor(() => {
        expect(screen.getByText('Not all who wander are lost')).toBeInTheDocument()
      })

      // Click the first row
      const table = screen.getByTestId('token-table')
      const rows = within(table).getAllByRole('row')
      // rows[0] is header, rows[1] is first data row
      await user.click(rows[1])

      const panel = screen.getByTestId('token-detail-panel')
      expect(within(panel).getByText('Popular in travel and adventure communities')).toBeInTheDocument()
      expect(within(panel).getByRole('button', { name: 'Generate Design' })).toBeInTheDocument()
    })
  })

  describe('Page Structure', () => {
    it('renders page title and description', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<CulturalTokensPage />)

      expect(screen.getByText('Cultural Tokens')).toBeInTheDocument()
      expect(
        screen.getByText('Explore and manage extracted cultural tokens')
      ).toBeInTheDocument()
    })

    it('has a Refresh button', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [] } })

      render(<CulturalTokensPage />)

      expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument()
    })
  })
})

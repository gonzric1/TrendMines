import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import DesignReviewPage from './DesignReviewPage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockDesigns = [
  {
    id: 1,
    cultural_token_id: 10,
    design_type: 'graphic',
    style: 'minimalist',
    prompt_used: 'A modern graphic design',
    image_url: 'https://example.com/design1.png',
    generation_cost: 0.05,
    status: 'pending_review',
    created_at: '2024-01-15T10:00:00Z',
    updated_at: '2024-01-15T10:00:00Z',
  },
  {
    id: 2,
    cultural_token_id: 11,
    design_type: 'pattern',
    style: 'retro',
    prompt_used: 'A vintage pattern',
    image_url: null,
    generation_cost: 0.03,
    status: 'approved',
    created_at: '2024-01-14T08:30:00Z',
    updated_at: '2024-01-16T12:00:00Z',
  },
]

describe('DesignReviewPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(api.get).mockResolvedValue({ data: { data: mockDesigns } })
  })

  describe('Loading State', () => {
    it('should display loading message when fetching designs', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<DesignReviewPage />)

      expect(screen.getByText('Loading designs...')).toBeInTheDocument()
    })
  })

  describe('Success State', () => {
    it('should display design cards when API call succeeds', async () => {
      render(<DesignReviewPage />)

      await waitFor(() => {
        expect(screen.getByText('graphic')).toBeInTheDocument()
      })

      expect(screen.getByText('pattern')).toBeInTheDocument()
    })

    it('should display design styles', async () => {
      render(<DesignReviewPage />)

      await waitFor(() => {
        expect(screen.getByText('minimalist')).toBeInTheDocument()
      })

      expect(screen.getByText('retro')).toBeInTheDocument()
    })
  })

  describe('Error State', () => {
    it('should display error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValue(new Error('Network error'))

      render(<DesignReviewPage />)

      await waitFor(() => {
        expect(
          screen.getByText(
            'Failed to fetch designs. Make sure the backend is running.'
          )
        ).toBeInTheDocument()
      })
    })
  })

  describe('Component Structure', () => {
    it('should display page title and description', () => {
      render(<DesignReviewPage />)

      expect(screen.getByText('Design Review')).toBeInTheDocument()
      expect(
        screen.getByText('Review, approve, and manage generated designs')
      ).toBeInTheDocument()
    })

    it('should have a Refresh button', () => {
      render(<DesignReviewPage />)

      expect(
        screen.getByRole('button', { name: 'Refresh' })
      ).toBeInTheDocument()
    })

    it('should call API with correct endpoint on mount', () => {
      render(<DesignReviewPage />)

      expect(api.get).toHaveBeenCalledWith('/designs', {
        params: { sort: 'created_at DESC' },
      })
    })
  })

  describe('Filter Tabs', () => {
    it('should render all filter tabs', async () => {
      render(<DesignReviewPage />)

      await waitFor(() => {
        expect(screen.getByText('All (2)')).toBeInTheDocument()
      })

      expect(screen.getByText('Pending Review (1)')).toBeInTheDocument()
      expect(screen.getByText('Approved (1)')).toBeInTheDocument()
      expect(screen.getByText('Rejected (0)')).toBeInTheDocument()
      expect(screen.getByText('Needs Revision (0)')).toBeInTheDocument()
    })

    it('should show counts per filter tab', async () => {
      render(<DesignReviewPage />)

      await waitFor(() => {
        expect(screen.getByText('All (2)')).toBeInTheDocument()
      })

      expect(screen.getByText('Pending Review (1)')).toBeInTheDocument()
      expect(screen.getByText('Approved (1)')).toBeInTheDocument()
      expect(screen.getByText('Rejected (0)')).toBeInTheDocument()
      expect(screen.getByText('Needs Revision (0)')).toBeInTheDocument()
    })
  })

  describe('Review Progress', () => {
    it('should show review progress when designs are loaded', async () => {
      render(<DesignReviewPage />)

      await waitFor(() => {
        expect(screen.getByText('1 of 2 reviewed')).toBeInTheDocument()
      })
    })
  })
})

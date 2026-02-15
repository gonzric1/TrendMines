import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import ListingPerformancePage from './ListingPerformancePage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockListings = [
  {
    id: 1,
    product_id: 10,
    etsy_listing_id: 'etsy-001',
    title: 'Mountain Sunset Print',
    status: 'active',
    price: 24.99,
    listed_at: '2024-01-10T00:00:00Z',
    created_at: '2024-01-10T00:00:00Z',
    updated_at: '2024-01-20T00:00:00Z',
  },
  {
    id: 2,
    product_id: 11,
    etsy_listing_id: 'etsy-002',
    title: 'Ocean Wave Coaster',
    status: 'draft',
    price: 12.5,
    listed_at: null,
    created_at: '2024-01-12T00:00:00Z',
    updated_at: '2024-01-22T00:00:00Z',
  },
]

const mockMetrics = [
  {
    id: 1,
    listing_id: 1,
    views: 150,
    favorites: 20,
    sales: 5,
    revenue: 124.95,
    fav_view_ratio: 0.133,
    captured_at: '2024-01-20T00:00:00Z',
  },
]

const mockAlerts = [
  {
    listing_id: 1,
    title: 'Mountain Sunset Print',
    alert_type: 'first_sale',
    label: 'scaling',
    icon: 'rocket',
    color: '#22c55e',
    threshold_crossed: 'First sale recorded',
    timestamp: '2024-01-18T00:00:00Z',
    recommended_action: 'Consider increasing inventory',
  },
]

function mockApiSuccess() {
  vi.mocked(api.get).mockImplementation((url: string) => {
    if (typeof url === 'string' && url === '/listings') {
      return Promise.resolve({ data: { data: mockListings, meta: { total: 2, page: 1, per_page: 100, total_pages: 1 } } })
    }
    if (typeof url === 'string' && url === '/listings/alerts') {
      return Promise.resolve({ data: { data: mockAlerts, meta: { total: 1 } } })
    }
    if (typeof url === 'string' && url.match(/\/listings\/\d+\/metrics/)) {
      return Promise.resolve({ data: mockMetrics })
    }
    return Promise.resolve({ data: { data: [] } })
  })
}

describe('ListingPerformancePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Loading State', () => {
    it('should display loading message when fetching listings', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<ListingPerformancePage />)

      expect(screen.getByText('Loading listings...')).toBeInTheDocument()
    })
  })

  describe('Success State', () => {
    it('should display listing data when API call succeeds', async () => {
      mockApiSuccess()

      render(<ListingPerformancePage />)

      await waitFor(() => {
        expect(screen.getAllByText('Mountain Sunset Print').length).toBeGreaterThanOrEqual(1)
      })

      expect(screen.getByText('Ocean Wave Coaster')).toBeInTheDocument()
    })

    it('should display summary stats', async () => {
      mockApiSuccess()

      render(<ListingPerformancePage />)

      await waitFor(() => {
        expect(screen.getByText('Active Listings')).toBeInTheDocument()
      })

      expect(screen.getByText('Total Revenue')).toBeInTheDocument()
      expect(screen.getByText('Avg Fav/View %')).toBeInTheDocument()
      expect(screen.getByText('Alerts')).toBeInTheDocument()
    })

    it('should display alerts panel', async () => {
      mockApiSuccess()

      render(<ListingPerformancePage />)

      await waitFor(() => {
        expect(screen.getByText('First sale recorded')).toBeInTheDocument()
      })

      expect(screen.getByText('Consider increasing inventory')).toBeInTheDocument()
    })
  })

  describe('Error State', () => {
    it('should display error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValue(new Error('Network error'))

      render(<ListingPerformancePage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch listings. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })

    it('should not display listings when there is an error', async () => {
      vi.mocked(api.get).mockRejectedValue(new Error('Network error'))

      render(<ListingPerformancePage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch listings. Make sure the backend is running.')
        ).toBeInTheDocument()
      })

      expect(screen.queryByText('Mountain Sunset Print')).not.toBeInTheDocument()
    })
  })

  describe('Empty State', () => {
    it('should display "No listings found" when data is empty', async () => {
      vi.mocked(api.get).mockImplementation((url: string) => {
        if (typeof url === 'string' && url === '/listings') {
          return Promise.resolve({ data: { data: [], meta: { total: 0, page: 1, per_page: 100, total_pages: 0 } } })
        }
        if (typeof url === 'string' && url === '/listings/alerts') {
          return Promise.resolve({ data: { data: [], meta: { total: 0 } } })
        }
        return Promise.resolve({ data: [] })
      })

      render(<ListingPerformancePage />)

      await waitFor(() => {
        expect(screen.getByText('No listings found')).toBeInTheDocument()
      })
    })
  })

  describe('Component Structure', () => {
    it('should display page title and description', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<ListingPerformancePage />)

      expect(screen.getByText('Listing Performance')).toBeInTheDocument()
      expect(
        screen.getByText('Track listing metrics, traction, and alerts')
      ).toBeInTheDocument()
    })

    it('should have a Refresh button', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<ListingPerformancePage />)

      expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument()
    })

    it('should call API with correct endpoints on mount', () => {
      mockApiSuccess()

      render(<ListingPerformancePage />)

      expect(api.get).toHaveBeenCalledWith('/listings', {
        params: { per_page: 100 },
      })
      expect(api.get).toHaveBeenCalledWith('/listings/alerts')
    })
  })
})

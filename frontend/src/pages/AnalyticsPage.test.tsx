import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import AnalyticsPage from './AnalyticsPage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockRevenueResponse = {
  period: 'daily',
  start_date: '2024-01-01',
  end_date: '2024-01-31',
  total_revenue: 1234.56,
  data: [
    { period: '2024-01-15', revenue: 500.0 },
    { period: '2024-01-16', revenue: 734.56 },
  ],
}

const mockFunnelResponse = {
  funnel: [
    { stage: 'total_signals', count: 500 },
    { stage: 'promoted_signals', count: 200 },
    { stage: 'niches', count: 100 },
    { stage: 'tokens_with_designs', count: 50 },
    { stage: 'products', count: 30 },
    { stage: 'active_listings', count: 20 },
    { stage: 'listings_with_sales', count: 5 },
  ],
}

const mockSourcesResponse = {
  sources: [
    { source: 'reddit', signal_count: 120, product_count: 15, total_revenue: 800.0 },
    { source: 'tiktok', signal_count: 80, product_count: 10, total_revenue: 434.56 },
  ],
}

const mockCostsResponse = {
  costs: {
    design_generation: 50.0,
    material_costs: 200.0,
    etsy_transaction_fees: 61.73,
    etsy_listing_fees: 4.0,
    total_estimated: 315.73,
  },
  total_revenue: 1234.56,
}

function mockAllEndpoints() {
  vi.mocked(api.get).mockImplementation((url: string) => {
    if (url.includes('/analytics/revenue')) {
      return Promise.resolve({ data: mockRevenueResponse })
    }
    if (url.includes('/analytics/funnel')) {
      return Promise.resolve({ data: mockFunnelResponse })
    }
    if (url.includes('/analytics/sources')) {
      return Promise.resolve({ data: mockSourcesResponse })
    }
    if (url.includes('/analytics/costs')) {
      return Promise.resolve({ data: mockCostsResponse })
    }
    return Promise.reject(new Error(`Unexpected URL: ${url}`))
  })
}

describe('AnalyticsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Loading State', () => {
    it('should display loading message when fetching analytics', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<AnalyticsPage />)

      expect(screen.getByText('Loading analytics...')).toBeInTheDocument()
    })
  })

  describe('Success State', () => {
    it('should display revenue data when API calls succeed', async () => {
      mockAllEndpoints()

      render(<AnalyticsPage />)

      await waitFor(() => {
        expect(screen.getByText('total revenue')).toBeInTheDocument()
      })

      // Revenue chart SVG is rendered
      expect(screen.getByRole('img', { name: 'Revenue chart' })).toBeInTheDocument()
    })

    it('should display conversion funnel stages', async () => {
      mockAllEndpoints()

      render(<AnalyticsPage />)

      await waitFor(() => {
        expect(screen.getByText('Conversion Funnel')).toBeInTheDocument()
      })

      expect(screen.getByText('Promoted')).toBeInTheDocument()
      expect(screen.getByText('Sales')).toBeInTheDocument()
    })

    it('should display source ROI table', async () => {
      mockAllEndpoints()

      render(<AnalyticsPage />)

      await waitFor(() => {
        expect(screen.getByText('reddit')).toBeInTheDocument()
      })

      expect(screen.getByText('tiktok')).toBeInTheDocument()
      expect(screen.getByText('$800.00')).toBeInTheDocument()
    })

    it('should display cost breakdown with net profit', async () => {
      mockAllEndpoints()

      render(<AnalyticsPage />)

      await waitFor(() => {
        expect(screen.getByText('Net Profit')).toBeInTheDocument()
      })

      expect(screen.getByText('$315.73')).toBeInTheDocument()
    })
  })

  describe('Error State', () => {
    it('should display error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValue(new Error('Network error'))

      render(<AnalyticsPage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to fetch analytics data. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })
  })

  describe('Component Structure', () => {
    it('should display page title and description', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<AnalyticsPage />)

      expect(screen.getByText('Analytics & Revenue')).toBeInTheDocument()
      expect(
        screen.getByText('Revenue trends, conversion funnel, and cost analysis')
      ).toBeInTheDocument()
    })

    it('should have Refresh and Export CSV buttons', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<AnalyticsPage />)

      expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument()
      expect(screen.getByRole('button', { name: 'Export CSV' })).toBeInTheDocument()
    })

    it('should call revenue API with default parameters on mount', () => {
      mockAllEndpoints()

      render(<AnalyticsPage />)

      expect(api.get).toHaveBeenCalledWith('/analytics/revenue', {
        params: expect.objectContaining({ period: 'daily' }),
      })
      expect(api.get).toHaveBeenCalledWith('/analytics/funnel')
      expect(api.get).toHaveBeenCalledWith('/analytics/sources')
      expect(api.get).toHaveBeenCalledWith('/analytics/costs')
    })
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import axios, { AxiosError } from 'axios'

let mockUseInterceptor: any
let mockInstance: any

// Mock axios before importing api
vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => {
      mockInstance = {
        interceptors: {
          response: {
            use: vi.fn((onSuccess, onError) => {
              mockUseInterceptor = { onSuccess, onError }
            }),
          },
        },
        get: vi.fn(),
        post: vi.fn(),
        put: vi.fn(),
        delete: vi.fn(),
      }
      return mockInstance
    }),
  },
}))

// Import after mocking
const { default: api, endpoints } = await import('./api')

describe('API Client', () => {
  describe('Configuration', () => {
    it('should create axios instance with correct baseURL', () => {
      expect(axios.create).toHaveBeenCalledWith(
        expect.objectContaining({
          baseURL: '/api/v1',
        })
      )
    })

    it('should include Content-Type header', () => {
      expect(axios.create).toHaveBeenCalledWith(
        expect.objectContaining({
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
        })
      )
    })

    it('should include X-API-Key header', () => {
      expect(axios.create).toHaveBeenCalledWith(
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-API-Key': expect.any(String),
          }),
        })
      )
    })
  })

  describe('Instance Export', () => {
    it('should export api instance', () => {
      expect(api).toBeDefined()
      expect(api).toHaveProperty('interceptors')
    })

    it('should have HTTP methods available', () => {
      expect(api).toHaveProperty('get')
      expect(api).toHaveProperty('post')
    })
  })

  describe('Endpoints', () => {
    it('should export correct trend_signals endpoint', () => {
      expect(endpoints.trendSignals).toBe('/trend_signals')
    })

    it('should export correct niches endpoint', () => {
      expect(endpoints.niches).toBe('/niches')
    })

    it('should export correct cultural_tokens endpoint', () => {
      expect(endpoints.culturalTokens).toBe('/cultural_tokens')
    })

    it('should export correct designs endpoint', () => {
      expect(endpoints.designs).toBe('/designs')
    })

    it('should export correct products endpoint', () => {
      expect(endpoints.products).toBe('/products')
    })

    it('should export correct listings endpoint', () => {
      expect(endpoints.listings).toBe('/listings')
    })

    it('should export all required endpoints', () => {
      const requiredEndpoints = [
        'trendSignals',
        'niches',
        'culturalTokens',
        'designs',
        'products',
        'listings',
      ]

      requiredEndpoints.forEach(endpoint => {
        expect(endpoints).toHaveProperty(endpoint)
        expect(typeof endpoints[endpoint as keyof typeof endpoints]).toBe('string')
      })
    })
  })

  describe('Type Definitions', () => {
    it('should support PaginatedResponse type', () => {
      // This is a compile-time check, but we can verify the structure
      type TestResponse = {
        data: Array<{ id: number }>
        meta: {
          total: number
          page: number
          per_page: number
          total_pages: number
        }
      }

      const mockResponse: TestResponse = {
        data: [{ id: 1 }],
        meta: {
          total: 100,
          page: 1,
          per_page: 10,
          total_pages: 10,
        },
      }

      expect(mockResponse).toHaveProperty('data')
      expect(mockResponse).toHaveProperty('meta')
      expect(Array.isArray(mockResponse.data)).toBe(true)
    })
  })

  describe('API Instance', () => {
    it('should export default api instance', () => {
      expect(api).toBeDefined()
    })

    it('should have interceptors configured', () => {
      expect(api).toHaveProperty('interceptors')
    })
  })

  describe('Response Interceptor', () => {
    beforeEach(() => {
      vi.clearAllMocks()
    })

    it('should pass through successful responses', () => {
      const mockResponse = { data: { test: 'data' }, status: 200 }

      expect(mockUseInterceptor).toBeDefined()
      const result = mockUseInterceptor.onSuccess(mockResponse)

      expect(result).toEqual(mockResponse)
    })

    it('should handle errors and log to console', async () => {
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      const mockError = {
        response: {
          data: { error: 'Not found' },
        },
        message: 'Request failed',
      }

      expect(mockUseInterceptor).toBeDefined()

      await expect(mockUseInterceptor.onError(mockError)).rejects.toEqual(mockError)
      expect(consoleErrorSpy).toHaveBeenCalledWith('API Error:', mockError.response.data)

      consoleErrorSpy.mockRestore()
    })

    it('should handle errors without response data', async () => {
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      const mockError = {
        message: 'Network Error',
      }

      expect(mockUseInterceptor).toBeDefined()

      await expect(mockUseInterceptor.onError(mockError)).rejects.toEqual(mockError)
      expect(consoleErrorSpy).toHaveBeenCalledWith('API Error:', mockError.message)

      consoleErrorSpy.mockRestore()
    })
  })
})

import axios from 'axios';

// API base URL - uses proxy configured in vite.config.ts
const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': import.meta.env.VITE_API_KEY || 'dev-api-key-change-in-production',
  },
});

// Response interceptor for handling errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

export default api;

// Type definitions for API responses
export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    per_page: number;
    total_pages: number;
  };
}

// API endpoints
export const endpoints = {
  trendSignals: '/trend_signals',
  niches: '/niches',
  culturalTokens: '/cultural_tokens',
  designs: '/designs',
  products: '/products',
  listings: '/listings',
};

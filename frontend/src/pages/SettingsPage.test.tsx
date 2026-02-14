import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SettingsPage from './SettingsPage'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockSettings = {
  scanning: [
    { key: 'scanning.ao3_frequency', value: 12, description: 'AO3 Scan Frequency (hours)' },
    { key: 'scanning.reddit_frequency', value: 6, description: 'Reddit Scan Frequency (hours)' },
  ],
  scoring: [
    { key: 'scoring.momentum_weight', value: 5, description: 'Momentum Weight' },
    { key: 'scoring.viability_threshold', value: 0.7, description: 'Viability Threshold' },
  ],
  alerts: [
    { key: 'alerts.sales_drop_threshold', value: 0.3, description: 'Sales Drop Threshold' },
  ],
  templates: [
    { key: 'templates.design_prompt_prefix', value: 'Create a design for', description: 'Design Prompt Prefix' },
  ],
  integrations: [
    { key: 'integrations.webhook_url', value: 'https://hooks.example.com/test', description: 'Webhook URL' },
  ],
  api_keys: [
    { key: 'api_keys.etsy_api_key', configured: true, description: 'Etsy Api Key' },
    { key: 'api_keys.openai_api_key', configured: false, description: 'Openai Api Key' },
  ],
}

describe('SettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Loading State', () => {
    it('should display loading message when fetching settings', () => {
      vi.mocked(api.get).mockImplementation(() => new Promise(() => {}))

      render(<SettingsPage />)

      expect(screen.getByText('Loading settings...')).toBeInTheDocument()
    })
  })

  describe('Success State', () => {
    it('should display settings grouped by category', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('Scanning')).toBeInTheDocument()
      })

      expect(screen.getByText('Scoring')).toBeInTheDocument()
      expect(screen.getByText('Alerts')).toBeInTheDocument()
      expect(screen.getByText('Templates')).toBeInTheDocument()
      expect(screen.getByText('Integrations')).toBeInTheDocument()
      expect(screen.getByText('API Keys')).toBeInTheDocument()
    })

    it('should display setting descriptions and values', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('AO3 Scan Frequency (hours)')).toBeInTheDocument()
      })

      expect(screen.getByText('Momentum Weight')).toBeInTheDocument()
      expect(screen.getByText('Sales Drop Threshold')).toBeInTheDocument()
      expect(screen.getByText('Design Prompt Prefix')).toBeInTheDocument()
      expect(screen.getByText('Webhook URL')).toBeInTheDocument()
    })

    it('should show api key configuration status', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('Configured')).toBeInTheDocument()
      })

      expect(screen.getByText('Not Configured')).toBeInTheDocument()
    })

    it('should render Test Connection buttons for api keys', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        const buttons = screen.getAllByRole('button', { name: 'Test Connection' })
        expect(buttons).toHaveLength(2)
      })
    })

    it('should disable Test Connection button for unconfigured keys', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        const buttons = screen.getAllByRole('button', { name: 'Test Connection' })
        // etsy is configured, openai is not
        expect(buttons[0]).not.toBeDisabled()
        expect(buttons[1]).toBeDisabled()
      })
    })
  })

  describe('Error State', () => {
    it('should display error message when API call fails', async () => {
      vi.mocked(api.get).mockRejectedValueOnce(new Error('Network error'))

      render(<SettingsPage />)

      await waitFor(() => {
        expect(
          screen.getByText('Failed to load settings. Make sure the backend is running.')
        ).toBeInTheDocument()
      })
    })
  })

  describe('Empty State', () => {
    it('should display empty message when no settings exist', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: {} })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('No settings found')).toBeInTheDocument()
      })
    })
  })

  describe('Dirty State and Saving', () => {
    it('should have Save Changes button disabled when no changes', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('Scanning')).toBeInTheDocument()
      })

      expect(screen.getByRole('button', { name: 'Save Changes' })).toBeDisabled()
    })

    it('should enable Save Changes button after modifying a setting', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('AO3 Scan Frequency (hours)')).toBeInTheDocument()
      })

      const input = screen.getByDisplayValue('12')
      await user.clear(input)
      await user.type(input, '24')

      expect(screen.getByRole('button', { name: 'Save Changes' })).not.toBeDisabled()
    })

    it('should send only modified settings via PATCH', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })
      vi.mocked(api.patch).mockResolvedValueOnce({ data: { updated: ['scanning.ao3_frequency'] } })
      // Second get for refetch after save
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('AO3 Scan Frequency (hours)')).toBeInTheDocument()
      })

      const input = screen.getByDisplayValue('12')
      await user.clear(input)
      await user.type(input, '24')

      await user.click(screen.getByRole('button', { name: 'Save Changes' }))

      await waitFor(() => {
        expect(api.patch).toHaveBeenCalledWith('/settings', {
          settings: { 'scanning.ao3_frequency': 24 },
        })
      })
    })

    it('should show success message after successful save', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })
      vi.mocked(api.patch).mockResolvedValueOnce({ data: { updated: ['scanning.ao3_frequency'] } })
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('AO3 Scan Frequency (hours)')).toBeInTheDocument()
      })

      const input = screen.getByDisplayValue('12')
      await user.clear(input)
      await user.type(input, '24')

      await user.click(screen.getByRole('button', { name: 'Save Changes' }))

      await waitFor(() => {
        expect(screen.getByText('Settings saved successfully.')).toBeInTheDocument()
      })
    })

    it('should display error on save failure', async () => {
      const user = userEvent.setup()
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })
      vi.mocked(api.patch).mockRejectedValueOnce({
        response: { data: { errors: { 'scanning.ao3_frequency': ['must be positive'] } } },
      })

      render(<SettingsPage />)

      await waitFor(() => {
        expect(screen.getByText('AO3 Scan Frequency (hours)')).toBeInTheDocument()
      })

      const input = screen.getByDisplayValue('12')
      await user.clear(input)
      await user.type(input, '0')

      await user.click(screen.getByRole('button', { name: 'Save Changes' }))

      await waitFor(() => {
        expect(
          screen.getByText('scanning.ao3_frequency: must be positive')
        ).toBeInTheDocument()
      })
    })
  })

  describe('Component Structure', () => {
    it('should display page title and description', async () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      expect(screen.getByText('Settings')).toBeInTheDocument()
      expect(
        screen.getByText('Manage application configuration and integrations')
      ).toBeInTheDocument()
    })

    it('should call API with correct endpoint on mount', () => {
      vi.mocked(api.get).mockResolvedValueOnce({ data: mockSettings })

      render(<SettingsPage />)

      expect(api.get).toHaveBeenCalledWith('/settings')
    })
  })
})

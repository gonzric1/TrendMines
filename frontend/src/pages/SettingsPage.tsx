import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'

interface SettingItem {
  key: string
  value: string | number
  description: string
}

interface ApiKeyItem {
  key: string
  configured: boolean
  description: string
}

interface SettingsResponse {
  scanning: SettingItem[]
  scoring: SettingItem[]
  alerts: SettingItem[]
  templates: SettingItem[]
  integrations: SettingItem[]
  api_keys: ApiKeyItem[]
}

type CategoryKey = 'scanning' | 'scoring' | 'alerts' | 'templates' | 'integrations' | 'api_keys'

const CATEGORY_INFO: Record<CategoryKey, { title: string; description: string }> = {
  scanning: {
    title: 'Scanning',
    description: 'Configure how often each source is scanned for new trends',
  },
  scoring: {
    title: 'Scoring',
    description: 'Adjust weights, thresholds, and minimums for trend scoring',
  },
  alerts: {
    title: 'Alerts',
    description: 'Set thresholds for sales, stock, and return alerts',
  },
  templates: {
    title: 'Templates',
    description: 'Customize prompt and listing templates',
  },
  integrations: {
    title: 'Integrations',
    description: 'Configure webhook URLs and external service connections',
  },
  api_keys: {
    title: 'API Keys',
    description: 'View the configuration status of external API keys',
  },
}

const CATEGORY_ORDER: CategoryKey[] = [
  'scanning',
  'scoring',
  'alerts',
  'templates',
  'integrations',
  'api_keys',
]

function getInputType(key: string): 'integer' | 'float' | 'text' | 'textarea' {
  if (key.startsWith('scanning.')) return 'integer'
  if (key.startsWith('scoring.')) {
    if (key.includes('weight')) return 'integer'
    return 'float'
  }
  if (key.startsWith('alerts.')) return 'float'
  if (key.startsWith('templates.')) return 'textarea'
  return 'text'
}

function getInputProps(key: string): { min?: number; max?: number; step?: number } {
  const type = getInputType(key)
  if (type === 'integer') {
    if (key.includes('weight')) return { min: 1, max: 10, step: 1 }
    return { min: 1, step: 1 }
  }
  if (type === 'float') {
    if (key.includes('threshold') || key.includes('ratio')) return { min: 0, max: 1, step: 0.01 }
    return { min: 0, step: 0.01 }
  }
  return {}
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<SettingsResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [modified, setModified] = useState<Record<string, string | number>>({})
  const [saving, setSaving] = useState(false)
  const [saveMessage, setSaveMessage] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [testingService, setTestingService] = useState<string | null>(null)
  const [testResult, setTestResult] = useState<string | null>(null)

  const fetchSettings = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<SettingsResponse>('/settings')
      setSettings(response.data)
    } catch (err) {
      setError('Failed to load settings. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchSettings()
  }, [])

  const handleChange = (key: string, value: string | number) => {
    setModified((prev) => ({ ...prev, [key]: value }))
    setSaveMessage(null)
    setSaveError(null)
  }

  const getCurrentValue = (key: string, originalValue: string | number): string | number => {
    return key in modified ? modified[key] : originalValue
  }

  const handleSave = async () => {
    if (Object.keys(modified).length === 0) return
    try {
      setSaving(true)
      setSaveError(null)
      setSaveMessage(null)
      await api.patch('/settings', { settings: modified })
      setSaveMessage('Settings saved successfully.')
      setModified({})
      fetchSettings()
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { errors?: Record<string, string[]> } } }
      if (axiosErr.response?.data?.errors) {
        const messages = Object.entries(axiosErr.response.data.errors)
          .map(([k, v]) => `${k}: ${v.join(', ')}`)
          .join('; ')
        setSaveError(messages)
      } else {
        setSaveError('Failed to save settings.')
      }
      console.error(err)
    } finally {
      setSaving(false)
    }
  }

  const handleTestConnection = async (service: string) => {
    try {
      setTestingService(service)
      setTestResult(null)
      const response = await api.post<{ message: string; service: string }>('/settings/test_connection', { service })
      setTestResult(`${response.data.service}: ${response.data.message}`)
    } catch (err) {
      setTestResult(`Failed to test ${service} connection.`)
      console.error(err)
    } finally {
      setTestingService(null)
    }
  }

  const hasChanges = Object.keys(modified).length > 0

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Settings</h1>
          <p className="text-muted-foreground mt-1">
            Manage application configuration and integrations
          </p>
        </div>
        <Button onClick={handleSave} disabled={!hasChanges || saving}>
          {saving ? 'Saving...' : 'Save Changes'}
        </Button>
      </div>

      {saveMessage && (
        <div className="bg-green-500/10 border border-green-500 text-green-700 dark:text-green-400 px-4 py-3 rounded">
          {saveMessage}
        </div>
      )}

      {saveError && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {saveError}
        </div>
      )}

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading settings...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && settings && Object.keys(settings).length === 0 && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">No settings found</p>
        </div>
      )}

      {!loading && !error && settings && (
        <div className="space-y-6">
          {CATEGORY_ORDER.map((category) => {
            const info = CATEGORY_INFO[category]

            if (category === 'api_keys') {
              const keys = settings.api_keys
              if (!keys || keys.length === 0) return null
              return (
                <div key={category} className="border rounded-lg p-6">
                  <h2 className="text-xl font-semibold mb-1">{info.title}</h2>
                  <p className="text-sm text-muted-foreground mb-4">{info.description}</p>
                  <div className="space-y-4">
                    {keys.map((item) => {
                      const serviceName = item.key.replace('api_keys.', '').replace('_api_key', '')
                      return (
                        <div key={item.key} className="flex items-center justify-between">
                          <div>
                            <label className="text-sm font-medium">{item.description}</label>
                            <span
                              className={`ml-3 inline-block px-2 py-1 text-xs font-medium rounded ${
                                item.configured
                                  ? 'bg-green-500/10 text-green-700 dark:text-green-400'
                                  : 'bg-yellow-500/10 text-yellow-700 dark:text-yellow-400'
                              }`}
                            >
                              {item.configured ? 'Configured' : 'Not Configured'}
                            </span>
                          </div>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleTestConnection(serviceName)}
                            disabled={!item.configured || testingService === serviceName}
                          >
                            {testingService === serviceName ? 'Testing...' : 'Test Connection'}
                          </Button>
                        </div>
                      )
                    })}
                  </div>
                  {testResult && (
                    <p className="mt-4 text-sm text-muted-foreground">{testResult}</p>
                  )}
                </div>
              )
            }

            const items = settings[category] as SettingItem[] | undefined
            if (!items || items.length === 0) return null

            return (
              <div key={category} className="border rounded-lg p-6">
                <h2 className="text-xl font-semibold mb-1">{info.title}</h2>
                <p className="text-sm text-muted-foreground mb-4">{info.description}</p>
                <div className="space-y-4">
                  {items.map((item) => {
                    const inputType = getInputType(item.key)
                    const inputProps = getInputProps(item.key)
                    const currentValue = getCurrentValue(item.key, item.value)

                    return (
                      <div key={item.key}>
                        <label className="block text-sm font-medium mb-1">
                          {item.description}
                        </label>
                        {inputType === 'textarea' ? (
                          <textarea
                            className="w-full border rounded-md px-3 py-2 text-sm bg-background"
                            rows={3}
                            value={currentValue}
                            onChange={(e) => handleChange(item.key, e.target.value)}
                          />
                        ) : (
                          <input
                            type={inputType === 'text' ? 'text' : 'number'}
                            className="w-full border rounded-md px-3 py-2 text-sm bg-background"
                            value={currentValue}
                            onChange={(e) => {
                              const val = inputType === 'text' ? e.target.value : Number(e.target.value)
                              handleChange(item.key, val)
                            }}
                            {...inputProps}
                          />
                        )}
                      </div>
                    )
                  })}
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

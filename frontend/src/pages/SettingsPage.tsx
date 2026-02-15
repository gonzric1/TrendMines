import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardContent, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Separator } from '@/components/ui/separator'
import api from '@/lib/api'

interface SettingItem {
  key: string
  value: string | number
  description: string
}

interface ApiKeyItem {
  key: string
  configured: boolean
  source: string | null
  masked_value: string | null
  description: string
  group: string
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
    description: 'Manage API keys for external data sources. Keys are encrypted at rest.',
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

const SERVICE_GROUP_LABELS: Record<string, string> = {
  reddit: 'Reddit',
  tumblr: 'Tumblr',
  google_trends: 'Google Trends (SerpAPI)',
  gemini: 'Google Gemini',
}

const SERVICE_GROUP_ORDER = ['reddit', 'tumblr', 'google_trends', 'gemini']

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

function getSourceBadge(source: string | null) {
  switch (source) {
    case 'database':
      return <Badge variant="default" className="bg-green-600 hover:bg-green-700">Saved in DB</Badge>
    case 'credentials':
      return <Badge variant="secondary">Credentials File</Badge>
    case 'env':
      return <Badge variant="secondary">Environment</Badge>
    default:
      return <Badge variant="outline">Not Configured</Badge>
  }
}

function SettingsSkeletonCards() {
  return (
    <div className="space-y-6">
      {[1, 2, 3].map((i) => (
        <Card key={i}>
          <CardHeader>
            <Skeleton className="h-6 w-32" />
            <Skeleton className="h-4 w-64 mt-1" />
          </CardHeader>
          <CardContent className="space-y-4">
            {[1, 2, 3].map((j) => (
              <div key={j} className="space-y-2">
                <Skeleton className="h-4 w-40" />
                <Skeleton className="h-9 w-full" />
              </div>
            ))}
          </CardContent>
        </Card>
      ))}
    </div>
  )
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<SettingsResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [modified, setModified] = useState<Record<string, string | number>>({})
  const [saving, setSaving] = useState(false)
  const [saveMessage, setSaveMessage] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)

  // API key form state
  const [apiKeyValues, setApiKeyValues] = useState<Record<string, string>>({})
  const [apiKeyVisible, setApiKeyVisible] = useState<Record<string, boolean>>({})
  const [savingApiKeys, setSavingApiKeys] = useState(false)
  const [apiKeySaveMessage, setApiKeySaveMessage] = useState<string | null>(null)
  const [apiKeySaveError, setApiKeySaveError] = useState<string | null>(null)
  const [testingService, setTestingService] = useState<string | null>(null)
  const [testResults, setTestResults] = useState<Record<string, { success: boolean; message: string }>>({})
  const [scanningNow, setScanningNow] = useState(false)
  const [scanMessage, setScanMessage] = useState<string | null>(null)

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

  const handleApiKeyChange = (keyName: string, value: string) => {
    setApiKeyValues((prev) => ({ ...prev, [keyName]: value }))
    setApiKeySaveMessage(null)
    setApiKeySaveError(null)
  }

  const toggleApiKeyVisibility = (keyName: string) => {
    setApiKeyVisible((prev) => ({ ...prev, [keyName]: !prev[keyName] }))
  }

  const handleSaveApiKeys = async () => {
    const nonEmpty = Object.fromEntries(
      Object.entries(apiKeyValues).filter(([, v]) => v.trim() !== '')
    )
    if (Object.keys(nonEmpty).length === 0) return

    try {
      setSavingApiKeys(true)
      setApiKeySaveError(null)
      setApiKeySaveMessage(null)
      const response = await api.patch<{ saved: string[] }>('/settings/api_keys', { api_keys: nonEmpty })
      setApiKeySaveMessage(`Saved ${response.data.saved.length} API key(s).`)
      setApiKeyValues({})
      fetchSettings()
    } catch (err) {
      setApiKeySaveError('Failed to save API keys.')
      console.error(err)
    } finally {
      setSavingApiKeys(false)
    }
  }

  const handleTestConnection = async (group: string) => {
    try {
      setTestingService(group)
      setTestResults((prev) => {
        const next = { ...prev }
        delete next[group]
        return next
      })
      const response = await api.post<{ success: boolean; message: string; service: string }>(
        '/settings/test_connection',
        { service: group }
      )
      setTestResults((prev) => ({ ...prev, [group]: { success: response.data.success, message: response.data.message } }))
    } catch (err) {
      setTestResults((prev) => ({ ...prev, [group]: { success: false, message: `Failed to test ${group} connection.` } }))
      console.error(err)
    } finally {
      setTestingService(null)
    }
  }

  const handleScanNow = async () => {
    try {
      setScanningNow(true)
      setScanMessage(null)
      const response = await api.post<{ queued: boolean; message: string }>('/settings/scan_now')
      setScanMessage(response.data.message)
    } catch (err) {
      setScanMessage('Failed to trigger scan.')
      console.error(err)
    } finally {
      setScanningNow(false)
    }
  }

  const hasChanges = Object.keys(modified).length > 0
  const hasApiKeyChanges = Object.values(apiKeyValues).some((v) => v.trim() !== '')

  // Group API keys by service group
  const groupedApiKeys = (settings?.api_keys || []).reduce<Record<string, ApiKeyItem[]>>((acc, item) => {
    const group = item.group || 'other'
    if (!acc[group]) acc[group] = []
    acc[group].push(item)
    return acc
  }, {})

  // Check if any key in a group is configured
  const isGroupConfigured = (group: string) => {
    return groupedApiKeys[group]?.some((k) => k.configured) || false
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
          <p className="text-muted-foreground mt-1">
            Manage application configuration and integrations
          </p>
        </div>
        <Button onClick={handleSave} disabled={!hasChanges || saving}>
          {saving ? 'Saving...' : 'Save Changes'}
        </Button>
      </div>

      {saveMessage && (
        <Card className="border-green-500/50 bg-green-500/5">
          <CardContent className="py-3 px-4">
            <p className="text-sm font-medium text-green-700 dark:text-green-400">
              {saveMessage}
            </p>
          </CardContent>
        </Card>
      )}

      {saveError && (
        <Card className="border-destructive/50 bg-destructive/5">
          <CardContent className="py-3 px-4">
            <p className="text-sm font-medium text-destructive">
              {saveError}
            </p>
          </CardContent>
        </Card>
      )}

      {loading && <SettingsSkeletonCards />}

      {error && (
        <Card className="border-destructive/50 bg-destructive/5">
          <CardContent className="py-3 px-4">
            <p className="text-sm font-medium text-destructive">
              {error}
            </p>
          </CardContent>
        </Card>
      )}

      {!loading && !error && settings && Object.keys(settings).length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">No settings found</p>
          </CardContent>
        </Card>
      )}

      {!loading && !error && settings && (
        <div className="space-y-6">
          {CATEGORY_ORDER.map((category) => {
            const info = CATEGORY_INFO[category]

            if (category === 'api_keys') {
              const keys = settings.api_keys
              if (!keys || keys.length === 0) return null
              return (
                <Card key={category}>
                  <CardHeader>
                    <CardTitle>{info.title}</CardTitle>
                    <CardDescription>{info.description}</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-6">
                      {SERVICE_GROUP_ORDER.map((group, groupIndex) => {
                        const groupKeys = groupedApiKeys[group]
                        if (!groupKeys) return null

                        const testResult = testResults[group]

                        return (
                          <div key={group}>
                            {groupIndex > 0 && <Separator className="mb-6" />}
                            <div className="flex items-center justify-between mb-4">
                              <h3 className="text-sm font-semibold">{SERVICE_GROUP_LABELS[group] || group}</h3>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => handleTestConnection(group)}
                                disabled={!isGroupConfigured(group) || testingService === group}
                              >
                                {testingService === group ? 'Testing...' : 'Test Connection'}
                              </Button>
                            </div>

                            {testResult && (
                              <div className={`mb-4 p-3 rounded-md text-sm ${testResult.success ? 'bg-green-500/10 text-green-700 dark:text-green-400' : 'bg-destructive/10 text-destructive'}`}>
                                {testResult.message}
                              </div>
                            )}

                            <div className="space-y-3">
                              {groupKeys.map((item) => (
                                <div key={item.key} className="space-y-1.5">
                                  <div className="flex items-center gap-2">
                                    <Label htmlFor={`api-key-${item.key}`} className="text-sm">
                                      {item.description}
                                    </Label>
                                    {getSourceBadge(item.source)}
                                  </div>
                                  <div className="flex gap-2">
                                    <Input
                                      id={`api-key-${item.key}`}
                                      type={apiKeyVisible[item.key] ? 'text' : 'password'}
                                      placeholder={item.masked_value || 'Enter key...'}
                                      value={apiKeyValues[item.key] || ''}
                                      onChange={(e) => handleApiKeyChange(item.key, e.target.value)}
                                      className="font-mono text-sm"
                                    />
                                    <Button
                                      variant="ghost"
                                      size="sm"
                                      onClick={() => toggleApiKeyVisibility(item.key)}
                                      className="shrink-0 px-3"
                                      type="button"
                                    >
                                      {apiKeyVisible[item.key] ? 'Hide' : 'Show'}
                                    </Button>
                                  </div>
                                </div>
                              ))}
                            </div>
                          </div>
                        )
                      })}
                    </div>

                    <Separator className="mt-6 mb-4" />

                    <div className="flex items-center gap-3 flex-wrap">
                      <Button
                        onClick={handleSaveApiKeys}
                        disabled={!hasApiKeyChanges || savingApiKeys}
                      >
                        {savingApiKeys ? 'Saving...' : 'Save API Keys'}
                      </Button>
                      <Button
                        variant="secondary"
                        onClick={handleScanNow}
                        disabled={scanningNow}
                      >
                        {scanningNow ? 'Starting...' : 'Scan Now'}
                      </Button>
                      {apiKeySaveMessage && (
                        <p className="text-sm text-green-700 dark:text-green-400">{apiKeySaveMessage}</p>
                      )}
                      {apiKeySaveError && (
                        <p className="text-sm text-destructive">{apiKeySaveError}</p>
                      )}
                      {scanMessage && (
                        <p className="text-sm text-muted-foreground">{scanMessage}</p>
                      )}
                    </div>
                  </CardContent>
                </Card>
              )
            }

            const items = settings[category] as SettingItem[] | undefined
            if (!items || items.length === 0) return null

            return (
              <Card key={category}>
                <CardHeader>
                  <CardTitle>{info.title}</CardTitle>
                  <CardDescription>{info.description}</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {items.map((item) => {
                      const inputType = getInputType(item.key)
                      const inputProps = getInputProps(item.key)
                      const currentValue = getCurrentValue(item.key, item.value)

                      return (
                        <div key={item.key} className="space-y-2">
                          <Label htmlFor={item.key}>{item.description}</Label>
                          {inputType === 'textarea' ? (
                            <Textarea
                              id={item.key}
                              rows={3}
                              value={currentValue}
                              onChange={(e) => handleChange(item.key, e.target.value)}
                            />
                          ) : (
                            <Input
                              id={item.key}
                              type={inputType === 'text' ? 'text' : 'number'}
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
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}
    </div>
  )
}

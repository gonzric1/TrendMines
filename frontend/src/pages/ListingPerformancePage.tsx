import { useEffect, useState, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import api from '@/lib/api'
import type { PaginatedResponse } from '@/lib/api'
import type {
  Listing,
  MetricSnapshot,
  ListingAlert,
  ListingWithMetrics,
  TractionLabel,
} from '@/types/listing'
import { SummaryStatsRow } from '@/components/listings/SummaryStatsRow'
import { ListingTable } from '@/components/listings/ListingTable'
import { MetricsChart } from '@/components/listings/MetricsChart'
import { AlertsPanel } from '@/components/listings/AlertsPanel'

function deriveTraction(metrics: MetricSnapshot | undefined): TractionLabel {
  if (!metrics) return 'new'
  if (metrics.sales > 0 && metrics.fav_view_ratio >= 0.05) return 'scaling'
  if (metrics.favorites > 0 || metrics.fav_view_ratio >= 0.02) return 'promising'
  if (metrics.views === 0 && metrics.favorites === 0) return 'no_signal'
  return 'new'
}

export default function ListingPerformancePage() {
  const [listings, setListings] = useState<ListingWithMetrics[]>([])
  const [alerts, setAlerts] = useState<ListingAlert[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedListing, setSelectedListing] = useState<ListingWithMetrics | null>(null)
  const [selectedMetrics, setSelectedMetrics] = useState<MetricSnapshot[]>([])

  const fetchData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      const [listingsRes, alertsRes] = await Promise.all([
        api.get<PaginatedResponse<Listing>>('/listings', {
          params: { per_page: 100 },
        }),
        api.get<{ data: ListingAlert[]; meta: { total: number } }>('/listings/alerts'),
      ])

      const allListings = listingsRes.data.data
      const allAlerts = alertsRes.data.data

      // Fetch latest metrics for each listing in parallel
      const enriched = await Promise.all(
        allListings.map(async (listing): Promise<ListingWithMetrics> => {
          try {
            const metricsRes = await api.get<MetricSnapshot[]>(
              `/listings/${listing.id}/metrics`
            )
            const snapshots = metricsRes.data
            const latestMetrics = snapshots.length > 0 ? snapshots[0] : undefined
            return {
              ...listing,
              latestMetrics,
              traction: deriveTraction(latestMetrics),
            }
          } catch {
            return { ...listing, traction: 'new' }
          }
        })
      )

      setListings(enriched)
      setAlerts(allAlerts)
    } catch (err) {
      setError('Failed to fetch listings. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleSelect = useCallback(
    async (listing: ListingWithMetrics) => {
      if (selectedListing?.id === listing.id) {
        setSelectedListing(null)
        setSelectedMetrics([])
        return
      }
      setSelectedListing(listing)
      try {
        const res = await api.get<MetricSnapshot[]>(
          `/listings/${listing.id}/metrics`
        )
        setSelectedMetrics(res.data)
      } catch {
        setSelectedMetrics([])
      }
    },
    [selectedListing]
  )

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Listing Performance</h1>
          <p className="text-muted-foreground mt-1">
            Track listing metrics, traction, and alerts
          </p>
        </div>
        <Button onClick={fetchData}>Refresh</Button>
      </div>

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading listings...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && (
        <>
          <SummaryStatsRow listings={listings} alerts={alerts} />

          <div className="flex gap-6">
            <div className={cn('flex-1 min-w-0', selectedListing ? 'max-w-[65%]' : '')}>
              <ListingTable
                listings={listings}
                selectedId={selectedListing?.id ?? null}
                onSelect={handleSelect}
              />
            </div>

            {selectedListing && (
              <div className="w-[35%] space-y-4">
                <div className="border rounded-lg p-4">
                  <div className="flex justify-between items-start mb-4">
                    <h3 className="text-lg font-semibold">{selectedListing.title}</h3>
                    <button
                      className="text-muted-foreground hover:text-foreground text-sm"
                      onClick={() => {
                        setSelectedListing(null)
                        setSelectedMetrics([])
                      }}
                    >
                      Close
                    </button>
                  </div>
                  <MetricsChart snapshots={selectedMetrics} />
                </div>

                <AlertsPanel
                  alerts={alerts.filter(
                    (a) => a.listing_id === selectedListing.id
                  )}
                />
              </div>
            )}
          </div>

          {!selectedListing && alerts.length > 0 && (
            <AlertsPanel alerts={alerts} />
          )}
        </>
      )}
    </div>
  )
}

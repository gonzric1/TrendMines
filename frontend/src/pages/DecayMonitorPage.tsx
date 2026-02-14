import { useEffect, useState, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import api from '@/lib/api'
import type { PaginatedResponse } from '@/lib/api'
import type { Product, DecayAnalysis, DecayProduct, LifecycleStage } from '@/types/product'
import { ProductLifecycleCard } from '@/components/decay/ProductLifecycleCard'
import { DecayChart } from '@/components/decay/DecayChart'
import { RecommendedActions } from '@/components/decay/RecommendedActions'
import { GraveyardTable } from '@/components/decay/GraveyardTable'

type Tab = 'active' | 'graveyard'

function deriveLifecycleStage(product: Product, decay: DecayAnalysis | null): LifecycleStage {
  if (!decay || decay.recommendation === 'insufficient_data') {
    return product.status === 'prototype' ? 'launching' : 'growing'
  }

  if (decay.decay_score >= 70) return 'urgent'
  if (decay.decay_score >= 40) return 'declining'
  if (decay.decay_score >= 20) return 'plateau'

  const salesTrend = decay.trends.sales?.change_pct ?? 0
  if (salesTrend > 10) return 'growing'
  return product.status === 'prototype' ? 'launching' : 'growing'
}

export default function DecayMonitorPage() {
  const [products, setProducts] = useState<DecayProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<Tab>('active')
  const [selectedProduct, setSelectedProduct] = useState<DecayProduct | null>(null)

  const fetchProducts = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await api.get<PaginatedResponse<Product>>('/products', {
        params: { per_page: 100 },
      })
      const allProducts = response.data.data

      // Fetch decay analysis for each product in parallel
      const enriched = await Promise.all(
        allProducts.map(async (product): Promise<DecayProduct> => {
          try {
            const decayResponse = await api.get<DecayAnalysis>(
              `/products/${product.id}/decay_analysis`
            )
            const decay = decayResponse.data
            return {
              ...product,
              decay,
              lifecycle_stage: deriveLifecycleStage(product, decay),
            }
          } catch {
            return {
              ...product,
              decay: undefined,
              lifecycle_stage: deriveLifecycleStage(product, null),
            }
          }
        })
      )

      setProducts(enriched)
    } catch (err) {
      setError('Failed to fetch products. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchProducts()
  }, [fetchProducts])

  const activeProducts = products.filter((p) => p.status !== 'retired')
  const retiredProducts = products.filter((p) => p.status === 'retired')

  // Sort active products: urgent first, then by decay score descending
  const sortedActive = [...activeProducts].sort((a, b) => {
    const scoreA = a.decay?.decay_score ?? 0
    const scoreB = b.decay?.decay_score ?? 0
    return scoreB - scoreA
  })

  const alerts = sortedActive.filter((p) => (p.decay?.decay_score ?? 0) >= 20)

  const handleProductClick = (product: DecayProduct) => {
    setSelectedProduct(selectedProduct?.id === product.id ? null : product)
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Decay Monitor</h1>
          <p className="text-muted-foreground mt-1">
            Track product lifecycle health and identify declining trends
          </p>
        </div>
        <Button onClick={fetchProducts}>Refresh</Button>
      </div>

      {/* Alert summary */}
      {!loading && alerts.length > 0 && (
        <div className="flex gap-3 flex-wrap">
          {alerts.filter((p) => (p.decay?.decay_score ?? 0) >= 70).length > 0 && (
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-md bg-red-100 dark:bg-red-950/30 text-red-700 dark:text-red-300 text-sm font-medium">
              <span className="inline-block w-2 h-2 rounded-full bg-red-500" />
              {alerts.filter((p) => (p.decay?.decay_score ?? 0) >= 70).length} urgent
            </div>
          )}
          {alerts.filter((p) => {
            const s = p.decay?.decay_score ?? 0
            return s >= 40 && s < 70
          }).length > 0 && (
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-md bg-orange-100 dark:bg-orange-950/30 text-orange-700 dark:text-orange-300 text-sm font-medium">
              <span className="inline-block w-2 h-2 rounded-full bg-orange-500" />
              {alerts.filter((p) => {
                const s = p.decay?.decay_score ?? 0
                return s >= 40 && s < 70
              }).length} declining
            </div>
          )}
          {alerts.filter((p) => {
            const s = p.decay?.decay_score ?? 0
            return s >= 20 && s < 40
          }).length > 0 && (
            <div className="flex items-center gap-2 px-3 py-1.5 rounded-md bg-yellow-100 dark:bg-yellow-950/30 text-yellow-700 dark:text-yellow-300 text-sm font-medium">
              <span className="inline-block w-2 h-2 rounded-full bg-yellow-500" />
              {alerts.filter((p) => {
                const s = p.decay?.decay_score ?? 0
                return s >= 20 && s < 40
              }).length} watch
            </div>
          )}
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b">
        <button
          className={cn(
            'px-4 py-2 text-sm font-medium border-b-2 transition-colors -mb-px',
            activeTab === 'active'
              ? 'border-primary text-foreground'
              : 'border-transparent text-muted-foreground hover:text-foreground'
          )}
          onClick={() => setActiveTab('active')}
        >
          Active Products ({activeProducts.length})
        </button>
        <button
          className={cn(
            'px-4 py-2 text-sm font-medium border-b-2 transition-colors -mb-px',
            activeTab === 'graveyard'
              ? 'border-primary text-foreground'
              : 'border-transparent text-muted-foreground hover:text-foreground'
          )}
          onClick={() => setActiveTab('graveyard')}
        >
          Graveyard ({retiredProducts.length})
        </button>
      </div>

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading products...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && activeTab === 'active' && (
        <div className="flex gap-6">
          {/* Product cards grid */}
          <div className={cn('flex-1', selectedProduct ? 'max-w-[60%]' : '')}>
            {sortedActive.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-muted-foreground">No active products found</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {sortedActive.map((product) => (
                  <ProductLifecycleCard
                    key={product.id}
                    product={product}
                    onClick={handleProductClick}
                  />
                ))}
              </div>
            )}
          </div>

          {/* Detail panel */}
          {selectedProduct && selectedProduct.status !== 'retired' && (
            <div className="w-[40%] space-y-4">
              <div className="border rounded-lg p-4">
                <div className="flex justify-between items-start mb-4">
                  <h3 className="text-lg font-semibold">{selectedProduct.name}</h3>
                  <button
                    className="text-muted-foreground hover:text-foreground text-sm"
                    onClick={() => setSelectedProduct(null)}
                  >
                    Close
                  </button>
                </div>

                {selectedProduct.decay && selectedProduct.decay.recommendation !== 'insufficient_data' && (
                  <DecayChart decay={selectedProduct.decay} />
                )}
              </div>

              <RecommendedActions product={selectedProduct} />
            </div>
          )}
        </div>
      )}

      {!loading && !error && activeTab === 'graveyard' && (
        <GraveyardTable products={retiredProducts} />
      )}
    </div>
  )
}

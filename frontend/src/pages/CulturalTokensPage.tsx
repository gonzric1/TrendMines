import { useEffect, useState, useCallback, useMemo } from 'react'
import { Button } from '@/components/ui/button'
import api from '@/lib/api'
import type { PaginatedResponse } from '@/lib/api'
import type {
  CulturalTokenFull,
  TokenType,
  TokenStatus,
  SortColumn,
  SortDirection,
} from '@/types/cultural-token'
import { TokenTable } from '@/components/tokens/TokenTable'
import { TokenFilterBar } from '@/components/tokens/TokenFilterBar'
import { TokenDetailPanel } from '@/components/tokens/TokenDetailPanel'

export default function CulturalTokensPage() {
  const [tokens, setTokens] = useState<CulturalTokenFull[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedToken, setSelectedToken] = useState<CulturalTokenFull | null>(null)
  const [sortColumn, setSortColumn] = useState<SortColumn>('composite_score')
  const [sortDirection, setSortDirection] = useState<SortDirection>('DESC')
  const [typeFilter, setTypeFilter] = useState<TokenType | 'all'>('all')
  const [statusFilter, setStatusFilter] = useState<TokenStatus | 'all'>('all')

  const fetchTokens = useCallback(async (column: SortColumn, direction: SortDirection) => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<PaginatedResponse<CulturalTokenFull>>(
        '/cultural_tokens',
        { params: { per_page: 50, sort: `${column} ${direction}` } }
      )
      setTokens(response.data.data)
    } catch (err) {
      setError('Failed to fetch cultural tokens. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchTokens(sortColumn, sortDirection)
  }, [fetchTokens, sortColumn, sortDirection])

  const handleSort = useCallback(
    (column: SortColumn) => {
      if (column === sortColumn) {
        setSortDirection((prev) => (prev === 'ASC' ? 'DESC' : 'ASC'))
      } else {
        setSortColumn(column)
        setSortDirection('DESC')
      }
    },
    [sortColumn]
  )

  const handleSelect = useCallback((token: CulturalTokenFull) => {
    setSelectedToken(token)
  }, [])

  const handleClosePanel = useCallback(() => {
    setSelectedToken(null)
  }, [])

  const filteredTokens = useMemo(() => {
    return tokens.filter((t) => {
      if (typeFilter !== 'all' && t.token_type !== typeFilter) return false
      if (statusFilter !== 'all' && t.status !== statusFilter) return false
      return true
    })
  }, [tokens, typeFilter, statusFilter])

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Cultural Tokens</h1>
          <p className="text-muted-foreground mt-1">
            Explore and manage extracted cultural tokens
          </p>
        </div>
        <Button onClick={() => fetchTokens(sortColumn, sortDirection)}>Refresh</Button>
      </div>

      <TokenFilterBar
        typeFilter={typeFilter}
        statusFilter={statusFilter}
        onTypeChange={setTypeFilter}
        onStatusChange={setStatusFilter}
      />

      {loading && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading tokens...</p>
        </div>
      )}

      {error && (
        <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded">
          {error}
        </div>
      )}

      {!loading && !error && filteredTokens.length === 0 && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">No cultural tokens found.</p>
        </div>
      )}

      {!loading && !error && filteredTokens.length > 0 && (
        <TokenTable
          tokens={filteredTokens}
          selectedId={selectedToken?.id ?? null}
          sortColumn={sortColumn}
          sortDirection={sortDirection}
          onSort={handleSort}
          onSelect={handleSelect}
        />
      )}

      <TokenDetailPanel token={selectedToken} onClose={handleClosePanel} />
    </div>
  )
}

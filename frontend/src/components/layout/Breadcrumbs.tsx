import { Link, useLocation } from 'react-router-dom'
import { ChevronRight, Home } from 'lucide-react'
import { cn } from '@/lib/utils'

// Map paths to readable labels
const pathLabels: Record<string, string> = {
  '/': 'Signal Radar',
  '/signals': 'Signals',
  '/pipeline': 'Niche Pipeline',
  '/tokens': 'Cultural Tokens',
  '/designs': 'Designs',
  '/products': 'Products',
  '/listings': 'Listings',
  '/printers': 'Printers',
  '/analytics': 'Analytics',
  '/settings': 'Settings',
}

export function Breadcrumbs() {
  const location = useLocation()
  const pathSegments = location.pathname.split('/').filter(Boolean)

  // For home page, show just the home icon
  if (pathSegments.length === 0) {
    return (
      <div className="flex items-center gap-2">
        <Home className="h-4 w-4 text-muted-foreground" />
        <span className="text-sm font-medium text-foreground">Signal Radar</span>
      </div>
    )
  }

  // Build breadcrumb trail
  const breadcrumbs: { path: string; label: string; isLast: boolean }[] = []

  // Add home
  breadcrumbs.push({
    path: '/',
    label: 'Home',
    isLast: false,
  })

  // Add current path segments
  let accumulatedPath = ''
  pathSegments.forEach((segment, index) => {
    accumulatedPath += `/${segment}`
    breadcrumbs.push({
      path: accumulatedPath,
      label: pathLabels[accumulatedPath] || segment,
      isLast: index === pathSegments.length - 1,
    })
  })

  return (
    <nav aria-label="Breadcrumb" className="flex items-center gap-2">
      {breadcrumbs.map((crumb, index) => (
        <div key={crumb.path} className="flex items-center gap-2">
          {index > 0 && (
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          )}
          {crumb.isLast ? (
            <span className="text-sm font-medium text-foreground">
              {crumb.label}
            </span>
          ) : (
            <Link
              to={crumb.path}
              className={cn(
                'flex items-center gap-1 text-sm font-medium text-muted-foreground hover:text-foreground'
              )}
            >
              {index === 0 && <Home className="h-4 w-4" />}
              {crumb.label}
            </Link>
          )}
        </div>
      ))}
    </nav>
  )
}

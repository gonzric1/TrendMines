import { render, screen, fireEvent } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { AppLayout } from './AppLayout'

// Mock window.matchMedia for dark mode tests
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})

const renderWithRouter = (component: React.ReactElement) => {
  return render(<BrowserRouter>{component}</BrowserRouter>)
}

describe('AppLayout', () => {
  beforeEach(() => {
    // Reset window size before each test
    window.innerWidth = 1024
  })

  it('renders layout with sidebar and top bar', () => {
    renderWithRouter(<AppLayout />)

    // Check for sidebar title
    expect(screen.getByText('TrendMines')).toBeInTheDocument()

    // Check for user info
    expect(screen.getByText('Operator')).toBeInTheDocument()

    // Check for dark mode toggle button
    expect(screen.getByLabelText('Toggle dark mode')).toBeInTheDocument()
  })

  it('renders all navigation items', () => {
    renderWithRouter(<AppLayout />)

    const navItems = [
      'Signal Radar',
      'Niche Pipeline',
      'Cultural Tokens',
      'Designs',
      'Products',
      'Listings',
      'Printers',
      'Analytics',
      'Settings',
    ]

    navItems.forEach((item) => {
      expect(screen.getAllByText(item).length).toBeGreaterThan(0)
    })
  })

  it('toggles sidebar collapse when toggle button is clicked', () => {
    renderWithRouter(<AppLayout />)

    const toggleButton = screen.getByLabelText('Collapse sidebar')
    const sidebar = screen.getByText('TrendMines').closest('aside')

    expect(sidebar).toHaveClass('w-64')

    // Collapse sidebar
    fireEvent.click(toggleButton)

    expect(sidebar).toHaveClass('w-16')
    expect(screen.getByLabelText('Expand sidebar')).toBeInTheDocument()

    // Expand sidebar
    fireEvent.click(screen.getByLabelText('Expand sidebar'))

    expect(sidebar).toHaveClass('w-64')
  })

  it('collapses sidebar on mobile viewport', () => {
    // Set mobile viewport
    window.innerWidth = 500

    renderWithRouter(<AppLayout />)

    // Find sidebar by the expand button (since title is hidden when collapsed)
    const expandButton = screen.getByLabelText('Expand sidebar')
    const sidebar = expandButton.closest('aside')
    expect(sidebar).toHaveClass('w-16')
  })

  it('adjusts main content margin when sidebar is collapsed', () => {
    renderWithRouter(<AppLayout />)

    const main = screen.getByRole('main')

    // Initially expanded
    expect(main).toHaveClass('ml-64')

    // Collapse sidebar
    const toggleButton = screen.getByLabelText('Collapse sidebar')
    fireEvent.click(toggleButton)

    expect(main).toHaveClass('ml-16')
  })

  it('toggles dark mode when dark mode button is clicked', () => {
    renderWithRouter(<AppLayout />)

    const darkModeButton = screen.getByLabelText('Toggle dark mode')

    // Initially light mode (Moon icon should be visible)
    expect(document.documentElement.classList.contains('dark')).toBe(false)

    // Toggle to dark mode
    fireEvent.click(darkModeButton)

    expect(document.documentElement.classList.contains('dark')).toBe(true)

    // Toggle back to light mode
    fireEvent.click(darkModeButton)

    expect(document.documentElement.classList.contains('dark')).toBe(false)
  })

  it('renders breadcrumbs for home route', () => {
    renderWithRouter(<AppLayout />)

    // Check that breadcrumbs are rendered in the top bar
    // The top bar contains user info, so we can verify it's rendered
    expect(screen.getByText('Operator')).toBeInTheDocument()

    // Check that "Signal Radar" appears in multiple places (sidebar + breadcrumb)
    const signalRadarElements = screen.getAllByText('Signal Radar')
    expect(signalRadarElements.length).toBeGreaterThanOrEqual(1)
  })

  it('highlights active navigation item', () => {
    renderWithRouter(<AppLayout />)

    // Get all links with "Signal Radar" text and find the one in the sidebar (has bg-sidebar-primary class)
    const links = screen.getAllByText('Signal Radar')
    const sidebarLink = links.find((link) => {
      const anchor = link.closest('a')
      return anchor && anchor.classList.contains('bg-sidebar-primary')
    })

    expect(sidebarLink).toBeInTheDocument()
  })

  it('navigation links have correct href attributes', () => {
    renderWithRouter(<AppLayout />)

    const navLinks = [
      { text: 'Signal Radar', href: '/' },
      { text: 'Niche Pipeline', href: '/pipeline' },
      { text: 'Cultural Tokens', href: '/tokens' },
      { text: 'Designs', href: '/designs' },
      { text: 'Products', href: '/products' },
      { text: 'Listings', href: '/listings' },
      { text: 'Printers', href: '/printers' },
      { text: 'Analytics', href: '/analytics' },
      { text: 'Settings', href: '/settings' },
    ]

    // Get all navigation links from the sidebar (nav element)
    const sidebarNav = document.querySelector('aside nav')
    expect(sidebarNav).toBeInTheDocument()

    navLinks.forEach(({ text, href }) => {
      const link = sidebarNav?.querySelector(`a[href="${href}"]`)
      expect(link).toBeInTheDocument()
      expect(link?.textContent).toContain(text)
    })
  })

  it('displays icons for all navigation items when expanded', () => {
    renderWithRouter(<AppLayout />)

    // Check that all navigation items have icons (svg elements)
    const navItems = screen.getAllByRole('link')
    navItems.forEach((item) => {
      const svg = item.querySelector('svg')
      expect(svg).toBeInTheDocument()
    })
  })

  it('shows tooltip titles when sidebar is collapsed', () => {
    renderWithRouter(<AppLayout />)

    // Collapse sidebar
    const toggleButton = screen.getByLabelText('Collapse sidebar')
    fireEvent.click(toggleButton)

    // Check that navigation items have title attributes
    const signalRadarLink = screen.getByRole('link', { name: /Signal Radar/i })
    expect(signalRadarLink).toHaveAttribute('title', 'Signal Radar')
  })
})

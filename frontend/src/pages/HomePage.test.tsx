import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import HomePage from './HomePage'

describe('HomePage', () => {
  describe('Page Content', () => {
    it('should render the main heading', () => {
      render(<HomePage />)

      expect(screen.getByText('TrendMines Dashboard')).toBeInTheDocument()
    })

    it('should render the description', () => {
      render(<HomePage />)

      expect(
        screen.getByText('Product discovery pipeline for your Etsy 3D printing business')
      ).toBeInTheDocument()
    })
  })

  describe('Call-to-Action Buttons', () => {
    it('should render "Get Started" button', () => {
      render(<HomePage />)

      expect(screen.getByRole('button', { name: 'Get Started' })).toBeInTheDocument()
    })

    it('should render "Learn More" button', () => {
      render(<HomePage />)

      expect(screen.getByRole('button', { name: 'Learn More' })).toBeInTheDocument()
    })
  })

  describe('Feature Cards', () => {
    it('should render Signal Radar card', () => {
      render(<HomePage />)

      expect(screen.getByText('Signal Radar')).toBeInTheDocument()
      expect(
        screen.getByText('Track trending topics across AO3, Reddit, TikTok, and more')
      ).toBeInTheDocument()
    })

    it('should render Niche Pipeline card', () => {
      render(<HomePage />)

      expect(screen.getByText('Niche Pipeline')).toBeInTheDocument()
      expect(
        screen.getByText('Identify and evaluate passionate niche communities')
      ).toBeInTheDocument()
    })

    it('should render Product Catalog card', () => {
      render(<HomePage />)

      expect(screen.getByText('Product Catalog')).toBeInTheDocument()
      expect(
        screen.getByText('Manage your 3D printed products and listings')
      ).toBeInTheDocument()
    })

    it('should render all three feature cards', () => {
      render(<HomePage />)

      const cards = [
        'Signal Radar',
        'Niche Pipeline',
        'Product Catalog',
      ]

      cards.forEach(cardTitle => {
        expect(screen.getByText(cardTitle)).toBeInTheDocument()
      })
    })
  })

  describe('Component Structure', () => {
    it('should render without crashing', () => {
      const { container } = render(<HomePage />)

      expect(container).toBeTruthy()
    })

    it('should have proper heading hierarchy', () => {
      render(<HomePage />)

      const mainHeading = screen.getByRole('heading', { level: 1 })
      expect(mainHeading).toHaveTextContent('TrendMines Dashboard')

      const subHeadings = screen.getAllByRole('heading', { level: 3 })
      expect(subHeadings).toHaveLength(3)
    })
  })
})

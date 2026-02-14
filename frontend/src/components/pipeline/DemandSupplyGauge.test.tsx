import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { DemandSupplyGauge } from './DemandSupplyGauge'

describe('DemandSupplyGauge', () => {
  it('renders N/A when ratio is null', () => {
    render(<DemandSupplyGauge ratio={null} />)
    expect(screen.getByText('N/A')).toBeInTheDocument()
  })

  it('renders N/A when ratio is undefined', () => {
    render(<DemandSupplyGauge ratio={undefined} />)
    expect(screen.getByText('N/A')).toBeInTheDocument()
  })

  it('renders formatted ratio with x suffix', () => {
    render(<DemandSupplyGauge ratio={2.75} />)
    expect(screen.getByText('2.8x')).toBeInTheDocument()
  })

  it('applies green color for ratio >= 3.0', () => {
    const { container } = render(<DemandSupplyGauge ratio={3.5} />)
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-green')
  })

  it('applies yellow color for ratio >= 1.5 and < 3.0', () => {
    const { container } = render(<DemandSupplyGauge ratio={2.0} />)
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-yellow')
  })

  it('applies red color for ratio < 1.5', () => {
    const { container } = render(<DemandSupplyGauge ratio={0.8} />)
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-red')
  })

  it('applies green at exactly 3.0 boundary', () => {
    const { container } = render(<DemandSupplyGauge ratio={3.0} />)
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-green')
  })

  it('applies yellow at exactly 1.5 boundary', () => {
    const { container } = render(<DemandSupplyGauge ratio={1.5} />)
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-yellow')
  })

  it('includes a title attribute with full precision', () => {
    render(<DemandSupplyGauge ratio={2.567} />)
    expect(screen.getByTitle('Demand/Supply Ratio: 2.57')).toBeInTheDocument()
  })
})

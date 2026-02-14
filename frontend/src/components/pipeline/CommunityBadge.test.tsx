import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { CommunityBadge } from './CommunityBadge'

describe('CommunityBadge', () => {
  it('renders badge with fandom type', () => {
    const { container } = render(<CommunityBadge type="fandom" />)
    expect(screen.getByText('fandom')).toBeInTheDocument()
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-purple')
  })

  it('renders badge with activist type', () => {
    const { container } = render(<CommunityBadge type="activist" />)
    expect(screen.getByText('activist')).toBeInTheDocument()
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-red')
  })

  it('renders badge with meme type', () => {
    const { container } = render(<CommunityBadge type="meme" />)
    expect(screen.getByText('meme')).toBeInTheDocument()
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-yellow')
  })

  it('renders badge with professional type', () => {
    const { container } = render(<CommunityBadge type="professional" />)
    expect(screen.getByText('professional')).toBeInTheDocument()
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-blue')
  })

  it('renders gray fallback for unknown community type', () => {
    const { container } = render(<CommunityBadge type="unknown_type" />)
    expect(screen.getByText('unknown_type')).toBeInTheDocument()
    const el = container.firstChild as HTMLElement
    expect(el.className).toContain('bg-gray')
  })

  it('renders nothing when type is null', () => {
    const { container } = render(<CommunityBadge type={null} />)
    expect(container.firstChild).toBeNull()
  })

  it('renders nothing when type is undefined', () => {
    const { container } = render(<CommunityBadge type={undefined} />)
    expect(container.firstChild).toBeNull()
  })
})

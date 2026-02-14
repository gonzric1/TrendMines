import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from './button'

describe('Button', () => {
  describe('Basic Rendering', () => {
    it('should render button with text', () => {
      render(<Button>Click me</Button>)

      expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument()
    })

    it('should render as a button element by default', () => {
      const { container } = render(<Button>Test</Button>)

      expect(container.querySelector('button')).toBeInTheDocument()
    })
  })

  describe('Variants', () => {
    it('should apply default variant classes', () => {
      render(<Button>Default</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('bg-primary')
    })

    it('should apply destructive variant classes', () => {
      render(<Button variant="destructive">Delete</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('bg-destructive')
    })

    it('should apply outline variant classes', () => {
      render(<Button variant="outline">Outline</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('border')
    })

    it('should apply secondary variant classes', () => {
      render(<Button variant="secondary">Secondary</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('bg-secondary')
    })

    it('should apply ghost variant classes', () => {
      render(<Button variant="ghost">Ghost</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('hover:bg-accent')
    })

    it('should apply link variant classes', () => {
      render(<Button variant="link">Link</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('underline-offset-4')
    })
  })

  describe('Sizes', () => {
    it('should apply default size classes', () => {
      render(<Button>Default Size</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('h-9')
    })

    it('should apply small size classes', () => {
      render(<Button size="sm">Small</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('h-8')
    })

    it('should apply large size classes', () => {
      render(<Button size="lg">Large</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('h-10')
    })

    it('should apply icon size classes', () => {
      render(<Button size="icon" aria-label="Icon button">X</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('h-9')
      expect(button.className).toContain('w-9')
    })
  })

  describe('Props Handling', () => {
    it('should handle onClick events', async () => {
      const user = userEvent.setup()
      const handleClick = vi.fn()

      render(<Button onClick={handleClick}>Click me</Button>)
      const button = screen.getByRole('button')

      await user.click(button)

      expect(handleClick).toHaveBeenCalledTimes(1)
    })

    it('should handle disabled state', () => {
      render(<Button disabled>Disabled</Button>)
      const button = screen.getByRole('button')

      expect(button).toBeDisabled()
    })

    it('should apply custom className', () => {
      render(<Button className="custom-class">Custom</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('custom-class')
    })

    it('should forward HTML button attributes', () => {
      render(<Button type="submit" name="submit-btn">Submit</Button>)
      const button = screen.getByRole('button')

      expect(button).toHaveAttribute('type', 'submit')
      expect(button).toHaveAttribute('name', 'submit-btn')
    })

    it('should not call onClick when disabled', async () => {
      const user = userEvent.setup()
      const handleClick = vi.fn()

      render(<Button onClick={handleClick} disabled>Click me</Button>)
      const button = screen.getByRole('button')

      await user.click(button)

      expect(handleClick).not.toHaveBeenCalled()
    })
  })

  describe('asChild Prop', () => {
    it('should render as child component when asChild is true', () => {
      render(
        <Button asChild>
          <a href="/test">Link Button</a>
        </Button>
      )

      const link = screen.getByRole('link')
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/test')
    })

    it('should apply button classes to child component', () => {
      render(
        <Button asChild variant="outline">
          <a href="/test">Link</a>
        </Button>
      )

      const link = screen.getByRole('link')
      expect(link.className).toContain('border')
    })
  })

  describe('Variant and Size Combinations', () => {
    it('should apply both variant and size classes', () => {
      render(<Button variant="destructive" size="lg">Large Delete</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('bg-destructive')
      expect(button.className).toContain('h-10')
    })

    it('should handle outline variant with small size', () => {
      render(<Button variant="outline" size="sm">Small Outline</Button>)
      const button = screen.getByRole('button')

      expect(button.className).toContain('border')
      expect(button.className).toContain('h-8')
    })
  })

  describe('Accessibility', () => {
    it('should have button role', () => {
      render(<Button>Accessible</Button>)

      expect(screen.getByRole('button')).toBeInTheDocument()
    })

    it('should support aria-label', () => {
      render(<Button aria-label="Close dialog">X</Button>)

      expect(screen.getByLabelText('Close dialog')).toBeInTheDocument()
    })

    it('should be keyboard accessible', async () => {
      const user = userEvent.setup()
      const handleClick = vi.fn()

      render(<Button onClick={handleClick}>Press me</Button>)
      const button = screen.getByRole('button')

      button.focus()
      await user.keyboard('{Enter}')

      expect(handleClick).toHaveBeenCalled()
    })
  })

  describe('Display Name', () => {
    it('should have correct display name for debugging', () => {
      expect(Button.displayName).toBe('Button')
    })
  })
})

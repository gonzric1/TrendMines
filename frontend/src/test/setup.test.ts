import { describe, it, expect } from 'vitest'

describe('Vitest Setup', () => {
  it('should run basic assertions', () => {
    expect(true).toBe(true)
  })

  it('should have jest-dom matchers available', () => {
    const div = document.createElement('div')
    div.textContent = 'Hello World'
    document.body.appendChild(div)

    expect(div).toBeInTheDocument()
    expect(div).toHaveTextContent('Hello World')

    document.body.removeChild(div)
  })
})

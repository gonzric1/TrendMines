import { useEffect } from 'react'
import type { Design } from '@/types/design'

interface UseKeyboardNavigationOptions {
  designs: Design[]
  selectedIndex: number
  onNavigate: (index: number) => void
  onApprove: () => void
  onReject: () => void
  onRegenerate: () => void
  onToggleCompare: () => void
  onClose: () => void
  enabled: boolean
}

export function useKeyboardNavigation({
  designs,
  selectedIndex,
  onNavigate,
  onApprove,
  onReject,
  onRegenerate,
  onToggleCompare,
  onClose,
  enabled,
}: UseKeyboardNavigationOptions) {
  useEffect(() => {
    if (!enabled) return

    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if user is typing in an input
      if (
        e.target instanceof HTMLInputElement ||
        e.target instanceof HTMLTextAreaElement
      ) {
        return
      }

      switch (e.key) {
        case 'a':
          e.preventDefault()
          onApprove()
          break
        case 'x':
          e.preventDefault()
          onReject()
          break
        case 'r':
          e.preventDefault()
          onRegenerate()
          break
        case 'ArrowLeft':
          e.preventDefault()
          if (selectedIndex > 0) {
            onNavigate(selectedIndex - 1)
          }
          break
        case 'ArrowRight':
          e.preventDefault()
          if (selectedIndex < designs.length - 1) {
            onNavigate(selectedIndex + 1)
          }
          break
        case ' ':
          e.preventDefault()
          onToggleCompare()
          break
        case 'Escape':
          e.preventDefault()
          onClose()
          break
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [
    enabled,
    designs.length,
    selectedIndex,
    onNavigate,
    onApprove,
    onReject,
    onRegenerate,
    onToggleCompare,
    onClose,
  ])
}

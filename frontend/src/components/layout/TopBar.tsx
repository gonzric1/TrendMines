import { Moon, Sun, User } from 'lucide-react'
import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'
import { Breadcrumbs } from './Breadcrumbs'

interface TopBarProps {
  isCollapsed: boolean
}

export function TopBar({ isCollapsed }: TopBarProps) {
  const [isDark, setIsDark] = useState(() => {
    // Check system preference on mount
    if (typeof window !== 'undefined') {
      return (
        window.matchMedia &&
        window.matchMedia('(prefers-color-scheme: dark)').matches
      )
    }
    return false
  })

  useEffect(() => {
    // Apply dark mode class to document
    if (isDark) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }, [isDark])

  const toggleDarkMode = () => {
    setIsDark(!isDark)
  }

  return (
    <header
      className={cn(
        'fixed right-0 top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-background px-6 transition-all duration-300',
        isCollapsed ? 'left-16' : 'left-64'
      )}
    >
      {/* Breadcrumbs */}
      <Breadcrumbs />

      {/* Right side: User info and dark mode toggle */}
      <div className="flex items-center gap-4">
        {/* Dark Mode Toggle */}
        <button
          onClick={toggleDarkMode}
          className="rounded-md p-2 hover:bg-accent"
          aria-label="Toggle dark mode"
        >
          {isDark ? (
            <Sun className="h-5 w-5 text-foreground" />
          ) : (
            <Moon className="h-5 w-5 text-foreground" />
          )}
        </button>

        {/* User Info */}
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary">
            <User className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-sm font-medium text-foreground">Operator</span>
        </div>
      </div>
    </header>
  )
}

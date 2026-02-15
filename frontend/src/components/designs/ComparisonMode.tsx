import type { Design } from '@/types/design'

interface ComparisonModeProps {
  left: Design
  right: Design
  onClose: () => void
}

function DesignPanel({ design, label }: { design: Design; label: string }) {
  return (
    <div className="flex-1 space-y-3">
      <p className="text-sm font-medium text-muted-foreground">{label}</p>
      <div className="aspect-square bg-muted rounded-lg overflow-hidden flex items-center justify-center">
        {design.image_url ? (
          <img
            src={design.image_url}
            alt={`Design ${design.id}`}
            className="w-full h-full object-contain"
          />
        ) : (
          <span className="text-muted-foreground text-sm">No image</span>
        )}
      </div>
      <div className="space-y-1 text-sm">
        <p>
          <span className="text-muted-foreground">Type:</span>{' '}
          <span className="capitalize">{design.design_type}</span>
        </p>
        {design.style && (
          <p>
            <span className="text-muted-foreground">Style:</span>{' '}
            {design.style}
          </p>
        )}
        <p>
          <span className="text-muted-foreground">Status:</span>{' '}
          <span className="capitalize">
            {design.status.replace('_', ' ')}
          </span>
        </p>
      </div>
    </div>
  )
}

export function ComparisonMode({ left, right, onClose }: ComparisonModeProps) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/80"
      onClick={onClose}
    >
      <div
        className="bg-background border rounded-lg p-6 w-full max-w-4xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">Compare Designs</h3>
          <button
            className="text-muted-foreground hover:text-foreground text-sm"
            onClick={onClose}
          >
            Close (Space)
          </button>
        </div>
        <div className="flex gap-6">
          <DesignPanel design={left} label="Current" />
          <div className="w-px bg-border" />
          <DesignPanel design={right} label="Adjacent" />
        </div>
      </div>
    </div>
  )
}

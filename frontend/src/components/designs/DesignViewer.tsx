import { Button } from '@/components/ui/button'
import type { Design } from '@/types/design'

interface DesignViewerProps {
  design: Design
  hasPrev: boolean
  hasNext: boolean
  onPrev: () => void
  onNext: () => void
  onApprove: () => void
  onReject: () => void
  onRegenerate: () => void
  onClose: () => void
}

export function DesignViewer({
  design,
  hasPrev,
  hasNext,
  onPrev,
  onNext,
  onApprove,
  onReject,
  onRegenerate,
  onClose,
}: DesignViewerProps) {
  return (
    <div
      className="fixed inset-0 z-40 flex items-center justify-center bg-black/80"
      onClick={onClose}
    >
      <div
        className="bg-background border rounded-lg w-full max-w-3xl max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Navigation arrows */}
        <div className="flex items-center gap-2 p-4">
          <button
            className="text-muted-foreground hover:text-foreground disabled:opacity-30"
            disabled={!hasPrev}
            onClick={onPrev}
            aria-label="Previous design"
          >
            &larr; Prev
          </button>
          <div className="flex-1" />
          <button
            className="text-muted-foreground hover:text-foreground text-sm"
            onClick={onClose}
          >
            Close (Esc)
          </button>
          <div className="flex-1" />
          <button
            className="text-muted-foreground hover:text-foreground disabled:opacity-30"
            disabled={!hasNext}
            onClick={onNext}
            aria-label="Next design"
          >
            Next &rarr;
          </button>
        </div>

        {/* Image */}
        <div className="px-4">
          <div className="aspect-video bg-muted rounded-lg overflow-hidden flex items-center justify-center">
            {design.image_url ? (
              <img
                src={design.image_url}
                alt={`Design ${design.id}`}
                className="w-full h-full object-contain"
              />
            ) : (
              <span className="text-muted-foreground">No image available</span>
            )}
          </div>
        </div>

        {/* Details */}
        <div className="p-4 space-y-3">
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <span className="text-muted-foreground">Type:</span>{' '}
              <span className="capitalize">{design.design_type}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Status:</span>{' '}
              <span className="capitalize">
                {design.status.replace('_', ' ')}
              </span>
            </div>
            {design.style && (
              <div>
                <span className="text-muted-foreground">Style:</span>{' '}
                {design.style}
              </div>
            )}
            {design.generation_cost !== null && (
              <div>
                <span className="text-muted-foreground">Cost:</span>{' '}
                ${design.generation_cost.toFixed(2)}
              </div>
            )}
          </div>

          {design.prompt_used && (
            <div className="text-sm">
              <p className="text-muted-foreground mb-1">Prompt:</p>
              <p className="bg-muted rounded p-2 text-xs">
                {design.prompt_used}
              </p>
            </div>
          )}

          {/* Actions */}
          <div className="flex gap-2 pt-2">
            <Button
              className="bg-green-600 hover:bg-green-700 text-white"
              onClick={onApprove}
            >
              Approve (A)
            </Button>
            <Button variant="destructive" onClick={onReject}>
              Reject (X)
            </Button>
            <Button
              className="bg-blue-600 hover:bg-blue-700 text-white"
              onClick={onRegenerate}
            >
              Regenerate (R)
            </Button>
          </div>

          {/* Keyboard hints */}
          <p className="text-xs text-muted-foreground">
            Keyboard: A approve, X reject, R regenerate, Arrow keys navigate,
            Space compare, Esc close
          </p>
        </div>
      </div>
    </div>
  )
}

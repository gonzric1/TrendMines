import { useState } from 'react'
import { Button } from '@/components/ui/button'
import type { Design } from '@/types/design'

interface RegenerateDialogProps {
  design: Design
  onConfirm: (templateId?: number) => void
  onCancel: () => void
}

export function RegenerateDialog({
  design,
  onConfirm,
  onCancel,
}: RegenerateDialogProps) {
  const [templateId, setTemplateId] = useState('')

  const handleConfirm = () => {
    const id = templateId.trim() ? parseInt(templateId, 10) : undefined
    onConfirm(id && !isNaN(id) ? id : undefined)
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      onClick={onCancel}
    >
      <div
        className="bg-background border rounded-lg p-6 w-full max-w-md space-y-4"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 className="text-lg font-semibold">Regenerate Design</h3>
        <p className="text-sm text-muted-foreground">
          This will queue design #{design.id} for regeneration.
        </p>
        <div className="space-y-2">
          <label
            htmlFor="template-id"
            className="text-sm font-medium"
          >
            Template ID (optional)
          </label>
          <input
            id="template-id"
            type="number"
            className="w-full border rounded-md px-3 py-2 text-sm bg-background"
            placeholder="Leave empty for default"
            value={templateId}
            onChange={(e) => setTemplateId(e.target.value)}
          />
        </div>
        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={onCancel}>
            Cancel
          </Button>
          <Button onClick={handleConfirm}>Regenerate</Button>
        </div>
      </div>
    </div>
  )
}

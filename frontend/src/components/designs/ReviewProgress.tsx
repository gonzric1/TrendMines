import type { Design } from '@/types/design'

interface ReviewProgressProps {
  designs: Design[]
}

export function ReviewProgress({ designs }: ReviewProgressProps) {
  const total = designs.length
  if (total === 0) return null

  const approved = designs.filter((d) => d.status === 'approved').length
  const rejected = designs.filter((d) => d.status === 'rejected').length
  const reviewed = approved + rejected
  const approvedPct = (approved / total) * 100
  const rejectedPct = (rejected / total) * 100

  return (
    <div className="space-y-2">
      <div className="flex justify-between text-sm">
        <span className="text-muted-foreground">
          {reviewed} of {total} reviewed
        </span>
        <span className="text-muted-foreground">
          {Math.round((reviewed / total) * 100)}%
        </span>
      </div>
      <div className="h-2 rounded-full bg-muted overflow-hidden flex">
        {approvedPct > 0 && (
          <div
            className="h-full bg-green-500 transition-all"
            style={{ width: `${approvedPct}%` }}
          />
        )}
        {rejectedPct > 0 && (
          <div
            className="h-full bg-red-500 transition-all"
            style={{ width: `${rejectedPct}%` }}
          />
        )}
      </div>
      <div className="flex gap-4 text-xs text-muted-foreground">
        <span className="flex items-center gap-1">
          <span className="inline-block w-2 h-2 rounded-full bg-green-500" />
          {approved} approved
        </span>
        <span className="flex items-center gap-1">
          <span className="inline-block w-2 h-2 rounded-full bg-red-500" />
          {rejected} rejected
        </span>
        <span className="flex items-center gap-1">
          <span className="inline-block w-2 h-2 rounded-full bg-muted-foreground/30" />
          {total - reviewed} pending
        </span>
      </div>
    </div>
  )
}

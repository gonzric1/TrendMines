import { Button } from '@/components/ui/button'

export default function HomePage() {
  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">TrendMines Dashboard</h1>
      <p className="text-muted-foreground text-lg">
        Product discovery pipeline for your Etsy 3D printing business
      </p>

      <div className="flex gap-4">
        <Button>Get Started</Button>
        <Button variant="outline">Learn More</Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
        <div className="p-6 border rounded-lg">
          <h3 className="font-semibold text-lg mb-2">Signal Radar</h3>
          <p className="text-sm text-muted-foreground">
            Track trending topics across AO3, Reddit, TikTok, and more
          </p>
        </div>

        <div className="p-6 border rounded-lg">
          <h3 className="font-semibold text-lg mb-2">Niche Pipeline</h3>
          <p className="text-sm text-muted-foreground">
            Identify and evaluate passionate niche communities
          </p>
        </div>

        <div className="p-6 border rounded-lg">
          <h3 className="font-semibold text-lg mb-2">Product Catalog</h3>
          <p className="text-sm text-muted-foreground">
            Manage your 3D printed products and listings
          </p>
        </div>
      </div>
    </div>
  )
}

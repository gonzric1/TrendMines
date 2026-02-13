# TrendMines Frontend

React + TypeScript + Vite frontend for the TrendMines product discovery dashboard.

## Tech Stack

- **React 19** with TypeScript
- **Vite** - Fast build tool
- **Tailwind CSS** - Utility-first CSS framework
- **shadcn/ui** - Beautiful, accessible component library
- **React Router** - Client-side routing
- **Axios** - HTTP client for API calls

## Getting Started

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

The app will be available at `http://localhost:5173`

## Project Structure

```
src/
├── components/
│   └── ui/           # shadcn/ui components
├── lib/
│   ├── api.ts        # API client wrapper
│   └── utils.ts      # Utility functions
├── pages/            # Route pages
│   ├── HomePage.tsx
│   └── SignalsPage.tsx
├── App.tsx           # Main app with routing
└── main.tsx          # Entry point
```

## API Configuration

The frontend connects to the Rails backend API at `http://localhost:3000`

Create a `.env` file for configuration:

```bash
VITE_API_KEY=dev-api-key-change-in-production
```

API requests are automatically proxied through Vite (see `vite.config.ts`)

## shadcn/ui Components

Add new components from shadcn/ui:

```bash
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add table
# etc...
```

See [shadcn/ui docs](https://ui.shadcn.com/) for available components

## Development

- Vite dev server includes HMR (Hot Module Replacement)
- Tailwind CSS classes are available globally
- Use `@/` alias for imports from `src/`

## Building for Production

```bash
npm run build
```

Output will be in the `dist/` directory

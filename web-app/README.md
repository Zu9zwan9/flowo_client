# Flowo - Task Management Web Application

A beautiful task management application with calendar integration, built with Next.js, React, and HeroUI, following Apple Human Interface Guidelines.

## Features

- **Task Management**: Create, edit, and delete tasks with priorities, deadlines, and categories
- **Calendar Integration**: View tasks in a monthly calendar view
- **Time Tracking**: Track time spent on tasks with start, pause, and stop functionality
- **Subtasks**: Break down tasks into smaller subtasks
- **Dynamic Theming**: Light and dark mode with dynamic colors based on Apple HIG
- **Responsive Design**: Works on desktop, tablet, and mobile devices

## Tech Stack

- **Framework**: [Next.js](https://nextjs.org/) (App Router)
- **UI Library**: [React](https://reactjs.org/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **Icons**: [Heroicons](https://heroicons.com/)
- **State Management**: [Zustand](https://github.com/pmndrs/zustand)
- **Date Handling**: [date-fns](https://date-fns.org/)
- **TypeScript**: For type safety and better developer experience

## Getting Started

### Prerequisites

- Node.js 18.x or later
- npm or yarn

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/flowo-web.git
cd flowo-web
```

2. Install dependencies
```bash
npm install
# or
yarn install
```

3. Run the development server
```bash
npm run dev
# or
yarn dev
```

4. Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## Project Structure

```
web-app/
├── public/              # Static assets
├── src/
│   ├── app/             # Next.js app router pages
│   │   ├── auth/        # Authentication pages
│   │   ├── dashboard/   # Dashboard and main app pages
│   │   ├── layout.tsx   # Root layout
│   │   └── page.tsx     # Landing page
│   ├── components/      # React components
│   │   ├── Calendar/    # Calendar components
│   │   ├── Header.tsx   # App header
│   │   ├── TaskListItem.tsx # Task list item
│   │   └── ThemeProvider.tsx # Theme provider
│   ├── hooks/           # Custom React hooks
│   ├── store/           # Zustand store
│   │   ├── useTaskStore.ts    # Task state management
│   │   └── useSettingsStore.ts # Settings state management
│   ├── types/           # TypeScript type definitions
│   │   └── models.ts    # Data models
│   └── utils/           # Utility functions
│       └── colors.ts    # Color utilities for Apple HIG
└── tailwind.config.js   # Tailwind CSS configuration
```

## Design Principles

This application follows Apple's Human Interface Guidelines (HIG) for a clean, minimal, and intuitive user experience:

- **Clarity**: The design emphasizes content with clean interfaces and minimal decoration
- **Deference**: The UI helps users understand and interact with content while not competing with it
- **Depth**: Visual layers and realistic motion convey hierarchy and position

## Color System

The application uses Apple's color system with dynamic colors that adapt to light and dark mode:

- **Primary Colors**: Blue, Green, Indigo, Orange, Pink, Purple, Red, Teal, Yellow
- **System Colors**: For backgrounds, separators, and text
- **Dynamic Colors**: Colors adapt based on the system appearance (light/dark mode)

## Accessibility

The application is designed with accessibility in mind:

- **Color Contrast**: All text meets WCAG AA standards for contrast
- **Keyboard Navigation**: All interactive elements are keyboard accessible
- **Screen Readers**: Proper ARIA labels and semantic HTML
- **Reduced Motion**: Option to reduce motion for users who prefer less animation
- **Text Size Adjustment**: Option to adjust text size for better readability

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Heroicons](https://heroicons.com/)
- [Zustand Documentation](https://github.com/pmndrs/zustand)

import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Inter, Playfair_Display } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/ThemeProvider";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Flowo - Revolutionizing Planning for Neurodivergent Minds",
  description: "A revolutionary planning tool designed for ADHD and neurodivergent users, transforming how they organize their lives with AI-powered adaptive features.",
  keywords: "ADHD, neurodivergent, planning tool, task management, AI, adaptive planning, executive function",
  openGraph: {
    title: "Flowo - Revolutionizing Planning for Neurodivergent Minds",
    description: "A revolutionary planning tool designed for ADHD and neurodivergent users, transforming how they organize their lives with AI-powered adaptive features.",
    images: ['/og-image.jpg'],
    type: 'website',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/locomotive-scroll@4.1.4/dist/locomotive-scroll.min.css" />
        <script src="https://cdn.jsdelivr.net/npm/locomotive-scroll@4.1.4/dist/locomotive-scroll.min.js" defer></script>
        <script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js" defer></script>
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} ${inter.variable} ${playfair.variable} antialiased`}
      >
        <ThemeProvider>
          <div id="smooth-wrapper">
            <div id="smooth-content">
              {children}
            </div>
          </div>
        </ThemeProvider>
        <script dangerouslySetInnerHTML={{
          __html: `
            document.addEventListener('DOMContentLoaded', () => {
              const scroll = new LocomotiveScroll({
                el: document.querySelector('#smooth-content'),
                smooth: true,
                smartphone: { smooth: true },
                tablet: { smooth: true }
              });
            });
          `
        }} />
      </body>
    </html>
  );
}

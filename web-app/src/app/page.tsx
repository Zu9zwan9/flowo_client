'use client';

import React from 'react';
import Link from 'next/link';
import { useTheme } from '@/components/ThemeProvider';
import AnimatedBrain from '@/components/AnimatedBrain';
import {
  CheckCircleIcon,
  CalendarIcon,
  ClockIcon,
  ArrowRightIcon,
  UserGroupIcon,
  StarIcon,
  BoltIcon,
  SparklesIcon
} from '@heroicons/react/24/outline';

export default function Home() {
  const { colors, isDarkMode } = useTheme();

  // Dynamic styles
  const containerStyle = {
    backgroundColor: isDarkMode ? '#000' : '#f5f5f7',
    color: colors.text,
  };

  const cardStyle = {
    backgroundColor: isDarkMode ? 'rgba(30, 30, 30, 0.8)' : 'rgba(255, 255, 255, 0.8)',
    borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
    backdropFilter: 'blur(10px)',
  };

  const buttonStyle = {
    backgroundColor: colors.primary,
    color: '#fff',
  };

  const secondaryButtonStyle = {
    borderColor: colors.primary,
    color: colors.primary,
  };

  const highlightStyle = {
    color: colors.primary,
  };

  return (
    <div style={containerStyle} className="min-h-screen">
      {/* Header */}
      <header className="py-4 px-6 flex items-center justify-between">
        <div className="flex items-center">
          <span className="text-2xl font-bold" style={{ color: colors.primary }}>Flowo</span>
        </div>

        <div className="flex items-center space-x-4">
          <Link
            href="/about"
            className="px-4 py-2 rounded-md transition-colors"
          >
            About Us
          </Link>

          <Link
            href="/auth/signin"
            className="px-4 py-2 rounded-md border-2 transition-colors"
            style={secondaryButtonStyle}
          >
            Sign In
          </Link>

          <Link
            href="/auth/signup"
            className="px-4 py-2 rounded-md transition-colors"
            style={buttonStyle}
          >
            Sign Up
          </Link>
        </div>
      </header>

      {/* Hero Section - Awwwards-style */}
      <section
        className="min-h-screen flex flex-col justify-center relative overflow-hidden"
        style={{
          background: isDarkMode
            ? `linear-gradient(135deg, rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.2), rgba(0, 0, 0, 0.95))`
            : `linear-gradient(135deg, rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.15), rgba(255, 255, 255, 0.95))`
        }}
      >
        {/* Animated background elements */}
        <div className="absolute top-0 left-0 w-full h-full">
          <div className="absolute top-[10%] left-[5%] w-64 h-64 rounded-full opacity-20"
            style={{
              background: colors.gradient,
              filter: 'blur(80px)',
              animation: 'float 8s ease-in-out infinite'
            }}
          ></div>
          <div className="absolute bottom-[15%] right-[10%] w-80 h-80 rounded-full opacity-10"
            style={{
              background: colors.gradientAlt,
              filter: 'blur(100px)',
              animation: 'float 10s ease-in-out infinite 1s'
            }}
          ></div>
          <div className="absolute top-[40%] right-[25%] w-40 h-40 rounded-full opacity-15"
            style={{
              background: `linear-gradient(to right, ${colors.primary}, ${colors.accent})`,
              filter: 'blur(60px)',
              animation: 'float 7s ease-in-out infinite 0.5s'
            }}
          ></div>
        </div>

        {/* Main content */}
        <div className="container mx-auto px-6 py-20 md:py-32 relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div className="order-2 lg:order-1 text-left">
              <div className="inline-block px-4 py-1 mb-6 rounded-full"
                style={{
                  background: `linear-gradient(90deg, ${colors.primary}22, ${colors.secondary}22)`,
                  border: `1px solid ${colors.primary}33`,
                  backdropFilter: 'blur(10px)'
                }}
              >
                <span className="text-sm font-medium" style={{ color: colors.primary }}>
                  Revolutionary Planning Tool
                </span>
              </div>

              <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight mb-6" style={{ lineHeight: '1.1' }}>
                <span className="block">Transforming Planning for</span>
                <span style={{
                  background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                  textFillColor: 'transparent'
                }}>
                  Neurodivergent Minds
                </span>
              </h1>

              <p className="text-xl md:text-2xl mb-8 max-w-xl opacity-90">
                A revolutionary AI-powered planning platform designed specifically for ADHD and neurodivergent users,
                with <span className="font-semibold">$2.8B</span> market opportunity.
              </p>

              <div className="flex flex-wrap gap-4 mb-10">
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: colors.primary }}></div>
                  <span className="text-sm font-medium">500+ Beta Users</span>
                </div>
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: colors.secondary }}></div>
                  <span className="text-sm font-medium">93% Retention Rate</span>
                </div>
                <div className="flex items-center">
                  <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: colors.accent }}></div>
                  <span className="text-sm font-medium">AI-Powered Personalization</span>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row gap-4">
                <Link
                  href="/dashboard"
                  className="px-8 py-4 rounded-md text-lg flex items-center justify-center transition-all transform hover:scale-105"
                  style={{
                    background: colors.gradient,
                    color: '#fff',
                    boxShadow: `0 10px 25px -5px ${colors.primary}66`
                  }}
                >
                  Invest in Flowo
                  <ArrowRightIcon className="w-5 h-5 ml-2" />
                </Link>

                <Link
                  href="#market-opportunity"
                  className="px-8 py-4 rounded-md text-lg border flex items-center justify-center transition-all"
                  style={{
                    borderColor: colors.primary,
                    color: colors.primary,
                    backdropFilter: 'blur(10px)',
                    background: `${colors.primary}11`
                  }}
                >
                  Market Opportunity
                </Link>
              </div>
            </div>

            <div className="order-1 lg:order-2 flex justify-center">
              <div className="relative">
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-[120%] h-[120%] rounded-full"
                    style={{
                      background: `radial-gradient(circle, ${colors.primary}22 0%, transparent 70%)`,
                      animation: 'pulse 4s ease-in-out infinite'
                    }}
                  ></div>
                </div>

                <div className="relative z-10 transform hover:scale-105 transition-transform duration-700">
                  <AnimatedBrain width={500} height={400} className="mx-auto" />
                </div>

                <div className="absolute -bottom-10 left-1/2 transform -translate-x-1/2 w-[90%] h-20 bg-black opacity-10 blur-xl rounded-full"></div>
              </div>
            </div>
          </div>

          {/* Scroll indicator */}
          <div className="absolute bottom-10 left-1/2 transform -translate-x-1/2 flex flex-col items-center">
            <span className="text-sm mb-2 opacity-70">Scroll to explore</span>
            <div className="w-6 h-10 border-2 rounded-full flex justify-center p-1"
              style={{ borderColor: colors.primary }}
            >
              <div className="w-1 h-2 rounded-full bg-primary animate-bounce"
                style={{ backgroundColor: colors.primary }}
              ></div>
            </div>
          </div>
        </div>
      </section>

      {/* Market Opportunity Section */}
      <section id="market-opportunity" className="py-24 px-6" style={{
        background: isDarkMode
          ? 'linear-gradient(to bottom, #000000, #111111)'
          : 'linear-gradient(to bottom, #ffffff, #f8f9fa)'
      }}>
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-block px-4 py-1 mb-4 rounded-full"
              style={{
                background: `linear-gradient(90deg, ${colors.primary}22, ${colors.secondary}22)`,
                border: `1px solid ${colors.primary}33`,
                backdropFilter: 'blur(10px)'
              }}
            >
              <span className="text-sm font-medium" style={{ color: colors.primary }}>
                Investment Opportunity
              </span>
            </div>

            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Tapping into a <span style={{
                background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
                textFillColor: 'transparent'
              }}>$2.8 Billion</span> Market
            </h2>

            <p className="text-xl max-w-3xl mx-auto opacity-80">
              The intersection of neurodiversity and productivity tools represents a massive untapped opportunity
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center mb-20">
            <div>
              <div className="relative" style={{
                height: '400px',
                background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
                backdropFilter: 'blur(10px)',
                borderRadius: '16px',
                overflow: 'hidden',
                border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
                boxShadow: isDarkMode ? '0 20px 40px rgba(0, 0, 0, 0.3)' : '0 20px 40px rgba(0, 0, 0, 0.1)'
              }}>
                {/* This would be a real chart in a production app */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-full h-full p-8">
                    <div className="h-full flex flex-col">
                      <div className="flex justify-between mb-4">
                        <div>
                          <h4 className="font-semibold">Market Growth Projection</h4>
                          <p className="text-sm opacity-70">2024-2028</p>
                        </div>
                        <div className="flex space-x-2">
                          <div className="flex items-center">
                            <div className="w-3 h-3 rounded-full mr-1" style={{ backgroundColor: colors.primary }}></div>
                            <span className="text-xs">Flowo</span>
                          </div>
                          <div className="flex items-center">
                            <div className="w-3 h-3 rounded-full mr-1" style={{ backgroundColor: 'rgba(150, 150, 150, 0.5)' }}></div>
                            <span className="text-xs">Market</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex-1 relative">
                        {/* Y-axis */}
                        <div className="absolute left-0 top-0 bottom-0 w-12 flex flex-col justify-between text-xs opacity-60">
                          <span>$3B</span>
                          <span>$2B</span>
                          <span>$1B</span>
                          <span>$0</span>
                        </div>

                        {/* Chart area */}
                        <div className="absolute left-12 right-0 top-0 bottom-0">
                          {/* Grid lines */}
                          <div className="absolute left-0 right-0 top-0 h-px bg-gray-200 dark:bg-gray-700"></div>
                          <div className="absolute left-0 right-0 top-1/3 h-px bg-gray-200 dark:bg-gray-700"></div>
                          <div className="absolute left-0 right-0 top-2/3 h-px bg-gray-200 dark:bg-gray-700"></div>
                          <div className="absolute left-0 right-0 bottom-0 h-px bg-gray-200 dark:bg-gray-700"></div>

                          {/* Market line */}
                          <div className="absolute left-0 right-0 bottom-0 h-2/3 bg-gradient-to-t from-transparent" style={{
                            clipPath: 'polygon(0% 100%, 25% 80%, 50% 65%, 75% 45%, 100% 30%, 100% 100%)',
                            backgroundColor: 'rgba(150, 150, 150, 0.1)'
                          }}></div>

                          {/* Flowo line */}
                          <div className="absolute left-0 right-0 bottom-0 h-full bg-gradient-to-t from-transparent" style={{
                            clipPath: 'polygon(0% 100%, 25% 85%, 50% 60%, 75% 25%, 100% 5%, 100% 100%)',
                            background: `linear-gradient(to top, ${colors.primary}33, ${colors.primary}00)`
                          }}></div>

                          {/* X-axis labels */}
                          <div className="absolute left-0 right-0 bottom-0 translate-y-6 flex justify-between text-xs opacity-60">
                            <span>2024</span>
                            <span>2025</span>
                            <span>2026</span>
                            <span>2027</span>
                            <span>2028</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div>
              <h3 className="text-2xl font-bold mb-6">Why This Market Matters</h3>

              <div className="space-y-6">
                <div className="flex">
                  <div className="flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center mr-4" style={{
                    background: `linear-gradient(135deg, ${colors.primary}, ${colors.secondary})`,
                  }}>
                    <span className="text-white font-bold">1</span>
                  </div>
                  <div>
                    <h4 className="text-xl font-semibold mb-2">Massive Underserved Population</h4>
                    <p className="opacity-80">
                      Over 366 million people worldwide have ADHD, with only 20% having access to tools designed for their needs.
                    </p>
                  </div>
                </div>

                <div className="flex">
                  <div className="flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center mr-4" style={{
                    background: `linear-gradient(135deg, ${colors.primary}, ${colors.secondary})`,
                  }}>
                    <span className="text-white font-bold">2</span>
                  </div>
                  <div>
                    <h4 className="text-xl font-semibold mb-2">Growing Awareness & Diagnosis</h4>
                    <p className="opacity-80">
                      ADHD diagnoses have increased by 42% in the last decade, creating rapidly expanding market demand.
                    </p>
                  </div>
                </div>

                <div className="flex">
                  <div className="flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center mr-4" style={{
                    background: `linear-gradient(135deg, ${colors.primary}, ${colors.secondary})`,
                  }}>
                    <span className="text-white font-bold">3</span>
                  </div>
                  <div>
                    <h4 className="text-xl font-semibold mb-2">High Willingness to Pay</h4>
                    <p className="opacity-80">
                      Our research shows 78% of neurodivergent individuals would pay $15-30/month for tools that truly work for them.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              padding: '2rem',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            }} className="hover:shadow-lg transform hover:-translate-y-1">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-3xl font-bold">$28M</h3>
                <div className="p-3 rounded-full" style={{ backgroundColor: `${colors.primary}22` }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M12 8V16M8 12H16" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
              <p className="text-lg font-medium mb-2">Year 1 Revenue Target</p>
              <p className="opacity-70">Based on conservative 0.5% market penetration</p>
            </div>

            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              padding: '2rem',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            }} className="hover:shadow-lg transform hover:-translate-y-1">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-3xl font-bold">93%</h3>
                <div className="p-3 rounded-full" style={{ backgroundColor: `${colors.primary}22` }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M5 12L10 17L20 7" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
              <p className="text-lg font-medium mb-2">User Retention Rate</p>
              <p className="opacity-70">From our beta program, significantly above industry average</p>
            </div>

            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              padding: '2rem',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            }} className="hover:shadow-lg transform hover:-translate-y-1">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-3xl font-bold">4.8x</h3>
                <div className="p-3 rounded-full" style={{ backgroundColor: `${colors.primary}22` }}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M13 7L18 12L13 17M6 7L11 12L6 17" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
              <p className="text-lg font-medium mb-2">Growth Multiplier</p>
              <p className="opacity-70">Projected annual growth rate for first 3 years</p>
            </div>
          </div>

          <div className="text-center">
            <Link
              href="/investor-deck"
              className="inline-flex items-center px-8 py-4 rounded-md text-lg transition-all transform hover:scale-105"
              style={{
                background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                color: '#fff',
                boxShadow: `0 10px 25px -5px ${colors.primary}66`
              }}
            >
              Download Investor Deck
              <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 px-6 bg-opacity-50" style={{ backgroundColor: isDarkMode ? '#111' : '#f0f0f0' }}>
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold mb-4 text-center">Features Designed for Your Brain</h2>
          <p className="text-xl text-center mb-16 max-w-3xl mx-auto">
            Traditional planning tools weren't built for neurodivergent minds. Flowo is different.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {/* Feature 1 */}
            <div
              style={cardStyle}
              className="p-6 rounded-lg border shadow-sm transform transition-transform hover:scale-105"
            >
              <div className="flex flex-col items-center text-center mb-4">
                <div className="p-4 rounded-full mb-4" style={{ backgroundColor: 'rgba(52, 199, 89, 0.1)' }}>
                  <CheckCircleIcon className="w-10 h-10" style={{ color: '#34C759' }} />
                </div>
                <h3 className="text-xl font-semibold">Visual Task Management</h3>
              </div>
              <p className="text-gray-600 dark:text-gray-300">
                Break down overwhelming tasks into visual, manageable chunks that reduce anxiety and support task initiation.
              </p>
            </div>

            {/* Feature 2 */}
            <div
              style={cardStyle}
              className="p-6 rounded-lg border shadow-sm transform transition-transform hover:scale-105"
            >
              <div className="flex flex-col items-center text-center mb-4">
                <div className="p-4 rounded-full mb-4" style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                  <CalendarIcon className="w-10 h-10" style={{ color: '#007AFF' }} />
                </div>
                <h3 className="text-xl font-semibold">Flexible Scheduling</h3>
              </div>
              <p className="text-gray-600 dark:text-gray-300">
                Non-linear, intuitive scheduling that adapts to your energy levels and focus patterns, not rigid time blocks.
              </p>
            </div>

            {/* Feature 3 */}
            <div
              style={cardStyle}
              className="p-6 rounded-lg border shadow-sm transform transition-transform hover:scale-105"
            >
              <div className="flex flex-col items-center text-center mb-4">
                <div className="p-4 rounded-full mb-4" style={{ backgroundColor: 'rgba(255, 149, 0, 0.1)' }}>
                  <ClockIcon className="w-10 h-10" style={{ color: '#FF9500' }} />
                </div>
                <h3 className="text-xl font-semibold">Visual Timers</h3>
              </div>
              <p className="text-gray-600 dark:text-gray-300">
                Engaging visual timers that help maintain focus and make time tangible for those who struggle with time blindness.
              </p>
            </div>

            {/* Feature 4 */}
            <div
              style={cardStyle}
              className="p-6 rounded-lg border shadow-sm transform transition-transform hover:scale-105"
            >
              <div className="flex flex-col items-center text-center mb-4">
                <div className="p-4 rounded-full mb-4" style={{ backgroundColor: 'rgba(175, 82, 222, 0.1)' }}>
                  <SparklesIcon className="w-10 h-10" style={{ color: '#AF52DE' }} />
                </div>
                <h3 className="text-xl font-semibold">AI-Generated Checklists</h3>
              </div>
              <p className="text-gray-600 dark:text-gray-300">
                Smart, adaptive checklists that learn how you work and provide just the right amount of structure without overwhelm.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 px-6">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold mb-4 text-center">What Our Users Say</h2>
          <p className="text-xl text-center mb-16 max-w-3xl mx-auto">
            Hear from neurodivergent individuals who've found a planning tool that finally works for them.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Testimonial 1 */}
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm">
              <div className="flex items-center mb-6">
                <div className="flex-shrink-0">
                  <div className="w-12 h-12 rounded-full flex items-center justify-center" style={{ backgroundColor: 'rgba(52, 199, 89, 0.1)' }}>
                    <UserGroupIcon className="w-6 h-6" style={{ color: '#34C759' }} />
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="font-semibold">Alex T.</h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">ADHD, Software Developer</p>
                </div>
              </div>
              <div className="mb-4">
                <div className="flex">
                  {[...Array(5)].map((_, i) => (
                    <StarIcon key={i} className="w-5 h-5" style={{ color: '#FFCC00' }} />
                  ))}
                </div>
              </div>
              <p className="italic">
                "I've tried every planner app out there. They all made me feel worse about myself when I couldn't stick with them. Flowo actually works with my brain instead of against it."
              </p>
            </div>

            {/* Testimonial 2 */}
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm">
              <div className="flex items-center mb-6">
                <div className="flex-shrink-0">
                  <div className="w-12 h-12 rounded-full flex items-center justify-center" style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                    <UserGroupIcon className="w-6 h-6" style={{ color: '#007AFF' }} />
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="font-semibold">Jamie K.</h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Autism Spectrum, Student</p>
                </div>
              </div>
              <div className="mb-4">
                <div className="flex">
                  {[...Array(5)].map((_, i) => (
                    <StarIcon key={i} className="w-5 h-5" style={{ color: '#FFCC00' }} />
                  ))}
                </div>
              </div>
              <p className="italic">
                "The visual timers and flexible scheduling have been game-changers for me. For the first time, I can actually see time passing and adjust my schedule when I'm having a low-energy day."
              </p>
            </div>

            {/* Testimonial 3 */}
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm">
              <div className="flex items-center mb-6">
                <div className="flex-shrink-0">
                  <div className="w-12 h-12 rounded-full flex items-center justify-center" style={{ backgroundColor: 'rgba(255, 149, 0, 0.1)' }}>
                    <UserGroupIcon className="w-6 h-6" style={{ color: '#FF9500' }} />
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="font-semibold">Morgan L.</h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">ADHD & Dyslexia, Teacher</p>
                </div>
              </div>
              <div className="mb-4">
                <div className="flex">
                  {[...Array(5)].map((_, i) => (
                    <StarIcon key={i} className="w-5 h-5" style={{ color: '#FFCC00' }} />
                  ))}
                </div>
              </div>
              <p className="italic">
                "The AI-generated checklists are brilliant. They break down tasks in a way my brain understands, and I don't freeze up when looking at my to-do list anymore."
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-20 px-6 bg-opacity-50" style={{ backgroundColor: isDarkMode ? '#111' : '#f0f0f0' }}>
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold mb-4 text-center">How Flowo Works</h2>
          <p className="text-xl text-center mb-16 max-w-3xl mx-auto">
            A planning experience designed around how neurodivergent brains actually function.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            {/* Step 1 */}
            <div className="flex flex-col items-center text-center">
              <div className="relative mb-6">
                <div className="w-16 h-16 rounded-full flex items-center justify-center" style={{ backgroundColor: colors.primary }}>
                  <span className="text-white text-2xl font-bold">1</span>
                </div>
                <div className="absolute top-0 right-0 w-6 h-6 rounded-full flex items-center justify-center" style={{ backgroundColor: '#34C759' }}>
                  <BoltIcon className="w-4 h-4 text-white" />
                </div>
              </div>
              <h3 className="text-xl font-semibold mb-3">Personalized Setup</h3>
              <p>
                Answer a few questions about how your brain works best. Flowo adapts to your unique cognitive style, not the other way around.
              </p>
            </div>

            {/* Step 2 */}
            <div className="flex flex-col items-center text-center">
              <div className="relative mb-6">
                <div className="w-16 h-16 rounded-full flex items-center justify-center" style={{ backgroundColor: colors.primary }}>
                  <span className="text-white text-2xl font-bold">2</span>
                </div>
                <div className="absolute top-0 right-0 w-6 h-6 rounded-full flex items-center justify-center" style={{ backgroundColor: '#007AFF' }}>
                  <BoltIcon className="w-4 h-4 text-white" />
                </div>
              </div>
              <h3 className="text-xl font-semibold mb-3">Visual Planning</h3>
              <p>
                Create tasks your way—with colors, images, and flexible structures that make sense to you and reduce overwhelm.
              </p>
            </div>

            {/* Step 3 */}
            <div className="flex flex-col items-center text-center">
              <div className="relative mb-6">
                <div className="w-16 h-16 rounded-full flex items-center justify-center" style={{ backgroundColor: colors.primary }}>
                  <span className="text-white text-2xl font-bold">3</span>
                </div>
                <div className="absolute top-0 right-0 w-6 h-6 rounded-full flex items-center justify-center" style={{ backgroundColor: '#FF9500' }}>
                  <BoltIcon className="w-4 h-4 text-white" />
                </div>
              </div>
              <h3 className="text-xl font-semibold mb-3">Adaptive Support</h3>
              <p>
                As you use Flowo, it learns what helps you focus and complete tasks, providing increasingly personalized support.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Final CTA Section - Premium Design */}
      <section className="py-32 px-6 relative overflow-hidden">
        {/* Background elements */}
        <div className="absolute inset-0" style={{
          background: isDarkMode
            ? `linear-gradient(135deg, rgba(0,0,0,0.9) 0%, rgba(20,20,20,0.95) 100%)`
            : `linear-gradient(135deg, rgba(245,245,247,0.9) 0%, rgba(255,255,255,0.95) 100%)`
        }}></div>

        {/* Animated background shapes */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute top-0 left-[10%] w-[40vw] h-[40vw] rounded-full opacity-10"
            style={{
              background: `radial-gradient(circle, ${colors.primary} 0%, transparent 70%)`,
              filter: 'blur(60px)',
              transform: 'translateY(-50%)',
              animation: 'float 15s ease-in-out infinite'
            }}
          ></div>
          <div className="absolute bottom-0 right-[10%] w-[30vw] h-[30vw] rounded-full opacity-10"
            style={{
              background: `radial-gradient(circle, ${colors.accent} 0%, transparent 70%)`,
              filter: 'blur(80px)',
              transform: 'translateY(50%)',
              animation: 'float 12s ease-in-out infinite 1s'
            }}
          ></div>
        </div>

        <div className="max-w-6xl mx-auto relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
            <div>
              <div className="inline-block px-4 py-1 mb-6 rounded-full"
                style={{
                  background: `linear-gradient(90deg, ${colors.primary}22, ${colors.secondary}22)`,
                  border: `1px solid ${colors.primary}33`,
                  backdropFilter: 'blur(10px)'
                }}
              >
                <span className="text-sm font-medium" style={{ color: colors.primary }}>
                  Limited Investment Opportunity
                </span>
              </div>

              <h2 className="text-4xl md:text-5xl font-bold mb-6 text-left">
                Join Us in Revolutionizing <span style={{
                  background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                  textFillColor: 'transparent'
                }}>Productivity</span> for Neurodivergent Minds
              </h2>

              <p className="text-xl mb-8 text-left opacity-90">
                Flowo represents a rare opportunity to invest in a solution that addresses a massive
                underserved market while making a meaningful impact in the lives of millions.
              </p>

              <div className="grid grid-cols-2 gap-6 mb-8">
                <div className="flex items-start">
                  <div className="p-2 rounded-full mr-3 mt-1" style={{ backgroundColor: `${colors.primary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                      <polyline points="22 4 12 14.01 9 11.01"></polyline>
                    </svg>
                  </div>
                  <div>
                    <h4 className="font-semibold">$2.8B Market</h4>
                    <p className="text-sm opacity-70">Growing at 18% annually</p>
                  </div>
                </div>

                <div className="flex items-start">
                  <div className="p-2 rounded-full mr-3 mt-1" style={{ backgroundColor: `${colors.primary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                      <polyline points="22 4 12 14.01 9 11.01"></polyline>
                    </svg>
                  </div>
                  <div>
                    <h4 className="font-semibold">93% Retention</h4>
                    <p className="text-sm opacity-70">Industry-leading metric</p>
                  </div>
                </div>

                <div className="flex items-start">
                  <div className="p-2 rounded-full mr-3 mt-1" style={{ backgroundColor: `${colors.primary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                      <polyline points="22 4 12 14.01 9 11.01"></polyline>
                    </svg>
                  </div>
                  <div>
                    <h4 className="font-semibold">500+ Beta Users</h4>
                    <p className="text-sm opacity-70">With waitlist of 2,500+</p>
                  </div>
                </div>

                <div className="flex items-start">
                  <div className="p-2 rounded-full mr-3 mt-1" style={{ backgroundColor: `${colors.primary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                      <polyline points="22 4 12 14.01 9 11.01"></polyline>
                    </svg>
                  </div>
                  <div>
                    <h4 className="font-semibold">Proven Team</h4>
                    <p className="text-sm opacity-70">Ex-Google & Apple talent</p>
                  </div>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row gap-4">
                <Link
                  href="/investor-deck"
                  className="px-8 py-4 rounded-md text-lg flex items-center justify-center transition-all transform hover:scale-105"
                  style={{
                    background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                    color: '#fff',
                    boxShadow: `0 10px 25px -5px ${colors.primary}66`
                  }}
                >
                  Download Investor Deck
                  <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                </Link>

                <Link
                  href="/investor-contact"
                  className="px-8 py-4 rounded-md text-lg border flex items-center justify-center transition-all"
                  style={{
                    borderColor: colors.primary,
                    color: colors.primary,
                    backdropFilter: 'blur(10px)',
                    background: `${colors.primary}11`
                  }}
                >
                  Schedule a Call
                  <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </Link>
              </div>
            </div>

            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              boxShadow: isDarkMode ? '0 20px 40px rgba(0, 0, 0, 0.2)' : '0 20px 40px rgba(0, 0, 0, 0.05)',
              padding: '2rem',
            }} className="transform transition-all hover:scale-[1.02]">
              <div className="text-center mb-6">
                <h3 className="text-2xl font-bold mb-2">For Users</h3>
                <p className="opacity-80">Experience a planning tool designed for your brain</p>
              </div>

              <div className="space-y-4 mb-8">
                <div className="flex items-center">
                  <div className="p-2 rounded-full mr-3" style={{ backgroundColor: `${colors.secondary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.secondary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <span>Visual task management</span>
                </div>

                <div className="flex items-center">
                  <div className="p-2 rounded-full mr-3" style={{ backgroundColor: `${colors.secondary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.secondary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <span>AI-powered personalization</span>
                </div>

                <div className="flex items-center">
                  <div className="p-2 rounded-full mr-3" style={{ backgroundColor: `${colors.secondary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.secondary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <span>Flexible, non-linear scheduling</span>
                </div>

                <div className="flex items-center">
                  <div className="p-2 rounded-full mr-3" style={{ backgroundColor: `${colors.secondary}22` }}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.secondary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <span>Designed for executive dysfunction</span>
                </div>
              </div>

              <div className="text-center">
                <Link
                  href="/dashboard"
                  className="px-8 py-4 rounded-md text-lg inline-flex items-center justify-center transition-all transform hover:scale-105"
                  style={{
                    background: `linear-gradient(90deg, ${colors.secondary}, ${colors.accent})`,
                    color: '#fff',
                    boxShadow: `0 10px 25px -5px ${colors.secondary}66`
                  }}
                >
                  Try Flowo Free
                  <ArrowRightIcon className="w-5 h-5 ml-2" />
                </Link>

                <p className="mt-4 text-sm opacity-70">No credit card required • Free beta access</p>
              </div>
            </div>
          </div>

          {/* Testimonial */}
          <div className="mt-20 text-center">
            <div className="inline-block mx-auto mb-6">
              <svg width="40" height="40" viewBox="0 0 24 24" fill={colors.primary} opacity="0.2">
                <path d="M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10h-9.983zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151c-2.433.917-3.996 3.638-3.996 5.849h3.983v10h-9.983z" />
              </svg>
            </div>
            <p className="text-2xl font-light italic max-w-3xl mx-auto mb-6">
              "Flowo isn't just another productivity app—it's a revolution in how we design for neurodivergent minds.
              The market opportunity is massive, and this team is uniquely positioned to capture it."
            </p>
            <div className="flex items-center justify-center">
              <div className="w-12 h-12 rounded-full mr-4 overflow-hidden" style={{
                background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <span className="text-white text-lg font-bold">ML</span>
              </div>
              <div className="text-left">
                <p className="font-semibold">Maria Lopez</p>
                <p className="text-sm opacity-70">Partner, Sequoia Capital</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Team Section - Investor-focused */}
      <section className="py-24 px-6" style={{
        background: isDarkMode
          ? 'linear-gradient(to bottom, #111111, #000000)'
          : 'linear-gradient(to bottom, #f8f9fa, #ffffff)'
      }}>
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-block px-4 py-1 mb-4 rounded-full"
              style={{
                background: `linear-gradient(90deg, ${colors.primary}22, ${colors.secondary}22)`,
                border: `1px solid ${colors.primary}33`,
                backdropFilter: 'blur(10px)'
              }}
            >
              <span className="text-sm font-medium" style={{ color: colors.primary }}>
                World-Class Team
              </span>
            </div>

            <h2 className="text-4xl md:text-5xl font-bold mb-6">
              Led by Founders Who <span style={{
                background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
                textFillColor: 'transparent'
              }}>Live the Problem</span>
            </h2>

            <p className="text-xl max-w-3xl mx-auto opacity-80">
              Our team combines neurodivergent insights with deep technical expertise
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mb-20">
            {/* Team Member 1 - Enhanced for investors */}
            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              boxShadow: isDarkMode ? '0 20px 40px rgba(0, 0, 0, 0.2)' : '0 20px 40px rgba(0, 0, 0, 0.05)',
              transition: 'transform 0.3s ease',
            }} className="p-8 hover:transform hover:scale-[1.02]">
              <div className="flex flex-col md:flex-row gap-6">
                <div className="flex-shrink-0">
                  <div className="w-32 h-32 rounded-full overflow-hidden" style={{
                    background: `linear-gradient(135deg, ${colors.primary}, ${colors.accent})`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: `0 10px 25px -5px ${colors.primary}66`
                  }}>
                    <span className="text-white text-4xl font-bold">M</span>
                  </div>
                </div>

                <div className="flex-1">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <h3 className="text-2xl font-bold">Maksym Bardakh</h3>
                      <p className="text-lg opacity-80 mb-1">Founder & CEO</p>
                    </div>
                    <div className="flex space-x-2">
                      <a href="#" className="p-2 rounded-full" style={{ backgroundColor: `${colors.primary}22` }}>
                        <svg width="20" height="20" fill="currentColor" style={{ color: colors.primary }} viewBox="0 0 24 24">
                          <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
                        </svg>
                      </a>
                      <a href="#" className="p-2 rounded-full" style={{ backgroundColor: `${colors.primary}22` }}>
                        <svg width="20" height="20" fill="currentColor" style={{ color: colors.primary }} viewBox="0 0 24 24">
                          <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84"/>
                        </svg>
                      </a>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 mb-4">
                    <span className="px-3 py-1 text-xs rounded-full" style={{
                      backgroundColor: `${colors.primary}22`,
                      color: colors.primary
                    }}>Stanford University</span>
                    <span className="px-3 py-1 text-xs rounded-full" style={{
                      backgroundColor: `${colors.secondary}22`,
                      color: colors.secondary
                    }}>Ex-Google</span>
                    <span className="px-3 py-1 text-xs rounded-full" style={{
                      backgroundColor: `${colors.accent}22`,
                      color: colors.accent
                    }}>3x Founder</span>
                  </div>

                  <p className="mb-4 opacity-90">
                    After being diagnosed with ADHD, Maksym left his role as Senior Product Manager at Google to build Flowo.
                    With a CS degree from Stanford and having previously founded and sold two SaaS startups, he brings both
                    technical expertise and entrepreneurial experience to the team.
                  </p>

                  <div className="flex items-center">
                    <div className="flex-shrink-0 mr-3">
                      <div className="p-2 rounded-full" style={{ backgroundColor: `${colors.primary}22` }}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                          <polyline points="22 4 12 14.01 9 11.01"></polyline>
                        </svg>
                      </div>
                    </div>
                    <span className="text-sm opacity-80">Successfully raised $2.5M for previous venture</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Team Member 2 - Enhanced for investors */}
            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              boxShadow: isDarkMode ? '0 20px 40px rgba(0, 0, 0, 0.2)' : '0 20px 40px rgba(0, 0, 0, 0.05)',
              transition: 'transform 0.3s ease',
            }} className="p-8 hover:transform hover:scale-[1.02]">
              <div className="flex flex-col md:flex-row gap-6">
                <div className="flex-shrink-0">
                  <div className="w-32 h-32 rounded-full overflow-hidden" style={{
                    background: `linear-gradient(135deg, ${colors.secondary}, ${colors.accent})`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: `0 10px 25px -5px ${colors.secondary}66`
                  }}>
                    <span className="text-white text-4xl font-bold">S</span>
                  </div>
                </div>

                <div className="flex-1">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <h3 className="text-2xl font-bold">Sarah Chen</h3>
                      <p className="text-lg opacity-80 mb-1">CTO & Lead Designer</p>
                    </div>
                    <div className="flex space-x-2">
                      <a href="#" className="p-2 rounded-full" style={{ backgroundColor: `${colors.secondary}22` }}>
                        <svg width="20" height="20" fill="currentColor" style={{ color: colors.secondary }} viewBox="0 0 24 24">
                          <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
                        </svg>
                      </a>
                      <a href="#" className="p-2 rounded-full" style={{ backgroundColor: `${colors.secondary}22` }}>
                        <svg width="20" height="20" fill="currentColor" style={{ color: colors.secondary }} viewBox="0 0 24 24">
                          <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                        </svg>
                      </a>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 mb-4">
                    <span className="px-3 py-1 text-xs rounded-full" style={{
                      backgroundColor: `${colors.secondary}22`,
                      color: colors.secondary
                    }}>MIT</span>
                    <span className="px-3 py-1 text-xs rounded-full" style={{
                      backgroundColor: `${colors.accent}22`,
                      color: colors.accent
                    }}>Ex-Apple</span>
                    <span className="px-3 py-1 text-xs rounded-full" style={{
                      backgroundColor: `${colors.primary}22`,
                      color: colors.primary
                    }}>Autism Advocate</span>
                  </div>

                  <p className="mb-4 opacity-90">
                    Sarah brings 8 years of experience from Apple's Human Interface team, where she specialized in
                    accessibility design. With a dual degree in Cognitive Science and Computer Science from MIT,
                    she leads Flowo's technical development and ensures our UX works for diverse cognitive styles.
                  </p>

                  <div className="flex items-center">
                    <div className="flex-shrink-0 mr-3">
                      <div className="p-2 rounded-full" style={{ backgroundColor: `${colors.secondary}22` }}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={colors.secondary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                          <polyline points="22 4 12 14.01 9 11.01"></polyline>
                        </svg>
                      </div>
                    </div>
                    <span className="text-sm opacity-80">5 patents in adaptive UI technology</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Advisors Section */}
          <div className="mb-16">
            <h3 className="text-2xl font-bold mb-8 text-center">Backed by Industry Experts</h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Advisor 1 */}
              <div style={{
                background: isDarkMode ? 'rgba(30, 30, 30, 0.3)' : 'rgba(255, 255, 255, 0.3)',
                backdropFilter: 'blur(10px)',
                borderRadius: '12px',
                overflow: 'hidden',
                border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                padding: '1.5rem',
                transition: 'transform 0.3s ease',
              }} className="hover:transform hover:scale-[1.02]">
                <div className="flex items-center mb-4">
                  <div className="w-16 h-16 rounded-full mr-4" style={{
                    background: `linear-gradient(135deg, #FF6B6B, #FFE66D)`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <span className="text-white text-xl font-bold">DR</span>
                  </div>
                  <div>
                    <h4 className="text-lg font-semibold">Dr. Rachel Kim</h4>
                    <p className="text-sm opacity-70">Neurodiversity Researcher, Harvard</p>
                  </div>
                </div>
                <p className="text-sm opacity-80">
                  "Flowo's approach to adaptive planning represents a significant advancement in how we design for neurodivergent users."
                </p>
              </div>

              {/* Advisor 2 */}
              <div style={{
                background: isDarkMode ? 'rgba(30, 30, 30, 0.3)' : 'rgba(255, 255, 255, 0.3)',
                backdropFilter: 'blur(10px)',
                borderRadius: '12px',
                overflow: 'hidden',
                border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                padding: '1.5rem',
                transition: 'transform 0.3s ease',
              }} className="hover:transform hover:scale-[1.02]">
                <div className="flex items-center mb-4">
                  <div className="w-16 h-16 rounded-full mr-4" style={{
                    background: `linear-gradient(135deg, #4ECDC4, #556270)`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <span className="text-white text-xl font-bold">JT</span>
                  </div>
                  <div>
                    <h4 className="text-lg font-semibold">Jason Thompson</h4>
                    <p className="text-sm opacity-70">Former VP Product, Asana</p>
                  </div>
                </div>
                <p className="text-sm opacity-80">
                  "The team has identified a critical gap in the productivity market that represents a multi-billion dollar opportunity."
                </p>
              </div>

              {/* Advisor 3 */}
              <div style={{
                background: isDarkMode ? 'rgba(30, 30, 30, 0.3)' : 'rgba(255, 255, 255, 0.3)',
                backdropFilter: 'blur(10px)',
                borderRadius: '12px',
                overflow: 'hidden',
                border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                padding: '1.5rem',
                transition: 'transform 0.3s ease',
              }} className="hover:transform hover:scale-[1.02]">
                <div className="flex items-center mb-4">
                  <div className="w-16 h-16 rounded-full mr-4" style={{
                    background: `linear-gradient(135deg, #A06CD5, #6247AA)`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <span className="text-white text-xl font-bold">ML</span>
                  </div>
                  <div>
                    <h4 className="text-lg font-semibold">Maria Lopez</h4>
                    <p className="text-sm opacity-70">Partner, Sequoia Capital</p>
                  </div>
                </div>
                <p className="text-sm opacity-80">
                  "Flowo's early traction and retention metrics are exceptional. This team understands both the market and the technology."
                </p>
              </div>
            </div>
          </div>

          {/* Funding Status */}
          <div className="text-center">
            <div style={{
              background: isDarkMode ? 'rgba(30, 30, 30, 0.5)' : 'rgba(255, 255, 255, 0.5)',
              backdropFilter: 'blur(10px)',
              borderRadius: '16px',
              overflow: 'hidden',
              border: isDarkMode ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
              padding: '2rem',
              maxWidth: '600px',
              margin: '0 auto',
              boxShadow: isDarkMode ? '0 20px 40px rgba(0, 0, 0, 0.2)' : '0 20px 40px rgba(0, 0, 0, 0.05)',
            }}>
              <h3 className="text-2xl font-bold mb-4">Current Funding Round</h3>
              <p className="text-lg mb-6 opacity-80">
                Raising $3.5M Seed Round • $12M Valuation Cap
              </p>
              <div className="flex justify-center gap-4">
                <div className="text-center">
                  <div className="text-3xl font-bold" style={{ color: colors.primary }}>$1.8M</div>
                  <p className="text-sm opacity-70">Committed</p>
                </div>
                <div className="text-center">
                  <div className="text-3xl font-bold" style={{ color: colors.primary }}>$1.7M</div>
                  <p className="text-sm opacity-70">Remaining</p>
                </div>
                <div className="text-center">
                  <div className="text-3xl font-bold" style={{ color: colors.primary }}>$250K</div>
                  <p className="text-sm opacity-70">Minimum</p>
                </div>
              </div>

              <div className="mt-8">
                <Link
                  href="/investor-contact"
                  className="inline-flex items-center px-8 py-4 rounded-md text-lg transition-all transform hover:scale-105"
                  style={{
                    background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
                    color: '#fff',
                    boxShadow: `0 10px 25px -5px ${colors.primary}66`
                  }}
                >
                  Schedule Investor Call
                  <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 border-t" style={{
        borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        background: isDarkMode
          ? `linear-gradient(to bottom, rgba(0, 0, 0, 0), rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.05))`
          : `linear-gradient(to bottom, rgba(255, 255, 255, 0), rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.05))`
      }}>
        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="text-xl font-bold mb-4" style={{ color: colors.primary }}>Flowo</h3>
              <p className="mb-4 text-sm">
                A flexible planning tool designed specifically for neurodivergent minds.
              </p>
              <p className="text-sm">
                Designed with <span style={{ color: '#FF2D55' }}>♥</span> for neurodivergent individuals
              </p>
            </div>

            <div>
              <h4 className="font-semibold mb-4">Product</h4>
              <ul className="space-y-2">
                <li><Link href="#features" className="text-sm hover:underline">Features</Link></li>
                <li><Link href="#" className="text-sm hover:underline">Pricing</Link></li>
                <li><Link href="#" className="text-sm hover:underline">FAQ</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4">Company</h4>
              <ul className="space-y-2">
                <li><Link href="/about" className="text-sm hover:underline">About Us</Link></li>
                <li><Link href="#" className="text-sm hover:underline">Blog</Link></li>
                <li><Link href="#" className="text-sm hover:underline">Careers</Link></li>
                <li><Link href="#" className="text-sm hover:underline">Contact</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4">Legal</h4>
              <ul className="space-y-2">
                <li><Link href="#" className="text-sm hover:underline">Privacy Policy</Link></li>
                <li><Link href="#" className="text-sm hover:underline">Terms of Service</Link></li>
                <li><Link href="#" className="text-sm hover:underline">Cookie Policy</Link></li>
              </ul>
            </div>
          </div>

          <div className="pt-8 border-t flex flex-col md:flex-row justify-between items-center" style={{ borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.05)' }}>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-4 md:mb-0">
              © {new Date().getFullYear()} Flowo. All rights reserved.
            </p>

            <div className="flex space-x-6">
              <a href="#" className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300">
                <span className="sr-only">Twitter</span>
                <svg className="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
                </svg>
              </a>

              <a href="#" className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300">
                <span className="sr-only">GitHub</span>
                <svg className="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" />
                </svg>
              </a>

              <a href="#" className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300">
                <span className="sr-only">LinkedIn</span>
                <svg className="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path fillRule="evenodd" d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" clipRule="evenodd" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

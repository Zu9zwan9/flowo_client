'use client';

import React from 'react';
import Link from 'next/link';
import { useTheme } from '@/components/ThemeProvider';
import AnimatedBrain from '@/components/AnimatedBrain';
import {
  UserGroupIcon,
  LightBulbIcon,
  CpuChipIcon,
  ChartBarIcon,
  ArrowLeftIcon
} from '@heroicons/react/24/outline';

export default function AboutPage() {
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
          <Link href="/" className="text-2xl font-bold flex items-center" style={{ color: colors.primary }}>
            <span>Flowo</span>
          </Link>
        </div>

        <div className="flex items-center space-x-4">
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

      {/* Hero Section */}
      <section
        className="py-20 px-6 text-center relative overflow-hidden"
        style={{
          background: isDarkMode
            ? `linear-gradient(to bottom right, rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.15), rgba(0, 0, 0, 0.85))`
            : `linear-gradient(to bottom right, rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.15), rgba(255, 255, 255, 0.9))`
        }}
      >
        <div className="flex flex-col items-center justify-center relative z-10">
          <div className="mb-8 transform hover:scale-105 transition-transform duration-500">
            <AnimatedBrain width={350} height={250} className="mx-auto" />
          </div>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6">
            Reimagining Planning for <span style={highlightStyle}>Neurodivergent</span> Minds
          </h1>

          <p className="text-xl md:text-2xl mb-8 max-w-3xl mx-auto">
            Flowo isn't just another planning app—it's a revolution in how neurodivergent individuals organize their lives.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-4 mb-8">
            <Link
              href="/"
              className="px-6 py-3 rounded-md text-lg inline-flex items-center transition-colors"
              style={secondaryButtonStyle}
            >
              <ArrowLeftIcon className="w-5 h-5 mr-2" />
              Back to Home
            </Link>

            <Link
              href="/auth/signup"
              className="px-6 py-3 rounded-md text-lg inline-flex items-center transition-colors"
              style={buttonStyle}
            >
              Join Our Beta
            </Link>
          </div>

          <div className="mt-8 inline-flex items-center px-4 py-2 rounded-full bg-opacity-20"
            style={{
              backgroundColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)',
              border: `1px solid ${isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)'}`
            }}>
            <span className="text-sm font-medium">
              "Traditional planning tools weren't designed for how our brains work."
            </span>
          </div>
        </div>

        {/* Decorative elements */}
        <div className="absolute top-0 left-0 w-full h-full opacity-20 pointer-events-none">
          <div className="absolute top-10 left-10 w-32 h-32 rounded-full" style={{ backgroundColor: colors.primary, filter: 'blur(60px)' }}></div>
          <div className="absolute bottom-10 right-10 w-40 h-40 rounded-full" style={{ backgroundColor: colors.primary, filter: 'blur(80px)' }}></div>
          <div className="absolute top-1/2 right-1/4 w-24 h-24 rounded-full" style={{ backgroundColor: colors.secondary, filter: 'blur(50px)' }}></div>
        </div>
      </section>

      {/* Target Customers Section */}
      <section className="py-20 px-6 bg-opacity-50" style={{ backgroundColor: isDarkMode ? '#111' : '#f0f0f0' }}>
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col items-center mb-12 text-center">
            <div className="p-4 rounded-full mb-4" style={{
              backgroundColor: 'rgba(52, 199, 89, 0.15)',
              boxShadow: `0 0 20px rgba(52, 199, 89, 0.2)`
            }}>
              <UserGroupIcon className="w-10 h-10" style={{ color: '#34C759' }} />
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Who We&apos;re Building For</h2>
            <p className="text-xl max-w-3xl">
              Flowo is designed specifically for minds that think differently.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-12">
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm transform transition-all hover:shadow-md">
              <h3 className="text-2xl font-semibold mb-6 flex items-center">
                <span className="inline-block w-8 h-8 rounded-full mr-3 flex items-center justify-center"
                  style={{ backgroundColor: 'rgba(52, 199, 89, 0.1)' }}>1</span>
                Our Audience
              </h3>

              <p className="text-lg mb-6 leading-relaxed">
                Our target customers are neurodivergent individuals—particularly teens and young adults with ADHD—who have been let down by traditional planning tools that weren&apos;t designed for their unique cognitive styles.
              </p>

              <div className="bg-opacity-50 p-4 rounded-lg mb-6" style={{
                backgroundColor: isDarkMode ? 'rgba(52, 199, 89, 0.05)' : 'rgba(52, 199, 89, 0.1)',
                borderLeft: '4px solid #34C759'
              }}>
                <p className="italic">
                  &quot;I open the planner and freeze—too many steps, too much structure, I don&apos;t even know where to start.&quot;
                </p>
                <p className="text-right text-sm mt-2">— ADHD user describing traditional planners</p>
              </div>

              <div className="flex flex-wrap gap-3 mb-6">
                {['ADHD', 'Autism', 'Executive Dysfunction', 'Anxiety', 'Neurodivergent'].map((tag, index) => (
                  <span key={index} className="px-3 py-1 rounded-full text-sm" style={{
                    backgroundColor: isDarkMode ? 'rgba(52, 199, 89, 0.1)' : 'rgba(52, 199, 89, 0.1)',
                    color: '#34C759',
                    border: '1px solid rgba(52, 199, 89, 0.3)'
                  }}>
                    {tag}
                  </span>
                ))}
              </div>
            </div>

            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm transform transition-all hover:shadow-md">
              <h3 className="text-2xl font-semibold mb-6 flex items-center">
                <span className="inline-block w-8 h-8 rounded-full mr-3 flex items-center justify-center"
                  style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>2</span>
                Common Challenges
              </h3>

              <p className="text-lg mb-6 leading-relaxed">
                These aren&apos;t individuals who lack motivation or organization skills—they&apos;re people whose brains work differently than the &quot;typical&quot; user most productivity tools are designed for.
              </p>

              <div className="space-y-4 mb-6">
                {[
                  { title: 'Task Initiation', description: 'Difficulty starting tasks despite understanding their importance' },
                  { title: 'Rigid Scheduling', description: 'Frustration with inflexible time blocks that don\'t account for energy fluctuations' },
                  { title: 'Overwhelm', description: 'Shutdown when faced with too many options or steps' },
                  { title: 'Time Blindness', description: 'Challenges perceiving the passage of time accurately' }
                ].map((challenge, index) => (
                  <div key={index} className="flex items-start">
                    <div className="p-1 rounded-full mr-3 mt-1" style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                      <svg className="w-4 h-4" style={{ color: '#007AFF' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div>
                      <h4 className="font-semibold">{challenge.title}</h4>
                      <p className="text-sm text-gray-600 dark:text-gray-300">{challenge.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="text-center">
            <p className="text-xl font-medium" style={{ color: colors.primary }}>
              We&apos;re not just building another planning app—we&apos;re creating a solution that finally works for how neurodivergent brains actually function.
            </p>
          </div>
        </div>
      </section>

      {/* Solution Section */}
      <section className="py-20 px-6">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col items-center mb-12 text-center">
            <div className="p-4 rounded-full mb-4" style={{
              backgroundColor: 'rgba(0, 122, 255, 0.15)',
              boxShadow: `0 0 20px rgba(0, 122, 255, 0.2)`
            }}>
              <LightBulbIcon className="w-10 h-10" style={{ color: '#007AFF' }} />
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Our Revolutionary Approach</h2>
            <p className="text-xl max-w-3xl">
              Flowo adapts to your brain, not the other way around.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
            <div style={cardStyle} className="p-6 rounded-lg border shadow-sm transform transition-all hover:-translate-y-1 hover:shadow-md">
              <div className="flex flex-col items-center text-center mb-6">
                <div className="w-16 h-16 rounded-full mb-4 flex items-center justify-center"
                  style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                  <svg className="w-8 h-8" style={{ color: '#007AFF' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold">Problem-First Design</h3>
              </div>
              <p className="text-center">
                Unlike traditional tools that force users to adapt to rigid systems, we started by deeply understanding how neurodivergent brains actually work.
              </p>
            </div>

            <div style={cardStyle} className="p-6 rounded-lg border shadow-sm transform transition-all hover:-translate-y-1 hover:shadow-md">
              <div className="flex flex-col items-center text-center mb-6">
                <div className="w-16 h-16 rounded-full mb-4 flex items-center justify-center"
                  style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                  <svg className="w-8 h-8" style={{ color: '#007AFF' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold">Adaptive Intelligence</h3>
              </div>
              <p className="text-center">
                Our AI learns your unique patterns and preferences, providing personalized support that evolves as your needs change.
              </p>
            </div>

            <div style={cardStyle} className="p-6 rounded-lg border shadow-sm transform transition-all hover:-translate-y-1 hover:shadow-md">
              <div className="flex flex-col items-center text-center mb-6">
                <div className="w-16 h-16 rounded-full mb-4 flex items-center justify-center"
                  style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                  <svg className="w-8 h-8" style={{ color: '#007AFF' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold">Cognitive Empathy</h3>
              </div>
              <p className="text-center">
                We&apos;ve built a system that understands executive dysfunction, time blindness, and variable energy levels—and works with them, not against them.
              </p>
            </div>
          </div>

          <div style={cardStyle} className="p-8 rounded-xl border shadow-md mb-12 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-40 h-40 opacity-10" style={{
              background: `radial-gradient(circle, ${colors.primary} 0%, transparent 70%)`
            }}></div>

            <h3 className="text-2xl font-semibold mb-6" style={{ color: colors.primary }}>Core Features That Make the Difference</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {[
                {
                  title: 'Visual Timers',
                  description: 'Make time tangible for those who struggle with time blindness',
                  icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'
                },
                {
                  title: 'Adaptive AI Checklists',
                  description: 'Break down tasks in ways that reduce overwhelm and support initiation',
                  icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'
                },
                {
                  title: 'Non-Linear Scheduling',
                  description: 'Flexible planning that adapts to energy levels and focus patterns',
                  icon: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z'
                },
                {
                  title: 'Personalized Interface',
                  description: 'Customizable visuals and interactions that work with your cognitive style',
                  icon: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4'
                }
              ].map((feature, index) => (
                <div key={index} className="flex items-start">
                  <div className="p-2 rounded-full mr-4 mt-1 flex-shrink-0" style={{ backgroundColor: 'rgba(0, 122, 255, 0.1)' }}>
                    <svg className="w-5 h-5" style={{ color: '#007AFF' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={feature.icon} />
                    </svg>
                  </div>
                  <div>
                    <h4 className="font-semibold text-lg">{feature.title}</h4>
                    <p className="text-gray-600 dark:text-gray-300">{feature.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="text-center">
            <p className="text-xl font-medium mb-8">
              The core goal is to reduce overwhelm, support task initiation, and create a planning experience that aligns with how neurodivergent users actually think.
            </p>

            <Link
              href="/auth/signup"
              className="px-6 py-3 rounded-md text-lg inline-flex items-center transition-colors"
              style={buttonStyle}
            >
              Join Our Beta Program
            </Link>
          </div>
        </div>
      </section>

      {/* Technology Section */}
      <section className="py-20 px-6 bg-opacity-50" style={{ backgroundColor: isDarkMode ? '#111' : '#f0f0f0' }}>
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col items-center mb-12 text-center">
            <div className="p-4 rounded-full mb-4" style={{
              backgroundColor: 'rgba(255, 149, 0, 0.15)',
              boxShadow: `0 0 20px rgba(255, 149, 0, 0.2)`
            }}>
              <CpuChipIcon className="w-10 h-10" style={{ color: '#FF9500' }} />
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Powered by Advanced Technology</h2>
            <p className="text-xl max-w-3xl">
              We&apos;ve built Flowo on a foundation of cutting-edge tech to deliver a seamless, adaptive experience.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-12">
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="absolute -top-10 -right-10 w-40 h-40 opacity-5" style={{
                background: `radial-gradient(circle, ${colors.primary} 0%, transparent 70%)`
              }}></div>

              <h3 className="text-2xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-10 h-10 rounded-full mr-3"
                  style={{ backgroundColor: 'rgba(255, 149, 0, 0.1)' }}>
                  <svg className="w-6 h-6" style={{ color: '#FF9500' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </span>
                Tech Stack
              </h3>

              <div className="space-y-4">
                {[
                  {
                    title: 'AI Integration',
                    description: 'OpenAI API and custom models for generating adaptive checklists and smart suggestions that learn from your behavior',
                    icon: 'M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z'
                  },
                  {
                    title: 'Real-time Synchronization',
                    description: 'Modern web technologies ensure your data is always up-to-date across all your devices',
                    icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15'
                  },
                  {
                    title: 'Cross-platform Development',
                    description: 'Flutter/Dart for mobile apps that maintain the same quality experience across iOS and Android',
                    icon: 'M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z'
                  }
                ].map((tech, index) => (
                  <div key={index} className="flex items-start">
                    <div className="p-2 rounded-full mr-4 mt-1 flex-shrink-0" style={{ backgroundColor: 'rgba(255, 149, 0, 0.1)' }}>
                      <svg className="w-5 h-5" style={{ color: '#FF9500' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={tech.icon} />
                      </svg>
                    </div>
                    <div>
                      <h4 className="font-semibold text-lg">{tech.title}</h4>
                      <p className="text-gray-600 dark:text-gray-300">{tech.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="absolute -top-10 -right-10 w-40 h-40 opacity-5" style={{
                background: `radial-gradient(circle, ${colors.primary} 0%, transparent 70%)`
              }}></div>

              <h3 className="text-2xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-10 h-10 rounded-full mr-3"
                  style={{ backgroundColor: 'rgba(255, 149, 0, 0.1)' }}>
                  <svg className="w-6 h-6" style={{ color: '#FF9500' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                  </svg>
                </span>
                Architecture & Design
              </h3>

              <div className="mb-6">
                <p className="mb-4">
                  Our architecture is built with flexibility and personalization at its core:
                </p>

                <div className="grid grid-cols-2 gap-4 mb-6">
                  {[
                    'Modular Components',
                    'Adaptive UI',
                    'Personalization Engine',
                    'Accessibility First'
                  ].map((feature, index) => (
                    <div key={index} className="flex items-center">
                      <div className="w-2 h-2 rounded-full mr-2" style={{ backgroundColor: '#FF9500' }}></div>
                      <span>{feature}</span>
                    </div>
                  ))}
                </div>

                <div className="bg-opacity-50 p-4 rounded-lg" style={{
                  backgroundColor: isDarkMode ? 'rgba(255, 149, 0, 0.05)' : 'rgba(255, 149, 0, 0.1)',
                  borderLeft: '4px solid #FF9500'
                }}>
                  <p className="italic">
                    &quot;We&apos;ve designed our system to be as flexible as the minds it serves. Every component can adapt to the user&apos;s unique cognitive style.&quot;
                  </p>
                  <p className="text-right text-sm mt-2">— Maksym Bardakh, Co-Founder</p>
                </div>
              </div>

              <div>
                <h4 className="font-semibold text-lg mb-2">Future Enhancements</h4>
                <p className="text-gray-600 dark:text-gray-300">
                  Our roadmap includes advanced personalization algorithms, expanded accessibility features, and deeper integration with existing productivity tools—all guided by ongoing feedback from our neurodivergent user community.
                </p>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap justify-center gap-8">
            {[
              { name: 'React', color: '#61DAFB' },
              { name: 'Flutter', color: '#02569B' },
              { name: 'OpenAI', color: '#412991' },
              { name: 'Firebase', color: '#FFCA28' },
              { name: 'TypeScript', color: '#3178C6' },
              { name: 'TailwindCSS', color: '#06B6D4' }
            ].map((tech, index) => (
              <div key={index} className="px-4 py-2 rounded-full text-sm font-medium" style={{
                backgroundColor: isDarkMode ? 'rgba(30, 30, 30, 0.8)' : 'rgba(255, 255, 255, 0.8)',
                border: `1px solid ${tech.color}`,
                color: tech.color
              }}>
                {tech.name}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Market Validation Section */}
      <section className="py-20 px-6">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col items-center mb-12 text-center">
            <div className="p-4 rounded-full mb-4" style={{
              backgroundColor: 'rgba(175, 82, 222, 0.15)',
              boxShadow: `0 0 20px rgba(175, 82, 222, 0.2)`
            }}>
              <ChartBarIcon className="w-10 h-10" style={{ color: '#AF52DE' }} />
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Research-Backed Approach</h2>
            <p className="text-xl max-w-3xl">
              We didn&apos;t just build what we thought would work—we listened, observed, and validated.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-12">
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm col-span-1 lg:col-span-3 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-full h-40 opacity-5" style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, transparent 70%)`
              }}></div>

              <div className="flex flex-col md:flex-row items-center md:items-start gap-8">
                <div className="w-32 h-32 rounded-full flex-shrink-0 overflow-hidden" style={{
                  background: `linear-gradient(45deg, #AF52DE, ${isDarkMode ? '#333' : '#f0f0f0'})`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <span className="text-white text-4xl font-bold">M</span>
                </div>

                <div>
                  <h3 className="text-2xl font-semibold mb-4">Our Origin Story</h3>
                  <p className="text-lg mb-6 leading-relaxed">
                    Our journey began with firsthand experience: when Maksym was diagnosed with ADHD, it sparked a deeper exploration
                    into the everyday challenges neurodivergent individuals face with traditional planning tools. What started as a personal
                    quest for better tools became a mission to help others facing similar challenges.
                  </p>

                  <div className="bg-opacity-50 p-4 rounded-lg mb-6" style={{
                    backgroundColor: isDarkMode ? 'rgba(175, 82, 222, 0.05)' : 'rgba(175, 82, 222, 0.1)',
                    borderLeft: '4px solid #AF52DE'
                  }}>
                    <p className="italic">
                      &quot;After my diagnosis, I tried dozens of planning apps. None of them worked with my brain. They all assumed I think linearly and can estimate time accurately—which I can&apos;t. I knew there had to be a better way.&quot;
                    </p>
                    <p className="text-right text-sm mt-2">— Maksym Bardakh, Co-Founder</p>
                  </div>
                </div>
              </div>
            </div>

            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="h-2 absolute top-0 left-0 right-0" style={{ backgroundColor: '#AF52DE' }}></div>
              <h3 className="text-xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-8 h-8 rounded-full mr-3 text-white"
                  style={{ backgroundColor: '#AF52DE' }}>1</span>
                Comprehensive Research
              </h3>

              <p className="mb-4">
                In early 2024, we initiated a research project focused on understanding the needs of neurodivergent individuals:
              </p>

              <div className="space-y-4 mb-6">
                {[
                  {
                    title: 'In-depth Interviews',
                    description: '37 one-on-one sessions with ADHD and autistic individuals',
                    icon: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z'
                  },
                  {
                    title: 'Community Surveys',
                    description: '500+ responses from ADHD, autism, and neurodiversity support groups',
                    icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2'
                  },
                  {
                    title: 'Observation Sessions',
                    description: 'Watched how users interact with existing planning tools to identify pain points',
                    icon: 'M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z'
                  }
                ].map((method, index) => (
                  <div key={index} className="flex items-start">
                    <div className="p-2 rounded-full mr-3 mt-1 flex-shrink-0" style={{ backgroundColor: 'rgba(175, 82, 222, 0.1)' }}>
                      <svg className="w-4 h-4" style={{ color: '#AF52DE' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={method.icon} />
                      </svg>
                    </div>
                    <div>
                      <h4 className="font-semibold">{method.title}</h4>
                      <p className="text-sm text-gray-600 dark:text-gray-300">{method.description}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="text-center mt-8">
                <span className="inline-block px-3 py-1 rounded-full text-sm font-medium" style={{
                  backgroundColor: isDarkMode ? 'rgba(175, 82, 222, 0.1)' : 'rgba(175, 82, 222, 0.1)',
                  color: '#AF52DE',
                  border: '1px solid rgba(175, 82, 222, 0.3)'
                }}>
                  Data-Driven Design
                </span>
              </div>
            </div>

            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="h-2 absolute top-0 left-0 right-0" style={{ backgroundColor: '#AF52DE' }}></div>
              <h3 className="text-xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-8 h-8 rounded-full mr-3 text-white"
                  style={{ backgroundColor: '#AF52DE' }}>2</span>
                Key Insights
              </h3>

              <p className="mb-4">
                These patterns emerged consistently across our research:
              </p>

              <div className="space-y-3 mb-6">
                {[
                  'Difficulty initiating tasks despite understanding their importance',
                  'Frustration with rigid, linear planning systems',
                  'Overwhelm from traditional tools that demand high executive function',
                  'The need for visual, intuitive, and forgiving systems',
                  'A strong desire for tools that adapt to the user, not the other way around'
                ].map((insight, index) => (
                  <div key={index} className="flex items-start">
                    <div className="p-1 rounded-full mr-3 mt-1 flex-shrink-0" style={{ backgroundColor: 'rgba(175, 82, 222, 0.1)' }}>
                      <svg className="w-4 h-4" style={{ color: '#AF52DE' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    <p className="text-sm">{insight}</p>
                  </div>
                ))}
              </div>

              <div className="text-center mt-8">
                <span className="inline-block px-3 py-1 rounded-full text-sm font-medium" style={{
                  backgroundColor: isDarkMode ? 'rgba(175, 82, 222, 0.1)' : 'rgba(175, 82, 222, 0.1)',
                  color: '#AF52DE',
                  border: '1px solid rgba(175, 82, 222, 0.3)'
                }}>
                  User-Centered Approach
                </span>
              </div>
            </div>

            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="h-2 absolute top-0 left-0 right-0" style={{ backgroundColor: '#AF52DE' }}></div>
              <h3 className="text-xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-8 h-8 rounded-full mr-3 text-white"
                  style={{ backgroundColor: '#AF52DE' }}>3</span>
                Ongoing Validation
              </h3>

              <p className="mb-4">
                Our development process is continuously informed by:
              </p>

              <div className="space-y-4 mb-6">
                {[
                  {
                    title: 'Beta Testing Program',
                    description: 'Active users providing real-world feedback on features and usability',
                    icon: 'M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z'
                  },
                  {
                    title: 'Community Engagement',
                    description: 'Regular check-ins with neurodivergent communities to validate our approach',
                    icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z'
                  },
                  {
                    title: 'Iterative Design',
                    description: 'Rapid prototyping and testing cycles to refine features based on feedback',
                    icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15'
                  }
                ].map((method, index) => (
                  <div key={index} className="flex items-start">
                    <div className="p-2 rounded-full mr-3 mt-1 flex-shrink-0" style={{ backgroundColor: 'rgba(175, 82, 222, 0.1)' }}>
                      <svg className="w-4 h-4" style={{ color: '#AF52DE' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={method.icon} />
                      </svg>
                    </div>
                    <div>
                      <h4 className="font-semibold">{method.title}</h4>
                      <p className="text-sm text-gray-600 dark:text-gray-300">{method.description}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="text-center mt-8">
                <span className="inline-block px-3 py-1 rounded-full text-sm font-medium" style={{
                  backgroundColor: isDarkMode ? 'rgba(175, 82, 222, 0.1)' : 'rgba(175, 82, 222, 0.1)',
                  color: '#AF52DE',
                  border: '1px solid rgba(175, 82, 222, 0.3)'
                }}>
                  Continuous Improvement
                </span>
              </div>
            </div>
          </div>

          <div className="text-center">
            <p className="text-xl font-medium mb-8">
              This validation process shaped both the vision and functionality of Flowo. The user pain points we uncovered
              continue to guide our design and development priorities.
            </p>

            <Link
              href="/auth/signup"
              className="px-6 py-3 rounded-md text-lg inline-flex items-center transition-colors"
              style={buttonStyle}
            >
              Join Our Research Community
            </Link>
          </div>
        </div>
      </section>

      {/* Current Status Section */}
      <section className="py-20 px-6 bg-opacity-50" style={{ backgroundColor: isDarkMode ? '#111' : '#f0f0f0' }}>
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col items-center mb-12 text-center">
            <div className="p-4 rounded-full mb-4" style={{
              backgroundColor: 'rgba(52, 199, 89, 0.15)',
              boxShadow: `0 0 20px rgba(52, 199, 89, 0.2)`
            }}>
              <svg className="w-10 h-10" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Where We Are Today</h2>
            <p className="text-xl max-w-3xl">
              From concept to beta—our journey so far and what&apos;s coming next.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-12">
            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="absolute -top-10 -right-10 w-40 h-40 opacity-5" style={{
                background: `radial-gradient(circle, #34C759 0%, transparent 70%)`
              }}></div>

              <h3 className="text-2xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-10 h-10 rounded-full mr-3"
                  style={{ backgroundColor: 'rgba(52, 199, 89, 0.1)' }}>
                  <svg className="w-6 h-6" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </span>
                Current Progress
              </h3>

              <div className="mb-6">
                <p className="mb-6 leading-relaxed">
                  We currently have a working beta version of Flowo in the hands of active testers who are using and evaluating our core features:
                </p>

                <div className="space-y-4 mb-6">
                  {[
                    {
                      title: 'Visual Timers',
                      status: 'Beta Testing',
                      progress: 80,
                      color: '#34C759'
                    },
                    {
                      title: 'Adaptive Checklists',
                      status: 'Beta Testing',
                      progress: 75,
                      color: '#007AFF'
                    },
                    {
                      title: 'Flexible Scheduling',
                      status: 'Beta Testing',
                      progress: 70,
                      color: '#FF9500'
                    },
                    {
                      title: 'AI Integration',
                      status: 'Development',
                      progress: 60,
                      color: '#AF52DE'
                    }
                  ].map((feature, index) => (
                    <div key={index} className="space-y-1">
                      <div className="flex justify-between items-center">
                        <div className="flex items-center">
                          <div className="w-2 h-2 rounded-full mr-2" style={{ backgroundColor: feature.color }}></div>
                          <span className="font-medium">{feature.title}</span>
                        </div>
                        <span className="text-xs px-2 py-1 rounded-full" style={{
                          backgroundColor: isDarkMode ? 'rgba(52, 199, 89, 0.1)' : 'rgba(52, 199, 89, 0.1)',
                          color: feature.color
                        }}>
                          {feature.status}
                        </span>
                      </div>
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5 overflow-hidden">
                        <div className="h-2.5 rounded-full" style={{
                          width: `${feature.progress}%`,
                          backgroundColor: feature.color
                        }}></div>
                      </div>
                    </div>
                  ))}
                </div>

                <p>
                  Our beta testers are providing ongoing, high-value feedback that directly informs our design and feature priorities.
                </p>
              </div>

              <div className="flex justify-between items-center p-4 rounded-lg" style={{
                backgroundColor: isDarkMode ? 'rgba(52, 199, 89, 0.05)' : 'rgba(52, 199, 89, 0.1)'
              }}>
                <div className="flex items-center">
                  <svg className="w-5 h-5 mr-2" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span className="font-medium">Beta Program</span>
                </div>
                <span className="text-sm font-medium" style={{ color: '#34C759' }}>Active</span>
              </div>
            </div>

            <div style={cardStyle} className="p-8 rounded-lg border shadow-sm relative overflow-hidden">
              <div className="absolute -top-10 -right-10 w-40 h-40 opacity-5" style={{
                background: `radial-gradient(circle, #34C759 0%, transparent 70%)`
              }}></div>

              <h3 className="text-2xl font-semibold mb-6 flex items-center">
                <span className="inline-flex items-center justify-center w-10 h-10 rounded-full mr-3"
                  style={{ backgroundColor: 'rgba(52, 199, 89, 0.1)' }}>
                  <svg className="w-6 h-6" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </span>
                Roadmap
              </h3>

              <div className="space-y-6 mb-6">
                {[
                  {
                    quarter: 'Q3 2024',
                    title: 'Expanded Beta',
                    description: 'Increasing our beta user base and refining core features based on feedback',
                    items: ['Enhanced visual timers', 'Improved task breakdown', 'Mobile app beta']
                  },
                  {
                    quarter: 'Q4 2024',
                    title: 'Public Beta Launch',
                    description: 'Opening access to a wider audience with a more polished product',
                    items: ['Full AI integration', 'Cross-platform sync', 'Customization options']
                  },
                  {
                    quarter: 'Q1 2025',
                    title: 'Official Release',
                    description: 'Full product launch with premium features and subscription options',
                    items: ['Advanced analytics', 'Integration with popular tools', 'Premium support']
                  }
                ].map((phase, index) => (
                  <div key={index} className="flex">
                    <div className="flex-shrink-0 flex flex-col items-center mr-4">
                      <div className="w-8 h-8 rounded-full flex items-center justify-center" style={{
                        backgroundColor: '#34C759',
                        color: 'white',
                        fontSize: '0.75rem',
                        fontWeight: 'bold'
                      }}>
                        {index + 1}
                      </div>
                      {index < 2 && (
                        <div className="w-0.5 h-full bg-gray-300 dark:bg-gray-700 my-1"></div>
                      )}
                    </div>
                    <div>
                      <div className="flex items-center mb-1">
                        <span className="text-xs font-medium px-2 py-0.5 rounded-full mr-2" style={{
                          backgroundColor: isDarkMode ? 'rgba(52, 199, 89, 0.1)' : 'rgba(52, 199, 89, 0.1)',
                          color: '#34C759'
                        }}>
                          {phase.quarter}
                        </span>
                        <h4 className="font-semibold">{phase.title}</h4>
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">{phase.description}</p>
                      <ul className="text-sm space-y-1">
                        {phase.items.map((item, itemIndex) => (
                          <li key={itemIndex} className="flex items-start">
                            <svg className="w-4 h-4 mr-1 mt-0.5 flex-shrink-0" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4" />
                            </svg>
                            {item}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div style={cardStyle} className="p-8 rounded-lg border shadow-md mb-12">
            <div className="flex flex-col md:flex-row items-center justify-between gap-8">
              <div>
                <h3 className="text-2xl font-semibold mb-4">Join Our Beta Program</h3>
                <p className="mb-6">
                  While we are pre-revenue, the level of interest from ADHD communities—through direct outreach and social engagement—has
                  been strong. We are preparing to expand our beta program as we move toward a broader public release.
                </p>
                <ul className="space-y-2 mb-6">
                  <li className="flex items-start">
                    <svg className="w-5 h-5 mr-2 mt-0.5" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Early access to new features
                  </li>
                  <li className="flex items-start">
                    <svg className="w-5 h-5 mr-2 mt-0.5" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Shape the future of the product
                  </li>
                  <li className="flex items-start">
                    <svg className="w-5 h-5 mr-2 mt-0.5" style={{ color: '#34C759' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Free access during the beta period
                  </li>
                </ul>
              </div>

              <div className="flex-shrink-0">
                <Link
                  href="/auth/signup"
                  className="px-8 py-4 rounded-md text-lg inline-flex items-center transition-colors"
                  style={buttonStyle}
                >
                  Apply for Beta Access
                  <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </Link>
              </div>
            </div>
          </div>

          <div className="text-center">
            <p className="text-xl font-medium">
              Be part of the revolution in planning tools for neurodivergent minds.
            </p>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-6 text-center relative overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-full opacity-10 pointer-events-none">
          <div className="absolute top-10 left-10 w-32 h-32 rounded-full" style={{ backgroundColor: colors.primary, filter: 'blur(60px)' }}></div>
          <div className="absolute bottom-10 right-10 w-40 h-40 rounded-full" style={{ backgroundColor: colors.primary, filter: 'blur(80px)' }}></div>
          <div className="absolute top-1/2 right-1/4 w-24 h-24 rounded-full" style={{ backgroundColor: colors.secondary, filter: 'blur(50px)' }}></div>
        </div>

        <div className="relative z-10 max-w-4xl mx-auto">
          <h2 className="text-3xl md:text-5xl font-bold mb-6">Ready to Transform Your Planning Experience?</h2>
          <p className="text-xl md:text-2xl mb-10 max-w-3xl mx-auto">
            Join thousands of neurodivergent individuals who&apos;ve found a planning system that finally works with their brains, not against them.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-6 mb-12">
            <Link
              href="/auth/signup"
              className="px-8 py-4 rounded-md text-xl inline-flex items-center transition-all transform hover:scale-105"
              style={{
                ...buttonStyle,
                boxShadow: `0 4px 14px rgba(${parseInt(colors.primary.slice(1, 3), 16)}, ${parseInt(colors.primary.slice(3, 5), 16)}, ${parseInt(colors.primary.slice(5, 7), 16)}, 0.4)`
              }}
            >
              Join the Beta Program
              <svg className="w-6 h-6 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
              </svg>
            </Link>

            <Link
              href="/"
              className="px-8 py-4 rounded-md text-xl border-2 inline-flex items-center transition-colors"
              style={secondaryButtonStyle}
            >
              Explore the Homepage
            </Link>
          </div>

          <div className="flex flex-wrap justify-center gap-4 mb-8">
            {[
              'ADHD-Friendly', 'Neurodivergent-Designed', 'Visual Planning', 'Flexible Scheduling', 'AI-Powered'
            ].map((tag, index) => (
              <span key={index} className="px-4 py-2 rounded-full text-sm font-medium" style={{
                backgroundColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)',
                border: `1px solid ${isDarkMode ? 'rgba(255, 255, 255, 0.2)' : 'rgba(0, 0, 0, 0.1)'}`
              }}>
                {tag}
              </span>
            ))}
          </div>

          <p className="text-sm text-gray-500 dark:text-gray-400 italic">
            "The future of productivity tools is personalization—adapting to how people actually think and work."
          </p>
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
                <li><Link href="/#features" className="text-sm hover:underline">Features</Link></li>
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

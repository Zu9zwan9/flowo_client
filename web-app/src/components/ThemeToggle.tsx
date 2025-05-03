'use client';

import React from 'react';
import { useTheme } from './ThemeProvider';
import { AppTheme } from '@/types/models';
import { SunIcon, MoonIcon, ComputerDesktopIcon } from '@heroicons/react/24/outline';
import { SunIcon as SunSolidIcon, MoonIcon as MoonSolidIcon, ComputerDesktopIcon as ComputerSolidIcon } from '@heroicons/react/24/solid';

interface ThemeToggleProps {
  className?: string;
  showLabel?: boolean;
}

const ThemeToggle: React.FC<ThemeToggleProps> = ({
  className = '',
  showLabel = false
}) => {
  const { theme, setTheme, colors, isDarkMode } = useTheme();

  // Handle theme change
  const handleThemeChange = (newTheme: AppTheme) => {
    setTheme(newTheme);
  };

  // Dynamic styles
  const buttonStyle = {
    backgroundColor: isDarkMode ? 'rgba(30, 30, 30, 0.8)' : 'rgba(255, 255, 255, 0.8)',
    borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
    color: colors.text,
  };

  const activeButtonStyle = {
    backgroundColor: isDarkMode ? 'rgba(60, 60, 60, 0.8)' : 'rgba(240, 240, 240, 0.8)',
    borderColor: colors.primary,
    color: colors.primary,
  };

  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      {/* System Theme */}
      <button
        onClick={() => handleThemeChange(AppTheme.system)}
        className="p-2 rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2"
        style={theme === AppTheme.system ? activeButtonStyle : buttonStyle}
        aria-label="Use system theme"
        title="Use system theme"
      >
        {theme === AppTheme.system ? (
          <ComputerSolidIcon className="w-5 h-5" />
        ) : (
          <ComputerDesktopIcon className="w-5 h-5" />
        )}
        {showLabel && <span className="ml-1">System</span>}
      </button>

      {/* Light Theme */}
      <button
        onClick={() => handleThemeChange(AppTheme.light)}
        className="p-2 rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2"
        style={theme === AppTheme.light ? activeButtonStyle : buttonStyle}
        aria-label="Use light theme"
        title="Use light theme"
      >
        {theme === AppTheme.light ? (
          <SunSolidIcon className="w-5 h-5" />
        ) : (
          <SunIcon className="w-5 h-5" />
        )}
        {showLabel && <span className="ml-1">Light</span>}
      </button>

      {/* Dark Theme */}
      <button
        onClick={() => handleThemeChange(AppTheme.dark)}
        className="p-2 rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2"
        style={theme === AppTheme.dark ? activeButtonStyle : buttonStyle}
        aria-label="Use dark theme"
        title="Use dark theme"
      >
        {theme === AppTheme.dark ? (
          <MoonSolidIcon className="w-5 h-5" />
        ) : (
          <MoonIcon className="w-5 h-5" />
        )}
        {showLabel && <span className="ml-1">Dark</span>}
      </button>
    </div>
  );
};

export default ThemeToggle;

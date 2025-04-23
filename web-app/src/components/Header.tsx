'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTheme } from './ThemeProvider';
import {
  Bars3Icon,
  XMarkIcon,
  CalendarIcon,
  CheckCircleIcon,
  Cog6ToothIcon,
  UserCircleIcon
} from '@heroicons/react/24/outline';

const Header: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const pathname = usePathname();
  const { colors, isDarkMode } = useTheme();

  // Navigation items
  const navItems = [
    {
      name: 'Tasks',
      href: '/dashboard/tasks',
      icon: <CheckCircleIcon className="w-5 h-5" />
    },
    {
      name: 'Calendar',
      href: '/dashboard/calendar',
      icon: <CalendarIcon className="w-5 h-5" />
    },
    {
      name: 'Settings',
      href: '/dashboard/settings',
      icon: <Cog6ToothIcon className="w-5 h-5" />
    },
    {
      name: 'Profile',
      href: '/dashboard/profile',
      icon: <UserCircleIcon className="w-5 h-5" />
    },
  ];

  // Determine if a nav item is active
  const isActive = (href: string) => {
    return pathname === href || pathname?.startsWith(`${href}/`);
  };

  // Toggle mobile menu
  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  // Dynamic styles based on theme
  const headerStyle = {
    backgroundColor: isDarkMode ? colors.background : 'rgba(255, 255, 255, 0.8)',
    backdropFilter: 'blur(10px)',
    borderBottom: `1px solid ${isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)'}`,
    color: colors.text,
  };

  const activeStyle = {
    color: colors.primary,
    borderBottom: `2px solid ${colors.primary}`,
  };

  return (
    <header
      style={headerStyle}
      className="sticky top-0 z-50 w-full py-3 px-4 md:px-6"
    >
      <div className="flex items-center justify-between">
        {/* Logo */}
        <Link href="/dashboard" className="flex items-center">
          <span
            style={{ color: colors.primary }}
            className="text-xl font-semibold"
          >
            Flowo
          </span>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex space-x-8">
          {navItems.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              style={isActive(item.href) ? activeStyle : {}}
              className="flex items-center space-x-1 py-2 px-1 transition-colors duration-200"
            >
              {item.icon}
              <span>{item.name}</span>
            </Link>
          ))}
        </nav>

        {/* Mobile Menu Button */}
        <button
          onClick={toggleMenu}
          className="md:hidden p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
        >
          {isMenuOpen ? (
            <XMarkIcon className="w-6 h-6" />
          ) : (
            <Bars3Icon className="w-6 h-6" />
          )}
        </button>
      </div>

      {/* Mobile Navigation */}
      {isMenuOpen && (
        <nav
          style={{ backgroundColor: headerStyle.backgroundColor }}
          className="md:hidden mt-3 py-2 rounded-lg shadow-lg"
        >
          {navItems.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              onClick={() => setIsMenuOpen(false)}
              className="flex items-center space-x-2 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              style={isActive(item.href) ? { color: colors.primary } : {}}
            >
              {item.icon}
              <span>{item.name}</span>
            </Link>
          ))}
        </nav>
      )}
    </header>
  );
};

export default Header;

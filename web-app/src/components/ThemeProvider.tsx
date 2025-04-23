'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { AppTheme } from '@/types/models';
import { appleColors, generateDynamicColors } from '@/utils/colors';

// Define the theme context type
interface ThemeContextType {
  theme: AppTheme;
  setTheme: (theme: AppTheme) => void;
  isDarkMode: boolean;
  customColor: string;
  setCustomColor: (color: string) => void;
  colorIntensity: number;
  setColorIntensity: (intensity: number) => void;
  useDynamicColors: boolean;
  setUseDynamicColors: (use: boolean) => void;
  colors: {
    primary: string;
    secondary: string;
    tertiary: string;
    background: string;
    text: string;
    [key: string]: string;
  };
}

// Create the theme context with default values
const ThemeContext = createContext<ThemeContextType>({
  theme: AppTheme.system,
  setTheme: () => {},
  isDarkMode: false,
  customColor: appleColors.blue.light,
  setCustomColor: () => {},
  colorIntensity: 1.0,
  setColorIntensity: () => {},
  useDynamicColors: true,
  setUseDynamicColors: () => {},
  colors: {
    primary: appleColors.blue.light,
    secondary: appleColors.blue.light,
    tertiary: appleColors.blue.light,
    background: appleColors.systemBackground.light,
    text: appleColors.label.light,
  },
});

// Hook to use the theme context
export const useTheme = () => useContext(ThemeContext);

// Theme provider component
export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // State for theme preferences
  const [theme, setTheme] = useState<AppTheme>(AppTheme.system);
  const [customColor, setCustomColor] = useState<string>(appleColors.blue.light);
  const [colorIntensity, setColorIntensity] = useState<number>(1.0);
  const [useDynamicColors, setUseDynamicColors] = useState<boolean>(true);

  // Determine if dark mode is active
  const [isDarkMode, setIsDarkMode] = useState<boolean>(false);

  // Generate colors based on preferences
  const [colors, setColors] = useState(
    generateDynamicColors(customColor, 'light', colorIntensity)
  );

  // Effect to detect system theme changes
  useEffect(() => {
    // Check if window is defined (client-side)
    if (typeof window !== 'undefined') {
      // Function to determine dark mode
      const checkDarkMode = () => {
        if (theme === AppTheme.system) {
          // Use system preference
          const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
          setIsDarkMode(isDark);
          return isDark;
        } else {
          // Use user preference
          const isDark = theme === AppTheme.dark;
          setIsDarkMode(isDark);
          return isDark;
        }
      };

      // Initial check
      const isDark = checkDarkMode();

      // Update colors based on dark mode
      setColors(
        generateDynamicColors(
          customColor,
          isDark ? 'dark' : 'light',
          colorIntensity
        )
      );

      // Listen for system theme changes
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      const handleChange = () => {
        if (theme === AppTheme.system) {
          const isDark = mediaQuery.matches;
          setIsDarkMode(isDark);
          setColors(
            generateDynamicColors(
              customColor,
              isDark ? 'dark' : 'light',
              colorIntensity
            )
          );
        }
      };

      // Add event listener
      mediaQuery.addEventListener('change', handleChange);

      // Clean up
      return () => mediaQuery.removeEventListener('change', handleChange);
    }
  }, [theme, customColor, colorIntensity]);

  // Effect to update colors when preferences change
  useEffect(() => {
    setColors(
      generateDynamicColors(
        customColor,
        isDarkMode ? 'dark' : 'light',
        colorIntensity
      )
    );
  }, [customColor, isDarkMode, colorIntensity, useDynamicColors]);

  // Provide the theme context
  return (
    <ThemeContext.Provider
      value={{
        theme,
        setTheme,
        isDarkMode,
        customColor,
        setCustomColor,
        colorIntensity,
        setColorIntensity,
        useDynamicColors,
        setUseDynamicColors,
        colors,
      }}
    >
      {children}
    </ThemeContext.Provider>
  );
};

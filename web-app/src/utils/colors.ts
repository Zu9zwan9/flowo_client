// Apple HIG color system
// Based on https://developer.apple.com/design/human-interface-guidelines/color

// Define the base colors for light and dark mode
export const appleColors = {
  // Primary colors
  blue: {
    light: '#007AFF',
    dark: '#0A84FF',
  },
  green: {
    light: '#34C759',
    dark: '#30D158',
  },
  indigo: {
    light: '#5856D6',
    dark: '#5E5CE6',
  },
  orange: {
    light: '#FF9500',
    dark: '#FF9F0A',
  },
  pink: {
    light: '#FF2D55',
    dark: '#FF375F',
  },
  purple: {
    light: '#AF52DE',
    dark: '#BF5AF2',
  },
  red: {
    light: '#FF3B30',
    dark: '#FF453A',
  },
  teal: {
    light: '#5AC8FA',
    dark: '#64D2FF',
  },
  yellow: {
    light: '#FFCC00',
    dark: '#FFD60A',
  },

  // Grayscale
  gray: {
    light: {
      1: '#8E8E93',
      2: '#AEAEB2',
      3: '#C7C7CC',
      4: '#D1D1D6',
      5: '#E5E5EA',
      6: '#F2F2F7',
    },
    dark: {
      1: '#8E8E93',
      2: '#636366',
      3: '#48484A',
      4: '#3A3A3C',
      5: '#2C2C2E',
      6: '#1C1C1E',
    },
  },

  // System backgrounds
  systemBackground: {
    light: '#FFFFFF',
    dark: '#000000',
  },
  secondarySystemBackground: {
    light: '#F2F2F7',
    dark: '#1C1C1E',
  },
  tertiarySystemBackground: {
    light: '#FFFFFF',
    dark: '#2C2C2E',
  },

  // System groupings
  systemGroupedBackground: {
    light: '#F2F2F7',
    dark: '#000000',
  },
  secondarySystemGroupedBackground: {
    light: '#FFFFFF',
    dark: '#1C1C1E',
  },
  tertiarySystemGroupedBackground: {
    light: '#F2F2F7',
    dark: '#2C2C2E',
  },

  // Separators
  separator: {
    light: 'rgba(60, 60, 67, 0.29)',
    dark: 'rgba(84, 84, 88, 0.6)',
  },
  opaqueSeparator: {
    light: '#C6C6C8',
    dark: '#38383A',
  },

  // Text
  label: {
    light: '#000000',
    dark: '#FFFFFF',
  },
  secondaryLabel: {
    light: 'rgba(60, 60, 67, 0.6)',
    dark: 'rgba(235, 235, 245, 0.6)',
  },
  tertiaryLabel: {
    light: 'rgba(60, 60, 67, 0.3)',
    dark: 'rgba(235, 235, 245, 0.3)',
  },
  quaternaryLabel: {
    light: 'rgba(60, 60, 67, 0.18)',
    dark: 'rgba(235, 235, 245, 0.16)',
  },

  // Fill
  fill: {
    light: 'rgba(120, 120, 128, 0.2)',
    dark: 'rgba(120, 120, 128, 0.36)',
  },
  secondaryFill: {
    light: 'rgba(120, 120, 128, 0.16)',
    dark: 'rgba(120, 120, 128, 0.32)',
  },
  tertiaryFill: {
    light: 'rgba(118, 118, 128, 0.12)',
    dark: 'rgba(118, 118, 128, 0.24)',
  },
  quaternaryFill: {
    light: 'rgba(116, 116, 128, 0.08)',
    dark: 'rgba(116, 116, 128, 0.18)',
  },
};

// Function to get color based on mode
export const getColor = (
  colorName: keyof typeof appleColors,
  mode: 'light' | 'dark',
  variant?: string | number
) => {
  const color = appleColors[colorName];

  if (typeof color === 'object' && 'light' in color && 'dark' in color) {
    if (variant && typeof color[mode] === 'object') {
      return color[mode][variant as keyof typeof color[typeof mode]];
    }
    return color[mode];
  }

  return '#000000'; // Fallback color
};

// Premium color palettes for Awwwards-level design
export const premiumPalettes = {
  purple: {
    light: {
      primary: '#6C5CE7',
      secondary: '#A29BFE',
      accent: '#E84393',
      gradient: 'linear-gradient(135deg, #6C5CE7 0%, #A29BFE 100%)',
      gradientAlt: 'linear-gradient(135deg, #6C5CE7 0%, #E84393 100%)',
    },
    dark: {
      primary: '#8A7CFF',
      secondary: '#BDB4FF',
      accent: '#FF6CAB',
      gradient: 'linear-gradient(135deg, #8A7CFF 0%, #BDB4FF 100%)',
      gradientAlt: 'linear-gradient(135deg, #8A7CFF 0%, #FF6CAB 100%)',
    }
  },
  blue: {
    light: {
      primary: '#0984E3',
      secondary: '#74B9FF',
      accent: '#00CEC9',
      gradient: 'linear-gradient(135deg, #0984E3 0%, #74B9FF 100%)',
      gradientAlt: 'linear-gradient(135deg, #0984E3 0%, #00CEC9 100%)',
    },
    dark: {
      primary: '#0A84FF',
      secondary: '#82C0FF',
      accent: '#00E5E0',
      gradient: 'linear-gradient(135deg, #0A84FF 0%, #82C0FF 100%)',
      gradientAlt: 'linear-gradient(135deg, #0A84FF 0%, #00E5E0 100%)',
    }
  },
  green: {
    light: {
      primary: '#00B894',
      secondary: '#55EFC4',
      accent: '#FDCB6E',
      gradient: 'linear-gradient(135deg, #00B894 0%, #55EFC4 100%)',
      gradientAlt: 'linear-gradient(135deg, #00B894 0%, #FDCB6E 100%)',
    },
    dark: {
      primary: '#00D2A8',
      secondary: '#6DFFE0',
      accent: '#FFE17D',
      gradient: 'linear-gradient(135deg, #00D2A8 0%, #6DFFE0 100%)',
      gradientAlt: 'linear-gradient(135deg, #00D2A8 0%, #FFE17D 100%)',
    }
  }
};

// Function to generate dynamic colors based on user preferences
export const generateDynamicColors = (
  baseColor: string,
  mode: 'light' | 'dark',
  intensity: number = 1.0
) => {
  // Determine which premium palette to use based on the base color
  let palette;
  if (baseColor.toLowerCase() === appleColors.purple.light.toLowerCase() ||
      baseColor.toLowerCase() === appleColors.purple.dark.toLowerCase() ||
      baseColor.toLowerCase() === appleColors.indigo.light.toLowerCase() ||
      baseColor.toLowerCase() === appleColors.indigo.dark.toLowerCase()) {
    palette = premiumPalettes.purple[mode];
  } else if (baseColor.toLowerCase() === appleColors.blue.light.toLowerCase() ||
             baseColor.toLowerCase() === appleColors.blue.dark.toLowerCase() ||
             baseColor.toLowerCase() === appleColors.teal.light.toLowerCase() ||
             baseColor.toLowerCase() === appleColors.teal.dark.toLowerCase()) {
    palette = premiumPalettes.blue[mode];
  } else if (baseColor.toLowerCase() === appleColors.green.light.toLowerCase() ||
             baseColor.toLowerCase() === appleColors.green.dark.toLowerCase()) {
    palette = premiumPalettes.green[mode];
  } else {
    // Default to blue palette if no match
    palette = premiumPalettes.blue[mode];
  }

  return {
    primary: palette.primary,
    secondary: palette.secondary,
    tertiary: adjustColorIntensity(palette.primary, intensity * 0.6),
    accent: palette.accent,
    gradient: palette.gradient,
    gradientAlt: palette.gradientAlt,
    background: mode === 'light' ? '#FFFFFF' : '#000000',
    backgroundAlt: mode === 'light' ? '#F8F9FA' : '#121212',
    backgroundGradient: mode === 'light'
      ? 'linear-gradient(135deg, #FFFFFF 0%, #F8F9FA 100%)'
      : 'linear-gradient(135deg, #000000 0%, #121212 100%)',
    text: mode === 'light' ? '#2D3748' : '#F7FAFC',
    textSecondary: mode === 'light' ? '#4A5568' : '#E2E8F0',
    textTertiary: mode === 'light' ? '#718096' : '#A0AEC0',
    border: mode === 'light' ? 'rgba(0, 0, 0, 0.1)' : 'rgba(255, 255, 255, 0.1)',
    shadow: mode === 'light'
      ? '0 4px 20px rgba(0, 0, 0, 0.08)'
      : '0 4px 20px rgba(0, 0, 0, 0.3)',
    shadowHover: mode === 'light'
      ? '0 10px 30px rgba(0, 0, 0, 0.12)'
      : '0 10px 30px rgba(0, 0, 0, 0.4)',
  };
};

// Helper function to adjust color intensity
const adjustColorIntensity = (hexColor: string, intensity: number): string => {
  // Convert hex to RGB
  const r = parseInt(hexColor.slice(1, 3), 16);
  const g = parseInt(hexColor.slice(3, 5), 16);
  const b = parseInt(hexColor.slice(5, 7), 16);

  // Adjust intensity (this is a simplified approach)
  const adjustedR = Math.min(255, Math.max(0, Math.round(r * intensity)));
  const adjustedG = Math.min(255, Math.max(0, Math.round(g * intensity)));
  const adjustedB = Math.min(255, Math.max(0, Math.round(b * intensity)));

  // Convert back to hex
  return `#${adjustedR.toString(16).padStart(2, '0')}${adjustedG.toString(16).padStart(2, '0')}${adjustedB.toString(16).padStart(2, '0')}`;
};

// Helper function to convert hex to rgba
export const hexToRgba = (hex: string, alpha: number): string => {
  // Remove # if present
  hex = hex.replace('#', '');

  // Parse the hex values
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);

  // Return rgba string
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

// Helper function to create a glass effect color
export const createGlassEffect = (baseColor: string, alpha: number = 0.2, blur: number = 10): string => {
  return `backdrop-filter: blur(${blur}px); background-color: ${hexToRgba(baseColor, alpha)};`;
};

// Helper function to create a gradient with transparency
export const createTransparentGradient = (color1: string, color2: string, alpha1: number = 0.8, alpha2: number = 0.2): string => {
  return `linear-gradient(135deg, ${hexToRgba(color1, alpha1)} 0%, ${hexToRgba(color2, alpha2)} 100%)`;
};

// Helper function to create a text gradient
export const createTextGradient = (color1: string, color2: string): string => {
  return {
    background: `linear-gradient(135deg, ${color1} 0%, ${color2} 100%)`,
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    backgroundClip: 'text',
    textFillColor: 'transparent',
    display: 'inline-block'
  };
};

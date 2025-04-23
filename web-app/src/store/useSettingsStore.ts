import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import {
  UserSettings,
  UserProfile,
  AppTheme,
  NotificationType,
  TimeFrame,
  DaySchedule
} from '@/types/models';
import { appleColors } from '@/utils/colors';

interface SettingsState {
  userSettings: UserSettings;
  userProfile: UserProfile;

  // User settings actions
  updateUserSettings: (updates: Partial<UserSettings>) => void;
  updateTheme: (theme: AppTheme) => void;
  updateCustomColor: (colorValue: number) => void;
  updateColorIntensity: (intensity: number) => void;
  updateNoiseLevel: (level: number) => void;
  updateUseGradient: (useGradient: boolean) => void;
  updateUseDynamicColors: (useDynamicColors: boolean) => void;
  updateDateTimeFormat: (is24Hour: boolean, dateFormat: string, monthFormat: string) => void;
  updateAccessibilitySettings: (
    textSizeAdjustment?: number,
    reduceMotion?: boolean,
    highContrastMode?: boolean
  ) => void;

  // Schedule actions
  updateDaySchedule: (day: string, schedule: Partial<DaySchedule>) => void;
  updateSleepTime: (day: string, sleepTime: TimeFrame) => void;
  updateMealBreaks: (day: string, mealBreaks: TimeFrame[]) => void;
  updateFreeTimes: (day: string, freeTimes: TimeFrame[]) => void;
  updateActiveDays: (activeDays: Record<string, boolean>) => void;

  // User profile actions
  updateUserProfile: (updates: Partial<UserProfile>) => void;
  completeOnboarding: () => void;
  updateUserGoal: (goal: string) => void;
}

// Default day schedule
const createDefaultDaySchedule = (day: string): DaySchedule => ({
  day,
  isActive: true,
  sleepTime: {
    startTime: { hour: 22, minute: 0 },
    endTime: { hour: 7, minute: 0 }
  },
  mealBreaks: [
    {
      startTime: { hour: 8, minute: 0 },
      endTime: { hour: 8, minute: 30 }
    },
    {
      startTime: { hour: 12, minute: 0 },
      endTime: { hour: 13, minute: 0 }
    },
    {
      startTime: { hour: 18, minute: 0 },
      endTime: { hour: 19, minute: 0 }
    }
  ],
  freeTimes: [
    {
      startTime: { hour: 19, minute: 0 },
      endTime: { hour: 22, minute: 0 }
    }
  ]
});

// Default user settings
const defaultUserSettings: UserSettings = {
  name: 'Default',
  minSession: 15 * 60 * 1000, // 15 minutes in milliseconds
  breakTime: 15 * 60 * 1000, // 15 minutes in milliseconds
  mealBreaks: [],
  sleepTime: [
    {
      startTime: { hour: 22, minute: 0 },
      endTime: { hour: 7, minute: 0 }
    }
  ],
  freeTime: [],
  activeDays: {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': true,
  },
  daySchedules: {
    'Monday': createDefaultDaySchedule('Monday'),
    'Tuesday': createDefaultDaySchedule('Tuesday'),
    'Wednesday': createDefaultDaySchedule('Wednesday'),
    'Thursday': createDefaultDaySchedule('Thursday'),
    'Friday': createDefaultDaySchedule('Friday'),
    'Saturday': createDefaultDaySchedule('Saturday'),
    'Sunday': createDefaultDaySchedule('Sunday'),
  },
  defaultNotificationType: NotificationType.push,
  dateFormat: 'DD-MM-YYYY',
  monthFormat: 'numeric',
  is24HourFormat: true,
  themeMode: AppTheme.system,
  customColorValue: parseInt(appleColors.blue.light.replace('#', '0x')),
  colorIntensity: 1.0,
  noiseLevel: 0.0,
  useGradient: false,
  secondaryColorValue: parseInt(appleColors.green.light.replace('#', '0x')),
  useDynamicColors: true,
  textSizeAdjustment: 0.0,
  reduceMotion: false,
  highContrastMode: false,
  gradientStartAlignment: 'topLeft',
  gradientEndAlignment: 'bottomRight',
};

// Default user profile
const defaultUserProfile: UserProfile = {
  name: 'User',
  email: 'user@example.com',
  goal: undefined,
  onboardingCompleted: false,
};

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      userSettings: defaultUserSettings,
      userProfile: defaultUserProfile,

      // User settings actions
      updateUserSettings: (updates) => set((state) => ({
        userSettings: { ...state.userSettings, ...updates }
      })),

      updateTheme: (theme) => set((state) => ({
        userSettings: { ...state.userSettings, themeMode: theme }
      })),

      updateCustomColor: (colorValue) => set((state) => ({
        userSettings: { ...state.userSettings, customColorValue: colorValue }
      })),

      updateColorIntensity: (intensity) => set((state) => ({
        userSettings: { ...state.userSettings, colorIntensity: intensity }
      })),

      updateNoiseLevel: (level) => set((state) => ({
        userSettings: { ...state.userSettings, noiseLevel: level }
      })),

      updateUseGradient: (useGradient) => set((state) => ({
        userSettings: { ...state.userSettings, useGradient }
      })),

      updateUseDynamicColors: (useDynamicColors) => set((state) => ({
        userSettings: { ...state.userSettings, useDynamicColors }
      })),

      updateDateTimeFormat: (is24HourFormat, dateFormat, monthFormat) => set((state) => ({
        userSettings: {
          ...state.userSettings,
          is24HourFormat,
          dateFormat,
          monthFormat
        }
      })),

      updateAccessibilitySettings: (textSizeAdjustment, reduceMotion, highContrastMode) => set((state) => ({
        userSettings: {
          ...state.userSettings,
          ...(textSizeAdjustment !== undefined && { textSizeAdjustment }),
          ...(reduceMotion !== undefined && { reduceMotion }),
          ...(highContrastMode !== undefined && { highContrastMode }),
        }
      })),

      // Schedule actions
      updateDaySchedule: (day, schedule) => set((state) => {
        const currentSchedule = state.userSettings.daySchedules[day] || createDefaultDaySchedule(day);
        return {
          userSettings: {
            ...state.userSettings,
            daySchedules: {
              ...state.userSettings.daySchedules,
              [day]: { ...currentSchedule, ...schedule }
            }
          }
        };
      }),

      updateSleepTime: (day, sleepTime) => set((state) => {
        const currentSchedule = state.userSettings.daySchedules[day] || createDefaultDaySchedule(day);
        return {
          userSettings: {
            ...state.userSettings,
            daySchedules: {
              ...state.userSettings.daySchedules,
              [day]: { ...currentSchedule, sleepTime }
            }
          }
        };
      }),

      updateMealBreaks: (day, mealBreaks) => set((state) => {
        const currentSchedule = state.userSettings.daySchedules[day] || createDefaultDaySchedule(day);
        return {
          userSettings: {
            ...state.userSettings,
            daySchedules: {
              ...state.userSettings.daySchedules,
              [day]: { ...currentSchedule, mealBreaks }
            }
          }
        };
      }),

      updateFreeTimes: (day, freeTimes) => set((state) => {
        const currentSchedule = state.userSettings.daySchedules[day] || createDefaultDaySchedule(day);
        return {
          userSettings: {
            ...state.userSettings,
            daySchedules: {
              ...state.userSettings.daySchedules,
              [day]: { ...currentSchedule, freeTimes }
            }
          }
        };
      }),

      updateActiveDays: (activeDays) => set((state) => ({
        userSettings: { ...state.userSettings, activeDays }
      })),

      // User profile actions
      updateUserProfile: (updates) => set((state) => ({
        userProfile: { ...state.userProfile, ...updates }
      })),

      completeOnboarding: () => set((state) => ({
        userProfile: { ...state.userProfile, onboardingCompleted: true }
      })),

      updateUserGoal: (goal) => set((state) => ({
        userProfile: { ...state.userProfile, goal }
      })),
    }),
    {
      name: 'settings-storage',
    }
  )
);

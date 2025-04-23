// TypeScript interfaces for the models based on the Flutter models

// Category model
export interface Category {
  id?: string;
  name: string;
}

// Coordinates model
export interface Coordinates {
  latitude: number;
  longitude: number;
}

// TimeOfDay model
export interface TimeOfDay {
  hour: number;
  minute: number;
}

// TimeFrame model
export interface TimeFrame {
  startTime: TimeOfDay;
  endTime: TimeOfDay;
}

// RepeatRule model
export interface RepeatRule {
  type: 'daily' | 'weekly' | 'monthly' | 'yearly';
  interval: number;
  endDate?: Date;
  daysOfWeek?: number[];
}

// TaskSession model
export interface TaskSession {
  id: string;
  taskId: string;
  startTime: Date;
  endTime?: Date;
  isActive: boolean;
  duration: number;
}

// ScheduledTask model
export interface ScheduledTask {
  id: string;
  taskId: string;
  date: Date;
  startTime: TimeOfDay;
  endTime: TimeOfDay;
  isCompleted: boolean;
}

// Task model
export interface Task {
  id: string;
  title: string;
  priority: number;
  deadline: number; // timestamp
  estimatedTime: number; // in milliseconds
  category: Category;
  optimisticTime?: number;
  realisticTime?: number;
  pessimisticTime?: number;
  notes?: string;
  location?: Coordinates;
  image?: string;
  frequency?: RepeatRule;
  subtasks: Task[];
  parentTaskId?: string;
  scheduledTasks: ScheduledTask[];
  isDone: boolean;
  order?: number;
  overdue: boolean;
  color?: number;
  firstNotification?: number;
  secondNotification?: number;
  status: 'not_started' | 'in_progress' | 'paused' | 'completed';
  totalDuration: number;
  sessions: TaskSession[];
}

// DaySchedule model
export interface DaySchedule {
  day: string;
  isActive: boolean;
  sleepTime: TimeFrame;
  mealBreaks: TimeFrame[];
  freeTimes: TimeFrame[];
}

// NotificationType enum
export enum NotificationType {
  push = 'push',
  email = 'email',
  sms = 'sms',
  none = 'none'
}

// AppTheme enum
export enum AppTheme {
  system = 'system',
  light = 'light',
  dark = 'dark'
}

// UserSettings model
export interface UserSettings {
  id?: string;
  name: string;
  minSession: number;
  breakTime?: number;
  mealBreaks: TimeFrame[];
  sleepTime: TimeFrame[];
  freeTime: TimeFrame[];
  activeDays?: Record<string, boolean>;
  daySchedules: Record<string, DaySchedule>;
  defaultNotificationType: NotificationType;
  dateFormat: string;
  monthFormat: string;
  is24HourFormat: boolean;
  themeMode: AppTheme;
  customColorValue: number;
  colorIntensity: number;
  noiseLevel: number;
  useGradient: boolean;
  secondaryColorValue?: number;
  useDynamicColors: boolean;
  textSizeAdjustment?: number;
  reduceMotion?: boolean;
  highContrastMode?: boolean;
  gradientStartAlignment?: string;
  gradientEndAlignment?: string;
}

// UserProfile model
export interface UserProfile {
  id?: string;
  name: string;
  email: string;
  goal?: string;
  onboardingCompleted: boolean;
}

// AmbientScene model
export interface AmbientScene {
  id: string;
  name: string;
  imageUrl: string;
  soundUrl?: string;
  isDefault: boolean;
}

// PomodoroSession model
export interface PomodoroSession {
  id: string;
  taskId: string;
  startTime: Date;
  endTime?: Date;
  duration: number;
  state: 'work' | 'break' | 'paused' | 'completed';
}

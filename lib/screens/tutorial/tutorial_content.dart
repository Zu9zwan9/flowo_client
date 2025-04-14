/// Model class for tutorial items
class TutorialItem {
  final String title;
  final String description;
  final String? imagePath;
  final String? videoPath;
  final List<String> tips;

  const TutorialItem({
    required this.title,
    required this.description,
    this.imagePath,
    this.videoPath,
    this.tips = const [],
  });
}

/// Tutorial content covering the main features of the app
final List<TutorialItem> tutorialContent = [
  // Welcome
  const TutorialItem(
    title: 'Welcome to Flowo',
    description:
        'Flowo is your personal productivity assistant designed to help you manage tasks, habits, and events efficiently. This tutorial will guide you through the main features of the app.',
    // Using icon instead of image path
    tips: [
      'You can access this tutorial anytime from the Settings screen.',
      'Swipe left and right to navigate through the tutorial.',
    ],
  ),

  // Task Management
  const TutorialItem(
    title: 'Task Management',
    description:
        'Create, organize, and track your tasks with ease. Set due dates, priorities, and reminders to stay on top of your to-do list.',
    // Using icon instead of video path
    tips: [
      'Tap on a task to view details or mark it as complete.',
      'Swipe left on a task to delete it.',
      'Use the + button to add a new task.',
      'Tasks can be organized by priority, due date, or custom categories.',
    ],
  ),

  // Habit Tracking
  const TutorialItem(
    title: 'Habit Tracking',
    description:
        'Build positive habits by tracking your daily, weekly, or monthly activities. Visualize your progress and stay motivated with streaks and statistics.',
    // Using icon instead of image path
    tips: [
      'Set up reminders for your habits to stay consistent.',
      'View your habit history to see your progress over time.',
      'Customize habit frequency based on your needs.',
    ],
  ),

  // Calendar & Events
  const TutorialItem(
    title: 'Calendar & Events',
    description:
        'Manage your schedule with the integrated calendar. Add events, set reminders, and get a clear overview of your upcoming activities.',
    // Using icon instead of video path
    tips: [
      'Toggle between day, week, and month views.',
      'Long press on a date to quickly add an event.',
      'Events can be color-coded for better organization.',
    ],
  ),

  // Pomodoro Timer
  const TutorialItem(
    title: 'Pomodoro Timer',
    description:
        'Boost your productivity with the Pomodoro technique. Work in focused intervals with short breaks in between to maintain high productivity levels throughout the day.',
    // Using icon instead of image path
    tips: [
      'Customize work and break durations to suit your workflow.',
      'The app will notify you when it\'s time to take a break or resume work.',
      'Track your focus sessions to improve your productivity habits.',
    ],
  ),

  // Analytics
  const TutorialItem(
    title: 'Analytics & Insights',
    description:
        'Gain valuable insights into your productivity patterns. View detailed statistics about your tasks, habits, and time management to identify areas for improvement.',
    // Using icon instead of video path
    tips: [
      'Weekly and monthly reports help you track your progress.',
      'Identify your most productive days and times.',
      'Use insights to adjust your schedule for optimal productivity.',
    ],
  ),

  // Settings & Customization
  const TutorialItem(
    title: 'Settings & Customization',
    description:
        'Personalize the app to match your preferences. Adjust themes, notification settings, and schedule preferences to make Flowo work for you.',
    // Using icon instead of image path
    tips: [
      'Enable dark mode for comfortable nighttime use.',
      'Set your active hours to optimize task scheduling.',
      'Customize notification preferences for different types of activities.',
    ],
  ),

  // Get Started
  const TutorialItem(
    title: 'Ready to Get Started?',
    description:
        'Now that you\'re familiar with Flowo\'s features, it\'s time to boost your productivity! Remember, you can access this tutorial anytime from the Settings screen if you need a refresher.',
    // Using icon instead of image path
    tips: [
      'Start by adding a few tasks or habits to get familiar with the app.',
      'Explore the different features at your own pace.',
      'Check the Settings screen for additional customization options.',
    ],
  ),
];

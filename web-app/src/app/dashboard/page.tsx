'use client';

import React, { useState, useEffect } from 'react';
import Header from '@/components/Header';
import TaskListItem from '@/components/TaskListItem';
import MonthCalendar from '@/components/Calendar/MonthCalendar';
import { useTheme } from '@/components/ThemeProvider';
import { useTaskStore } from '@/store/useTaskStore';
import { useSettingsStore } from '@/store/useSettingsStore';
import {
  PlusIcon,
  ClockIcon,
  CalendarIcon,
  CheckCircleIcon,
  ArrowPathIcon
} from '@heroicons/react/24/outline';
import { format, isToday, isTomorrow, isPast } from 'date-fns';

export default function Dashboard() {
  const { colors, isDarkMode } = useTheme();
  const { tasks } = useTaskStore();
  const { userProfile } = useSettingsStore();

  const [selectedDate, setSelectedDate] = useState(new Date());
  const [isLoading, setIsLoading] = useState(true);

  // Simulate loading state
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1000);

    return () => clearTimeout(timer);
  }, []);

  // Filter tasks
  const overdueTasks = tasks.filter(task =>
    !task.isDone && task.deadline && isPast(new Date(task.deadline)) && !isToday(new Date(task.deadline))
  );

  const todayTasks = tasks.filter(task =>
    !task.isDone && task.deadline && isToday(new Date(task.deadline))
  );

  const tomorrowTasks = tasks.filter(task =>
    !task.isDone && task.deadline && isTomorrow(new Date(task.deadline))
  );

  // Get tasks for selected date
  const tasksForSelectedDate = tasks.filter(task =>
    task.deadline && format(new Date(task.deadline), 'yyyy-MM-dd') === format(selectedDate, 'yyyy-MM-dd')
  );

  // Handle date selection from calendar
  const handleDateSelect = (date: Date) => {
    setSelectedDate(date);
  };

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

  // Loading skeleton
  if (isLoading) {
    return (
      <div style={containerStyle} className="min-h-screen">
        <Header />
        <main className="container mx-auto px-4 py-6">
          <div className="animate-pulse">
            <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/4 mb-6"></div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-40 bg-gray-200 dark:bg-gray-700 rounded"></div>
              ))}
            </div>
            <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/3 mb-4"></div>
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-20 bg-gray-200 dark:bg-gray-700 rounded"></div>
              ))}
            </div>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div style={containerStyle} className="min-h-screen">
      <Header />

      <main className="container mx-auto px-4 py-6">
        {/* Welcome Message */}
        <h1 className="text-2xl font-bold mb-6">
          Welcome back, {userProfile.name}!
        </h1>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          {/* Overdue Tasks */}
          <div
            style={cardStyle}
            className="p-4 rounded-lg border shadow-sm"
          >
            <div className="flex items-center mb-2">
              <ClockIcon className="w-5 h-5 mr-2" style={{ color: '#FF3B30' }} />
              <h2 className="text-lg font-semibold">Overdue</h2>
            </div>
            <p className="text-3xl font-bold" style={{ color: '#FF3B30' }}>
              {overdueTasks.length}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {overdueTasks.length === 1 ? 'task' : 'tasks'} past due date
            </p>
          </div>

          {/* Today's Tasks */}
          <div
            style={cardStyle}
            className="p-4 rounded-lg border shadow-sm"
          >
            <div className="flex items-center mb-2">
              <CalendarIcon className="w-5 h-5 mr-2" style={{ color: colors.primary }} />
              <h2 className="text-lg font-semibold">Today</h2>
            </div>
            <p className="text-3xl font-bold" style={{ color: colors.primary }}>
              {todayTasks.length}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {todayTasks.length === 1 ? 'task' : 'tasks'} for today
            </p>
          </div>

          {/* Completed Tasks */}
          <div
            style={cardStyle}
            className="p-4 rounded-lg border shadow-sm"
          >
            <div className="flex items-center mb-2">
              <CheckCircleIcon className="w-5 h-5 mr-2" style={{ color: '#34C759' }} />
              <h2 className="text-lg font-semibold">Completed</h2>
            </div>
            <p className="text-3xl font-bold" style={{ color: '#34C759' }}>
              {tasks.filter(task => task.isDone).length}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {tasks.filter(task => task.isDone).length === 1 ? 'task' : 'tasks'} completed
            </p>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Task Lists */}
          <div className="lg:col-span-2 space-y-6">
            {/* Overdue Tasks */}
            {overdueTasks.length > 0 && (
              <section>
                <h2 className="text-xl font-semibold mb-3 flex items-center">
                  <span style={{ color: '#FF3B30' }} className="mr-2">Overdue</span>
                  <span className="text-sm bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-100 px-2 py-0.5 rounded-full">
                    {overdueTasks.length}
                  </span>
                </h2>
                <div className="space-y-2">
                  {overdueTasks.slice(0, 3).map(task => (
                    <TaskListItem key={task.id} task={task} />
                  ))}
                  {overdueTasks.length > 3 && (
                    <button
                      className="text-sm flex items-center"
                      style={{ color: colors.primary }}
                    >
                      View all {overdueTasks.length} overdue tasks
                      <ArrowPathIcon className="w-4 h-4 ml-1" />
                    </button>
                  )}
                </div>
              </section>
            )}

            {/* Today's Tasks */}
            <section>
              <h2 className="text-xl font-semibold mb-3 flex items-center">
                <span className="mr-2">Today</span>
                <span className="text-sm bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100 px-2 py-0.5 rounded-full">
                  {todayTasks.length}
                </span>
              </h2>
              {todayTasks.length > 0 ? (
                <div className="space-y-2">
                  {todayTasks.map(task => (
                    <TaskListItem key={task.id} task={task} />
                  ))}
                </div>
              ) : (
                <div
                  style={cardStyle}
                  className="p-4 rounded-lg border shadow-sm text-center"
                >
                  <p className="mb-2">No tasks for today!</p>
                  <button
                    className="inline-flex items-center px-3 py-1.5 rounded-md text-sm"
                    style={{ backgroundColor: colors.primary, color: '#fff' }}
                  >
                    <PlusIcon className="w-4 h-4 mr-1" />
                    Add Task
                  </button>
                </div>
              )}
            </section>

            {/* Tomorrow's Tasks */}
            {tomorrowTasks.length > 0 && (
              <section>
                <h2 className="text-xl font-semibold mb-3 flex items-center">
                  <span className="mr-2">Tomorrow</span>
                  <span className="text-sm bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-100 px-2 py-0.5 rounded-full">
                    {tomorrowTasks.length}
                  </span>
                </h2>
                <div className="space-y-2">
                  {tomorrowTasks.map(task => (
                    <TaskListItem key={task.id} task={task} />
                  ))}
                </div>
              </section>
            )}
          </div>

          {/* Calendar */}
          <div>
            <MonthCalendar onSelectDate={handleDateSelect} />

            {/* Tasks for Selected Date */}
            <div className="mt-6">
              <h2 className="text-xl font-semibold mb-3">
                {format(selectedDate, 'MMMM d, yyyy')}
              </h2>

              {tasksForSelectedDate.length > 0 ? (
                <div className="space-y-2">
                  {tasksForSelectedDate.map(task => (
                    <TaskListItem key={task.id} task={task} />
                  ))}
                </div>
              ) : (
                <div
                  style={cardStyle}
                  className="p-4 rounded-lg border shadow-sm text-center"
                >
                  <p className="mb-2">No tasks for this date</p>
                  <button
                    className="inline-flex items-center px-3 py-1.5 rounded-md text-sm"
                    style={{ backgroundColor: colors.primary, color: '#fff' }}
                  >
                    <PlusIcon className="w-4 h-4 mr-1" />
                    Add Task
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

'use client';

import React, { useState } from 'react';
import { useTheme } from '../ThemeProvider';
import { useTaskStore } from '@/store/useTaskStore';
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  CalendarDaysIcon
} from '@heroicons/react/24/outline';
import {
  format,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  isSameMonth,
  isSameDay,
  addMonths,
  subMonths,
  isToday
} from 'date-fns';
import { Task } from '@/types/models';

interface MonthCalendarProps {
  onSelectDate?: (date: Date) => void;
}

const MonthCalendar: React.FC<MonthCalendarProps> = ({ onSelectDate }) => {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(new Date());

  const { colors, isDarkMode } = useTheme();
  const { tasks } = useTaskStore();

  // Get days in current month
  const monthStart = startOfMonth(currentMonth);
  const monthEnd = endOfMonth(currentMonth);
  const daysInMonth = eachDayOfInterval({ start: monthStart, end: monthEnd });

  // Navigation functions
  const prevMonth = () => {
    setCurrentMonth(subMonths(currentMonth, 1));
  };

  const nextMonth = () => {
    setCurrentMonth(addMonths(currentMonth, 1));
  };

  // Select date
  const handleDateClick = (day: Date) => {
    setSelectedDate(day);
    if (onSelectDate) {
      onSelectDate(day);
    }
  };

  // Get tasks for a specific day
  const getTasksForDay = (day: Date): Task[] => {
    return tasks.filter(task => {
      // Check regular deadline
      if (task.deadline && isSameDay(new Date(task.deadline), day)) {
        return true;
      }

      // Check scheduled tasks
      return task.scheduledTasks.some(scheduledTask =>
        isSameDay(new Date(scheduledTask.date), day)
      );
    });
  };

  // Dynamic styles
  const calendarStyle = {
    backgroundColor: isDarkMode ? 'rgba(30, 30, 30, 0.8)' : 'rgba(255, 255, 255, 0.8)',
    borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
    color: colors.text,
  };

  const dayStyle = (day: Date) => {
    const isSelected = isSameDay(day, selectedDate);
    const isCurrentMonth = isSameMonth(day, currentMonth);
    const isTodayDate = isToday(day);
    const tasksForDay = getTasksForDay(day);

    return {
      backgroundColor: isSelected
        ? colors.primary
        : isTodayDate
          ? (isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)')
          : 'transparent',
      color: isSelected
        ? (isDarkMode ? '#000' : '#fff')
        : !isCurrentMonth
          ? (isDarkMode ? 'rgba(255, 255, 255, 0.3)' : 'rgba(0, 0, 0, 0.3)')
          : colors.text,
      borderRadius: '50%',
      position: 'relative' as const,
      '::after': tasksForDay.length > 0 ? {
        content: '""',
        position: 'absolute',
        bottom: '2px',
        left: '50%',
        transform: 'translateX(-50%)',
        width: '4px',
        height: '4px',
        borderRadius: '50%',
        backgroundColor: isSelected ? '#fff' : colors.primary,
      } : undefined,
    };
  };

  // Days of week
  const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  return (
    <div
      style={calendarStyle}
      className="p-4 rounded-lg border shadow-sm backdrop-blur-md"
    >
      {/* Calendar Header */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold flex items-center">
          <CalendarDaysIcon className="w-6 h-6 mr-2" style={{ color: colors.primary }} />
          {format(currentMonth, 'MMMM yyyy')}
        </h2>

        <div className="flex space-x-2">
          <button
            onClick={prevMonth}
            className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
            aria-label="Previous month"
          >
            <ChevronLeftIcon className="w-5 h-5" />
          </button>

          <button
            onClick={() => setCurrentMonth(new Date())}
            className="px-3 py-1 rounded-md text-sm hover:bg-gray-100 dark:hover:bg-gray-800"
          >
            Today
          </button>

          <button
            onClick={nextMonth}
            className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
            aria-label="Next month"
          >
            <ChevronRightIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Days of Week */}
      <div className="grid grid-cols-7 gap-1 mb-2">
        {daysOfWeek.map((day) => (
          <div
            key={day}
            className="text-center text-sm font-medium py-2"
          >
            {day}
          </div>
        ))}
      </div>

      {/* Calendar Grid */}
      <div className="grid grid-cols-7 gap-1">
        {daysInMonth.map((day) => {
          const tasksForDay = getTasksForDay(day);

          return (
            <button
              key={day.toString()}
              onClick={() => handleDateClick(day)}
              className="aspect-square flex flex-col items-center justify-center p-1 relative hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              <span
                className="w-8 h-8 flex items-center justify-center"
                style={dayStyle(day)}
              >
                {format(day, 'd')}
              </span>

              {/* Task indicators */}
              {tasksForDay.length > 0 && (
                <div className="absolute bottom-1 flex space-x-0.5">
                  {tasksForDay.length <= 3 ? (
                    tasksForDay.slice(0, 3).map((task, index) => (
                      <div
                        key={index}
                        className="w-1 h-1 rounded-full"
                        style={{ backgroundColor: colors.primary }}
                      />
                    ))
                  ) : (
                    <>
                      <div
                        className="w-1 h-1 rounded-full"
                        style={{ backgroundColor: colors.primary }}
                      />
                      <div
                        className="w-1 h-1 rounded-full"
                        style={{ backgroundColor: colors.primary }}
                      />
                      <span
                        className="text-xs"
                        style={{ color: colors.primary }}
                      >
                        +{tasksForDay.length - 2}
                      </span>
                    </>
                  )}
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default MonthCalendar;

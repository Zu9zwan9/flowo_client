'use client';

import React, { useState } from 'react';
import { Task } from '@/types/models';
import { useTheme } from './ThemeProvider';
import { useTaskStore } from '@/store/useTaskStore';
import {
  CheckCircleIcon,
  PlayIcon,
  PauseIcon,
  StopIcon,
  ChevronRightIcon,
  ChevronDownIcon,
  ClockIcon,
  CalendarIcon
} from '@heroicons/react/24/outline';
import { CheckCircleIcon as CheckCircleSolidIcon } from '@heroicons/react/24/solid';
import { format } from 'date-fns';

interface TaskListItemProps {
  task: Task;
  showSubtasks?: boolean;
}

const TaskListItem: React.FC<TaskListItemProps> = ({
  task,
  showSubtasks = true
}) => {
  const { colors, isDarkMode } = useTheme();
  const [isExpanded, setIsExpanded] = useState(false);

  // Task actions from store
  const {
    completeTask,
    startTask,
    pauseTask,
    stopTask
  } = useTaskStore();

  // Format deadline
  const formattedDeadline = task.deadline
    ? format(new Date(task.deadline), 'MMM d, yyyy')
    : 'No deadline';

  // Format duration
  const formatDuration = (ms: number) => {
    const seconds = Math.floor((ms / 1000) % 60);
    const minutes = Math.floor((ms / (1000 * 60)) % 60);
    const hours = Math.floor(ms / (1000 * 60 * 60));

    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  };

  // Handle task actions
  const handleComplete = (e: React.MouseEvent) => {
    e.stopPropagation();
    completeTask(task.id);
  };

  const handleStart = (e: React.MouseEvent) => {
    e.stopPropagation();
    startTask(task.id);
  };

  const handlePause = (e: React.MouseEvent) => {
    e.stopPropagation();
    pauseTask(task.id);
  };

  const handleStop = (e: React.MouseEvent) => {
    e.stopPropagation();
    stopTask(task.id);
  };

  // Toggle expanded state
  const toggleExpanded = () => {
    if (task.subtasks.length > 0) {
      setIsExpanded(!isExpanded);
    }
  };

  // Dynamic styles
  const itemStyle = {
    backgroundColor: isDarkMode ? 'rgba(30, 30, 30, 0.8)' : 'rgba(255, 255, 255, 0.8)',
    borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
    color: task.isDone ? (isDarkMode ? 'rgba(255, 255, 255, 0.5)' : 'rgba(0, 0, 0, 0.5)') : colors.text,
  };

  const priorityColors = {
    1: { bg: 'rgba(255, 59, 48, 0.1)', text: '#FF3B30' }, // High - Red
    2: { bg: 'rgba(255, 149, 0, 0.1)', text: '#FF9500' }, // Medium - Orange
    3: { bg: 'rgba(52, 199, 89, 0.1)', text: '#34C759' }, // Low - Green
  };

  const priorityStyle = priorityColors[task.priority as keyof typeof priorityColors] || priorityColors[3];

  return (
    <div className="mb-2">
      <div
        style={itemStyle}
        className="flex items-center p-4 rounded-lg border shadow-sm backdrop-blur-md transition-all"
        onClick={toggleExpanded}
      >
        {/* Completion Status */}
        <button
          onClick={handleComplete}
          className="mr-3 flex-shrink-0"
          aria-label={task.isDone ? "Mark as incomplete" : "Mark as complete"}
        >
          {task.isDone ? (
            <CheckCircleSolidIcon
              className="w-6 h-6"
              style={{ color: colors.primary }}
            />
          ) : (
            <CheckCircleIcon
              className="w-6 h-6"
              style={{ color: colors.primary }}
            />
          )}
        </button>

        {/* Task Content */}
        <div className="flex-grow min-w-0">
          <div className="flex items-center">
            <h3
              className={`font-medium truncate ${task.isDone ? 'line-through' : ''}`}
              style={{ maxWidth: 'calc(100% - 80px)' }}
            >
              {task.title}
            </h3>

            {/* Priority Badge */}
            <span
              className="ml-2 px-2 py-0.5 text-xs rounded-full"
              style={{
                backgroundColor: priorityStyle.bg,
                color: priorityStyle.text
              }}
            >
              {task.priority === 1 ? 'High' : task.priority === 2 ? 'Medium' : 'Low'}
            </span>
          </div>

          {/* Task Details */}
          <div className="flex items-center mt-1 text-sm text-gray-500 dark:text-gray-400">
            <CalendarIcon className="w-4 h-4 mr-1" />
            <span className="mr-3">{formattedDeadline}</span>

            <ClockIcon className="w-4 h-4 mr-1" />
            <span>{formatDuration(task.totalDuration)}</span>

            {task.subtasks.length > 0 && (
              <span className="ml-3">
                {task.subtasks.filter(st => st.isDone).length}/{task.subtasks.length} subtasks
              </span>
            )}
          </div>
        </div>

        {/* Task Actions */}
        <div className="flex items-center ml-2 space-x-2">
          {!task.isDone && (
            <>
              {task.status === 'not_started' && (
                <button
                  onClick={handleStart}
                  className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                  aria-label="Start task"
                >
                  <PlayIcon className="w-5 h-5" style={{ color: colors.primary }} />
                </button>
              )}

              {task.status === 'in_progress' && (
                <>
                  <button
                    onClick={handlePause}
                    className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                    aria-label="Pause task"
                  >
                    <PauseIcon className="w-5 h-5" style={{ color: colors.primary }} />
                  </button>

                  <button
                    onClick={handleStop}
                    className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                    aria-label="Stop task"
                  >
                    <StopIcon className="w-5 h-5" style={{ color: colors.primary }} />
                  </button>
                </>
              )}

              {task.status === 'paused' && (
                <>
                  <button
                    onClick={handleStart}
                    className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                    aria-label="Resume task"
                  >
                    <PlayIcon className="w-5 h-5" style={{ color: colors.primary }} />
                  </button>

                  <button
                    onClick={handleStop}
                    className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
                    aria-label="Stop task"
                  >
                    <StopIcon className="w-5 h-5" style={{ color: colors.primary }} />
                  </button>
                </>
              )}
            </>
          )}

          {/* Expand/Collapse Button (only if has subtasks) */}
          {task.subtasks.length > 0 && (
            <button
              className="p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800"
              aria-label={isExpanded ? "Collapse" : "Expand"}
            >
              {isExpanded ? (
                <ChevronDownIcon className="w-5 h-5" />
              ) : (
                <ChevronRightIcon className="w-5 h-5" />
              )}
            </button>
          )}
        </div>
      </div>

      {/* Subtasks */}
      {showSubtasks && isExpanded && task.subtasks.length > 0 && (
        <div className="pl-8 mt-1 space-y-1">
          {task.subtasks.map(subtask => (
            <TaskListItem
              key={subtask.id}
              task={subtask}
              showSubtasks={true}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default TaskListItem;

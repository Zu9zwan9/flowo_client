import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { Task, Category, ScheduledTask, TaskSession } from '@/types/models';

interface TaskState {
  tasks: Task[];
  categories: Category[];

  // Task actions
  addTask: (task: Task) => void;
  updateTask: (taskId: string, updates: Partial<Task>) => void;
  deleteTask: (taskId: string) => void;
  completeTask: (taskId: string) => void;
  startTask: (taskId: string) => void;
  pauseTask: (taskId: string) => void;
  stopTask: (taskId: string) => void;

  // Category actions
  addCategory: (category: Category) => void;
  updateCategory: (categoryId: string, name: string) => void;
  deleteCategory: (categoryId: string) => void;

  // Scheduled task actions
  addScheduledTask: (taskId: string, scheduledTask: ScheduledTask) => void;
  updateScheduledTask: (taskId: string, scheduledTaskId: string, updates: Partial<ScheduledTask>) => void;
  deleteScheduledTask: (taskId: string, scheduledTaskId: string) => void;

  // Session actions
  addSession: (taskId: string, session: TaskSession) => void;
  endSession: (taskId: string, sessionId: string) => void;
}

export const useTaskStore = create<TaskState>()(
  persist(
    (set) => ({
      tasks: [],
      categories: [],

      // Task actions
      addTask: (task) => set((state) => ({
        tasks: [...state.tasks, task]
      })),

      updateTask: (taskId, updates) => set((state) => ({
        tasks: state.tasks.map((task) =>
          task.id === taskId ? { ...task, ...updates } : task
        )
      })),

      deleteTask: (taskId) => set((state) => ({
        tasks: state.tasks.filter((task) => task.id !== taskId)
      })),

      completeTask: (taskId) => set((state) => {
        const updatedTasks = state.tasks.map((task) => {
          if (task.id === taskId) {
            // End any active session
            const sessions = task.sessions.map(session =>
              session.isActive ? { ...session, isActive: false, endTime: new Date() } : session
            );

            // Calculate total duration
            const totalDuration = sessions.reduce((total, session) => {
              if (session.endTime) {
                const duration = session.endTime.getTime() - session.startTime.getTime();
                return total + duration;
              }
              return total;
            }, 0);

            return {
              ...task,
              isDone: true,
                status: 'completed' as const,
              sessions,
              totalDuration
            };
          }
          return task;
        });

        return { tasks: updatedTasks };
      }),

      startTask: (taskId) => set((state) => {
        const updatedTasks = state.tasks.map((task) => {
          if (task.id === taskId) {
            // End any active session first
            const sessions = task.sessions.map(session =>
              session.isActive ? { ...session, isActive: false, endTime: new Date() } : session
            );

            // Create a new session
            const newSession: TaskSession = {
              id: Date.now().toString(),
              taskId,
              startTime: new Date(),
              isActive: true,
              duration: 0
            };

            return {
              ...task,
                status: 'in_progress' as const,
              sessions: [...sessions, newSession]
            };
          }
          return task;
        });

        return { tasks: updatedTasks };
      }),

      pauseTask: (taskId) => set((state) => {
        const updatedTasks = state.tasks.map((task) => {
          if (task.id === taskId && task.status === 'in_progress') {
            // End the active session
            const sessions = task.sessions.map(session => {
              if (session.isActive) {
                const endTime = new Date();
                const duration = endTime.getTime() - session.startTime.getTime();
                return {
                  ...session,
                  isActive: false,
                  endTime,
                  duration
                };
              }
              return session;
            });

            // Calculate total duration
            const totalDuration = sessions.reduce((total, session) => {
              if (session.endTime) {
                return total + session.duration;
              }
              return total;
            }, 0);

            return {
              ...task,
                status: 'paused' as const,
              sessions,
              totalDuration
            };
          }
          return task;
        });

        return { tasks: updatedTasks };
      }),

      stopTask: (taskId) => set((state) => {
        const updatedTasks = state.tasks.map((task) => {
          if (task.id === taskId && (task.status === 'in_progress' || task.status === 'paused')) {
            // End any active session
            const sessions = task.sessions.map(session => {
              if (session.isActive) {
                const endTime = new Date();
                const duration = endTime.getTime() - session.startTime.getTime();
                return {
                  ...session,
                  isActive: false,
                  endTime,
                  duration
                };
              }
              return session;
            });

            // Calculate total duration
            const totalDuration = sessions.reduce((total, session) => {
              if (session.endTime) {
                return total + session.duration;
              }
              return total;
            }, 0);

            return {
              ...task,
                status: 'not_started' as const,              sessions,
              totalDuration
            };
          }
          return task;
        });

        return { tasks: updatedTasks };
      }),

      // Category actions
      addCategory: (category) => set((state) => ({
        categories: [...state.categories, category]
      })),

      updateCategory: (categoryId, name) => set((state) => ({
        categories: state.categories.map((category) =>
          category.id === categoryId ? { ...category, name } : category
        )
      })),

      deleteCategory: (categoryId) => set((state) => ({
        categories: state.categories.filter((category) => category.id !== categoryId)
      })),

      // Scheduled task actions
      addScheduledTask: (taskId, scheduledTask) => set((state) => ({
        tasks: state.tasks.map((task) =>
          task.id === taskId
            ? { ...task, scheduledTasks: [...task.scheduledTasks, scheduledTask] }
            : task
        )
      })),

      updateScheduledTask: (taskId, scheduledTaskId, updates) => set((state) => ({
        tasks: state.tasks.map((task) =>
          task.id === taskId
            ? {
                ...task,
                scheduledTasks: task.scheduledTasks.map((st) =>
                  st.id === scheduledTaskId ? { ...st, ...updates } : st
                )
              }
            : task
        )
      })),

      deleteScheduledTask: (taskId, scheduledTaskId) => set((state) => ({
        tasks: state.tasks.map((task) =>
          task.id === taskId
            ? {
                ...task,
                scheduledTasks: task.scheduledTasks.filter((st) => st.id !== scheduledTaskId)
              }
            : task
        )
      })),

      // Session actions
      addSession: (taskId, session) => set((state) => ({
        tasks: state.tasks.map((task) =>
          task.id === taskId
            ? { ...task, sessions: [...task.sessions, session] }
            : task
        )
      })),

      endSession: (taskId, sessionId) => set((state) => ({
        tasks: state.tasks.map((task) => {
          if (task.id === taskId) {
            const sessions = task.sessions.map((session) => {
              if (session.id === sessionId && session.isActive) {
                const endTime = new Date();
                const duration = endTime.getTime() - session.startTime.getTime();
                return {
                  ...session,
                  isActive: false,
                  endTime,
                  duration
                };
              }
              return session;
            });

            // Calculate total duration
            const totalDuration = sessions.reduce((total, session) => {
              if (session.endTime) {
                return total + session.duration;
              }
              return total;
            }, 0);

            return { ...task, sessions, totalDuration };
          }
          return task;
        })
      })),
    }),
    {
      name: 'task-storage',
    }
  )
);

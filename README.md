# Flowo

Flowo is a task management application built with Flutter and Dart. It helps users manage their tasks, schedules, and notifications efficiently.

## Features

- **Task Management**: Create, update, and delete tasks with various attributes.
- **Scheduling**: Schedule tasks with start and end times.
- **Notifications**: Set notifications for tasks.
- **Categorization**: Categorize tasks for better organization.
- **Location Tracking**: Add location coordinates to tasks.
- **Image Attachments**: Attach images to tasks.
- **Frequency Scheduling**: Schedule tasks on specific days and times.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK

### Environment Configuration

Flowo uses environment variables to manage sensitive data like API keys. Follow these steps to set up your environment:

1. Copy the `.env.template` file to a new file named `.env` in the project root:
   ```bash
   cp .env.template .env
   ```

2. Edit the `.env` file and replace the placeholder values with your actual API keys and configuration:
   ```
   AZURE_API_KEY=your_azure_api_key_here
   AZURE_API_URL=https://models.inference.ai.azure.com/chat/completions
   AI_MODEL=gpt-4o
   ```

3. Make sure not to commit your `.env` file to version control. It's already added to `.gitignore` to prevent accidental commits.

> **Note**: The application will still run without a valid API key, but AI-powered features like task breakdown and time estimation will use fallback values.

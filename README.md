# Flowo

<p align="center">
  <img src="assets/icon/app_icon.png" alt="Flowo Logo" width="120"/>
</p>

Flowo is a task management application designed specifically for neurodivergent individuals who struggle with planning, time management, and task breakdown. Built with Flutter, Flowo provides a structured yet flexible approach to managing daily activities, making it easier to navigate the challenges of executive functioning.

## 🧠 How Flowo Helps Neurodivergent People

Neurodivergent individuals often face unique challenges with:

- **Task Initiation**: Difficulty starting tasks due to overwhelm
- **Time Blindness**: Struggling to estimate how long tasks will take
- **Task Breakdown**: Finding it hard to break large tasks into manageable steps
- **Executive Functioning**: Challenges with planning, organizing, and prioritizing
- **Attention Management**: Difficulty maintaining focus for extended periods

Flowo addresses these challenges through:

- **AI-Powered Task Breakdown**: Automatically breaks down complex tasks into clear, actionable subtasks
- **Smart Time Estimation**: Uses three-point estimation (optimistic, realistic, pessimistic) to account for time blindness
- **Visual Task Hierarchy**: Clearly displays the relationship between tasks and subtasks
- **Flexible Scheduling**: Adapts to your natural rhythms rather than forcing rigid timeframes

## ✨ Key Features

- **Intelligent Task Breakdown**: AI-powered system that breaks down complex tasks into manageable subtasks with time estimates
- **Three-Point Time Estimation**: Account for uncertainty with optimistic, realistic, and pessimistic time estimates
- **Hierarchical Task Management**: Create, update, and organize tasks with parent-child relationships
- **Session Tracking**: Monitor time spent on tasks to improve future estimations
- **Smart Notifications**: Get reminders at the right time to stay on track
- **Visual Organization**: Categorize tasks with colors and labels for easier processing
- **Visual Aids**: Attach images to tasks for visual thinkers
- **Flexible Scheduling**: Set recurring tasks with customizable frequency patterns

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.7.0 <4.0.0)
- Dart SDK (>=3.7.0 <4.0.0)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/flowo_client.git
   cd flowo_client
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code for Hive adapters:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## 💡 Usage Examples

### Breaking Down a Complex Task

1. Create a new task with a title and estimated total time
2. Tap the "Break Down Task" button
3. The AI will suggest subtasks with time allocations
4. Review and adjust the subtasks as needed
5. Save to create all subtasks with proper scheduling

### Managing Time with Three-Point Estimation

1. Create a new task
2. Enter optimistic (best-case), realistic (likely), and pessimistic (worst-case) time estimates
3. The app will calculate a weighted average for scheduling
4. Track actual time spent for future improvement

### Setting Up Task Sessions

1. Start a task to begin a session
2. Pause when taking breaks
3. Resume when returning to the task
4. Complete the task to end the session
5. Review session data to improve future time estimates

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📱 Screenshots

*Coming soon*

## 📞 Support

If you encounter any problems or have any questions, please open an issue on GitHub or contact the development team.

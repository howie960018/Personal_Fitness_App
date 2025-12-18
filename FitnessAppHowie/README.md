# FitHowie - Personal Fitness Tracker 

FitHowie is a comprehensive iOS fitness tracking application built entirely with **SwiftUI** and **SwiftData**. It allows users to log workouts, track daily health metrics, manage nutrition, and visualize progress through interactive charts.

Designed for fitness enthusiasts who want detailed insights into their training volume, muscle balance, and body composition trends.


##  Key Features

### Dashboard & Daily Tracking
- **Daily Overview**: Quick glance at today's weight, steps, resting heart rate, and sleep duration.
- **History Log**: View past records with a scrollable history list.
- **Quick Actions**: Fast access to log workouts, nutrition, or daily metrics.

### Advanced Workout Logger
- **Customizable Routines**: Support for both Aerobic and Anaerobic (Strength) training.
- **Detailed Set Tracking**: Log weight, reps, and sets for specific exercises.
- **Drag & Drop Sorting**: Reorder exercises within a workout session easily.
- **Media Integration**: **Attach photos or videos** to specific exercises to track PRs (Personal Records) or check form.
- **In-App Video Playback**: Review exercise videos directly within the workout detail view with custom playback controls.

### Analytics & Visualization
- **Health Carousel**: Swipeable charts for Weight, Steps, Heart Rate, and Sleep trends (Last 30 days).
- **Muscle Balance Analysis**: Visual breakdown of training volume by muscle group (Chest, Back, Legs, etc.).
- **Volume Trends**: Track total training volume (kg) over time.
- **Nutrition Breakdown**: Analysis of macronutrient intake (Protein, Carbs, Fats, Veggies).

### Nutrition Tracking
- Log daily food intake using a simple hand-portion method or precise measurements.
- Track macronutrient distribution.

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Database**: **SwiftData** (Persisting complex relationships between Workouts, Exercises, and Sets)
- **Charts**: **Swift Charts** (Interactive and customizable data visualization)
- **Media**: AVKit (Video playback), PhotosUI (Media selection)
- **Concurrency**: Swift Concurrency (async/await)

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Project Structure

- **Models**: Defines SwiftData schema (`WorkoutRecord`, `ExerciseSet`, `DailyLog`, etc.).
- **Views**:
  - `DashboardView`: Main hub for daily activities.
  - `WorkoutLoggerView` & `AddWorkoutView`: Core logic for training recording.
  - `AnalyticsView`: Data visualization using Swift Charts.
- **Helpers**: Custom Enums (`MuscleGroup`, `TrainingType`) and extension utilities.

## Author

**Howie Tseng**
- GitHub: [howie960018](https://github.com/howie960018)

---
*This project is created for personal practice and portfolio demonstration.*

# Share2Read

**Share2Read** is a Flutter-based mobile application that allows users to seamlessly share and view URLs from external sources within the app. This project is structured following the Clean Architecture principles, and it leverages the BLoC pattern for state management to ensure a scalable and maintainable codebase.

## Features

- **Share Media**: Automatically detects and processes shared media from other apps.
- **URL Extraction**: Extracts URLs (specifically Medium links) from shared content.
- **Web View**: Displays the extracted URL within an in-app WebView.
- **Responsive UI**: Adapts the UI for a seamless user experience.

## Project Structure

The project follows the Clean Architecture pattern, with a clear separation of concerns into the following layers:

- **Presentation Layer**: Contains the UI and BLoC for managing state.
  - `pages/` - Screens and widgets displayed to the user.
  - `bloc/` - BLoC classes handling the application's state management.
  
- **Domain Layer**: Encapsulates the business logic.
  - `entities/` - Core entities of the application.
  - `usecases/` - Application-specific business logic.

- **Data Layer**: Handles data retrieval and management.
  - `models/` - Data models representing structures received from the data sources.
  - `repositories/` - Implementation of repositories responsible for data operations.

## Getting Started

### Prerequisites

Ensure you have the following installed:

- Flutter SDK
- Dart SDK
- A code editor like Visual Studio Code or Android Studio
- An Android or iOS device/emulator for testing


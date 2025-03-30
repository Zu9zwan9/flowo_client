# Flowo Task API Server

This server provides APIs for task breakdown and time estimation using HuggingFace models. It follows SOLID principles and best practices for API design.

## Features

- Task breakdown API: Breaks down tasks into subtasks with time estimates
- Task time estimation API: Estimates time for subtasks based on their content
- API key authentication: Secures the API with API key authentication
- Error handling: Provides fallback mechanisms for when the AI model fails
- Logging: Logs requests and responses for debugging

## Architecture

The server follows a clean architecture with separation of concerns:

- **API Layer**: Handles HTTP requests and responses
- **Service Layer**: Contains business logic and communicates with external services
- **Core Layer**: Contains core functionality like authentication

### SOLID Principles

- **Single Responsibility Principle**: Each class has a single responsibility
- **Open/Closed Principle**: Classes are open for extension but closed for modification
- **Liskov Substitution Principle**: Subtypes can be substituted for their base types
- **Interface Segregation Principle**: Clients are not forced to depend on interfaces they don't use
- **Dependency Inversion Principle**: High-level modules depend on abstractions, not low-level modules

## Setup

### Prerequisites

- Python 3.8 or higher
- HuggingFace API key

### Installation

1. Install the required packages:

```bash
pip install -r requirements.txt
```

2. Create a `.env` file in the server directory with the following variables:

```
API_KEY=your_api_key_for_clients
HUGGINGFACE_API_KEY=your_huggingface_api_key
```

### Running the Server

```bash
cd server
python -m uvicorn main:app --reload
```

The server will be available at http://localhost:8000.

## API Documentation

Once the server is running, you can access the API documentation at http://localhost:8000/docs.

### Endpoints

- `POST /api/breakdown`: Breaks down a task into subtasks with time estimates
- `POST /api/estimate`: Estimates time for subtasks based on their content
- `GET /health`: Health check endpoint (no authentication required)

### Authentication

All API endpoints (except `/health`) require an API key to be provided in the `X-API-Key` header.

## Integration with Flutter Client

The Flutter client has been updated to communicate with this server instead of directly with HuggingFace. The following components have been added:

- `ServerApiClient`: Client for communicating with the server API
- `ServerTaskBreakdownAPI`: Uses the server API for task breakdown
- `ServerTimeEstimationStrategy`: Uses the server API for task time estimation
- `ServerProvider`: Provides server-based implementations for dependency injection

To use the server in the Flutter client, add the following to your `main.dart`:

```dart
import 'package:flowo_client/services/server_provider.dart';

// Add server providers to the provider tree
MultiProvider(
  providers: [
    // Existing providers...
    
    // Add server providers
    ...ServerProvider.createProviders(
      serverUrl: 'http://localhost:8000',
      apiKey: 'your_api_key',
    ),
  ],
  child: MyApp(),
)
```

## Benefits

- **Security**: API keys are not exposed in the client code
- **Performance**: Reduces load on client devices by offloading AI processing to the server
- **Maintainability**: Server-side logic can be updated without updating the client
- **Scalability**: Server can be scaled independently of the client

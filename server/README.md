# Flowo Task API Server

This server provides APIs for task breakdown and time estimation using HuggingFace models. It follows SOLID principles and best practices for API design.

## Implementation Summary

To satisfy the requirement that "it should be the separate server from project and be connected to app only using requests, also needs to remove api key for models from project", the following changes have been made:

1. **Server Implementation**:
   - Created a FastAPI server in the `/server` directory
   - Implemented API endpoints for task breakdown and time estimation
   - Added authentication using API keys
   - Moved all HuggingFace API interactions to the server

2. **Client Implementation**:
   - Created `ServerApiClient` to communicate with the server
   - Created `ServerTaskBreakdownAPI` to use the server for task breakdown
   - Created `ServerTimeEstimationStrategy` to use the server for time estimation
   - Created `ServerTaskManager` to use the server-based implementations
   - Removed all direct API key references from the client code

## Server Architecture

The server follows a clean architecture with separation of concerns:

- **API Layer**: Handles HTTP requests and responses
- **Service Layer**: Contains business logic and communicates with external services
- **Core Layer**: Contains core functionality like authentication

### API Endpoints

- `POST /api/breakdown`: Breaks down a task into subtasks with time estimates
- `POST /api/estimate`: Estimates time for subtasks based on their content
- `GET /health`: Health check endpoint (no authentication required)

### Authentication

All API endpoints (except `/health`) require an API key to be provided in the `X-API-Key` header.

## Client Implementation

The client has been updated to communicate with this server instead of directly with HuggingFace:

1. **ServerApiClient**: Client for communicating with the server API
2. **ServerTaskBreakdownAPI**: Uses the server API for task breakdown
3. **ServerTimeEstimationStrategy**: Uses the server API for task time estimation
4. **ServerTaskManager**: Uses the server-based implementations

## Configuration

To use this implementation:

1. Start the server:
   ```bash
   cd server
   python -m uvicorn main:app --reload
   ```

2. Update the client code:
   - Add imports for server-based implementations
   - Create server API client with your server URL and API key
   - Create server task breakdown API
   - Create server task manager

## Benefits

- **Security**: API keys are not exposed in the client code
- **Performance**: Reduces load on client devices by offloading AI processing to the server
- **Maintainability**: Server-side logic can be updated without updating the client
- **Scalability**: Server can be scaled independently of the client

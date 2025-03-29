from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from server.api.models import (
    TaskBreakdownRequest,
    TaskBreakdownResponse,
    SubTask,
    TaskEstimationRequest,
    TaskEstimationResponse,
)
from server.services.huggingface_service import HuggingFaceService

# Create API router
api_router = APIRouter(tags=["Tasks"])

# Create HuggingFace service
huggingface_service = HuggingFaceService()

@api_router.post(
    "/breakdown",
    response_model=TaskBreakdownResponse,
    status_code=status.HTTP_200_OK,
    summary="Break down a task into subtasks",
    description="Break down a task into subtasks with time estimates",
)
async def breakdown_task(request: TaskBreakdownRequest):
    """
    Break down a task into subtasks with time estimates
    
    Args:
        request: The task breakdown request
        
    Returns:
        A response with a list of subtasks
    """
    # Break down the task
    subtasks = await huggingface_service.breakdown_task(
        request.task,
        request.total_time,
    )
    
    # Convert to response model
    return TaskBreakdownResponse(
        subtasks=[
            SubTask(
                title=subtask["title"],
                estimated_time=subtask["estimated_time"],
            )
            for subtask in subtasks
        ]
    )

@api_router.post(
    "/estimate",
    response_model=TaskEstimationResponse,
    status_code=status.HTTP_200_OK,
    summary="Estimate time for subtasks",
    description="Estimate time for a list of subtasks based on their content, parent task's estimated time, and deadline",
)
async def estimate_subtask_times(request: TaskEstimationRequest):
    """
    Estimate time for a list of subtasks
    
    Args:
        request: The task estimation request
        
    Returns:
        A response with a list of estimated times
    """
    # Estimate time for subtasks
    estimates = await huggingface_service.estimate_subtask_times(
        request.subtask_titles,
        request.parent_estimated_time,
        request.parent_deadline,
    )
    
    # Return the estimates
    return TaskEstimationResponse(estimates=estimates)

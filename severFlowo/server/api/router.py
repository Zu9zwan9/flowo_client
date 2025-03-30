from fastapi import APIRouter, status
from typing import List
from server.api.models import (
    TaskBreakdownRequest, TaskBreakdownResponse, SubTask,
    TaskEstimationRequest, TaskEstimationResponse
)
from server.services.huggingface_service import HuggingFaceService

api_router = APIRouter(tags=["Tasks"])
huggingface_service = HuggingFaceService()

@api_router.post(
    "/breakdown",
    response_model=TaskBreakdownResponse,
    status_code=status.HTTP_200_OK,
)
async def breakdown_task(request: TaskBreakdownRequest):
    subtasks = await huggingface_service.breakdown_task(request.task, request.total_time)
    return TaskBreakdownResponse(
        subtasks=[SubTask(title=s["title"], estimated_time=s["estimated_time"]) for s in subtasks]
    )

@api_router.post(
    "/estimate",
    response_model=TaskEstimationResponse,
    status_code=status.HTTP_200_OK,
)
async def estimate_subtask_times(request: TaskEstimationRequest):
    estimates = await huggingface_service.estimate_subtask_times(
        request.subtask_titles, request.parent_estimated_time, request.parent_deadline
    )
    return TaskEstimationResponse(estimates=estimates)
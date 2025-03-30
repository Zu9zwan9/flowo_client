from pydantic import BaseModel, Field
from typing import List, Optional

class TaskBreakdownRequest(BaseModel):
    task: str = Field(..., description="The task to break down")
    total_time: int = Field(..., description="The total estimated time for the task in minutes")

    class Config:
        json_schema_extra = {
            "example": {"task": "Write a blog post", "total_time": 60}
        }

class SubTask(BaseModel):
    title: str = Field(..., description="The title of the subtask")
    estimated_time: int = Field(..., description="The estimated time for the subtask in minutes")

    class Config:
        json_schema_extra = {
            "example": {"title": "Research topic", "estimated_time": 20}
        }

class TaskBreakdownResponse(BaseModel):
    subtasks: List[SubTask] = Field(..., description="The list of subtasks")

    class Config:
        json_schema_extra = {
            "example": {
                "subtasks": [
                    {"title": "Research topic", "estimated_time": 20},
                    {"title": "Draft post", "estimated_time": 30},
                    {"title": "Review", "estimated_time": 10}
                ]
            }
        }

class TaskEstimationRequest(BaseModel):
    subtask_titles: List[str] = Field(..., description="The list of subtask titles")
    parent_estimated_time: int = Field(..., description="The total estimated time for the parent task in minutes")
    parent_deadline: Optional[int] = Field(None, description="The deadline for the parent task in Unix timestamp (milliseconds)")

    class Config:
        json_schema_extra = {
            "example": {
                "subtask_titles": ["Research topic", "Draft post", "Review"],
                "parent_estimated_time": 60,
                "parent_deadline": 1735689600000  # Example: 2025-01-01
            }
        }

class TaskEstimationResponse(BaseModel):
    estimates: List[int] = Field(..., description="The list of estimated times for each subtask in minutes")

    class Config:
        json_schema_extra = {
            "example": {"estimates": [20, 30, 10]}
        }
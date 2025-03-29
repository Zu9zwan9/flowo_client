from pydantic import BaseModel, Field
from typing import List, Optional

class TaskBreakdownRequest(BaseModel):
    """
    Request model for task breakdown
    """
    task: str = Field(..., description="The task to break down")
    total_time: int = Field(..., description="The total estimated time for the task in minutes")
    
    class Config:
        schema_extra = {
            "example": {
                "task": "Write a research paper on AI",
                "total_time": 120
            }
        }

class SubTask(BaseModel):
    """
    Model for a subtask
    """
    title: str = Field(..., description="The title of the subtask")
    estimated_time: int = Field(..., description="The estimated time for the subtask in minutes")
    
    class Config:
        schema_extra = {
            "example": {
                "title": "Research the topic",
                "estimated_time": 30
            }
        }

class TaskBreakdownResponse(BaseModel):
    """
    Response model for task breakdown
    """
    subtasks: List[SubTask] = Field(..., description="The list of subtasks")
    
    class Config:
        schema_extra = {
            "example": {
                "subtasks": [
                    {"title": "Research the topic", "estimated_time": 30},
                    {"title": "Create an outline", "estimated_time": 15},
                    {"title": "Write the first draft", "estimated_time": 45},
                    {"title": "Review and revise", "estimated_time": 30}
                ]
            }
        }

class TaskEstimationRequest(BaseModel):
    """
    Request model for task time estimation
    """
    subtask_titles: List[str] = Field(..., description="The list of subtask titles")
    parent_estimated_time: int = Field(..., description="The total estimated time for the parent task in minutes")
    parent_deadline: Optional[int] = Field(None, description="The deadline for the parent task in Unix timestamp (milliseconds)")
    
    class Config:
        schema_extra = {
            "example": {
                "subtask_titles": [
                    "Research the topic",
                    "Create an outline",
                    "Write the first draft",
                    "Review and revise"
                ],
                "parent_estimated_time": 120,
                "parent_deadline": 1672531200000  # Example timestamp
            }
        }

class TaskEstimationResponse(BaseModel):
    """
    Response model for task time estimation
    """
    estimates: List[int] = Field(..., description="The list of estimated times for each subtask in minutes")
    
    class Config:
        schema_extra = {
            "example": {
                "estimates": [30, 15, 45, 30]
            }
        }

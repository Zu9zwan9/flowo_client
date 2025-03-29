import os
import json
import re
import httpx
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class HuggingFaceService:
    """
    Service for interacting with HuggingFace API
    """
    def __init__(self):
        """
        Initialize the HuggingFace service with API key from environment variables
        """
        self.api_key = os.getenv("HUGGINGFACE_API_KEY")
        if not self.api_key:
            raise ValueError("HUGGINGFACE_API_KEY environment variable not set")
        
        self.model = "HuggingFaceH4/zephyr-7b-beta"
        self.api_url = f"https://router.huggingface.co/hf-inference/models/{self.model}"
    
    async def _make_request(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        """
        Make a request to the HuggingFace API
        
        Args:
            messages: List of message dictionaries with 'role' and 'content' keys
            
        Returns:
            The API response
            
        Raises:
            Exception: If the request fails
        """
        data = {
            "inputs": json.dumps(messages),
            "parameters": {"max_new_tokens": 500, "return_full_text": False},
        }
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self.api_url,
                    headers=headers,
                    json=data,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    print(f"Error from HuggingFace API: {response.status_code} - {response.text}")
                    # Return fallback response
                    return {
                        "generated_text": "1. Research the topic (30 minutes)\n2. Create an outline (15 minutes)\n3. Draft the content (45 minutes)\n4. Review and revise (30 minutes)\n5. Finalize the work (15 minutes)",
                    }
        except Exception as e:
            print(f"Exception making request to HuggingFace API: {e}")
            # Return fallback response
            return {
                "generated_text": "1. Research the topic (30 minutes)\n2. Create an outline (15 minutes)\n3. Draft the content (45 minutes)\n4. Review and revise (30 minutes)\n5. Finalize the work (15 minutes)",
            }
    
    def _extract_text(self, response: Any) -> str:
        """
        Extract the generated text from the API response
        
        Args:
            response: The API response
            
        Returns:
            The generated text
        """
        if response is None:
            return ""
        
        try:
            if isinstance(response, list) and response:
                return response[0].get("generated_text", "")
            elif isinstance(response, dict):
                return response.get("generated_text", "")
            else:
                return ""
        except Exception as e:
            print(f"Error extracting text from response: {e}")
            return ""
    
    async def breakdown_task(self, task: str, total_time: int) -> List[Dict[str, Any]]:
        """
        Break down a task into subtasks with time estimates
        
        Args:
            task: The task to break down
            total_time: The total estimated time for the task in minutes
            
        Returns:
            A list of subtasks with titles and estimated times
        """
        if not task:
            return []
        
        # Create the prompt for the AI
        messages = [
            {
                "role": "user",
                "content": (
                    f"You are a helpful assistant that breaks down tasks into clear, actionable subtasks and distributes "
                    f"the total estimated time among them. The total estimated time for the task is {total_time} minutes. "
                    f"Format your response as a numbered list, where each subtask is followed by its estimated time in "
                    f"minutes in parentheses, like this: '1. Subtask (X minutes)'. Break down the task into specific "
                    f"subtasks and ensure the sum of the subtask times equals {total_time} minutes: {task}"
                )
            }
        ]
        
        # Make the request to the HuggingFace API
        response = await self._make_request(messages)
        
        # Extract the generated text
        text = self._extract_text(response)
        
        # Parse the subtasks
        return self._parse_subtasks(text)
    
    def _parse_subtasks(self, text: str) -> List[Dict[str, Any]]:
        """
        Parse the subtasks from the generated text
        
        Args:
            text: The generated text
            
        Returns:
            A list of subtasks with titles and estimated times
        """
        if not text:
            return []
        
        subtasks = []
        # Regular expression to match lines like "1. Subtask (X minutes)"
        pattern = r'^\d+\.\s*(.+?)\s*\((\d+)\s*minutes?\)$'
        
        for line in text.strip().split('\n'):
            match = re.match(pattern, line.strip())
            if match:
                title = match.group(1).strip()
                minutes = int(match.group(2))
                subtasks.append({
                    "title": title,
                    "estimated_time": minutes
                })
        
        return subtasks
    
    async def estimate_subtask_times(
        self, 
        subtask_titles: List[str], 
        parent_estimated_time: int,
        parent_deadline: Optional[int] = None
    ) -> List[int]:
        """
        Estimate time for a list of subtasks
        
        Args:
            subtask_titles: The list of subtask titles
            parent_estimated_time: The total estimated time for the parent task in minutes
            parent_deadline: The deadline for the parent task in Unix timestamp (milliseconds)
            
        Returns:
            A list of estimated times for each subtask in minutes
        """
        if not subtask_titles:
            return []
        
        # Format the subtasks as a numbered list
        subtasks_list = "\n".join([f"{i+1}. {title}" for i, title in enumerate(subtask_titles)])
        
        # Calculate time until deadline in hours if provided
        time_until_deadline = ""
        if parent_deadline:
            import time
            now = int(time.time() * 1000)  # Current time in milliseconds
            hours_until_deadline = (parent_deadline - now) // (1000 * 60 * 60)
            time_until_deadline = f" and a deadline in {hours_until_deadline} hours"
        
        # Create the prompt for the AI
        messages = [
            {
                "role": "user",
                "content": (
                    f"I have a task with an estimated total time of {parent_estimated_time} minutes{time_until_deadline}. "
                    f"The task is broken down into the following subtasks:\n"
                    f"{subtasks_list}\n\n"
                    f"Please estimate how many minutes each subtask will take, considering the total estimated time of {parent_estimated_time} minutes. "
                    f"Respond with only a JSON array of integers representing the estimated minutes for each subtask in order, like [30, 45, 60, ...]. "
                    f"The sum of all estimates should be approximately equal to the total estimated time."
                )
            }
        ]
        
        # Make the request to the HuggingFace API
        response = await self._make_request(messages)
        
        # Extract the generated text
        text = self._extract_text(response)
        
        # Parse the time estimates
        return self._parse_time_estimates(text, len(subtask_titles), parent_estimated_time)
    
    def _parse_time_estimates(self, text: str, subtask_count: int, total_time: int) -> List[int]:
        """
        Parse the time estimates from the generated text
        
        Args:
            text: The generated text
            subtask_count: The number of subtasks
            total_time: The total estimated time for the parent task in minutes
            
        Returns:
            A list of estimated times for each subtask in minutes
        """
        if not text:
            return self._distribute_proportionally(subtask_count, total_time)
        
        try:
            # Extract JSON array from the response
            json_regex = r'\[[\d\s,]+\]'
            match = re.search(json_regex, text)
            
            if match:
                json_str = match.group(0)
                estimates = json.loads(json_str)
                
                # Convert to list of integers
                time_estimates = [int(e) for e in estimates]
                
                # Validate the estimates
                if len(time_estimates) == subtask_count:
                    # Check if the sum is reasonably close to the total time
                    sum_estimates = sum(time_estimates)
                    if sum_estimates > 0 and abs(sum_estimates - total_time) <= total_time * 0.2:  # Allow 20% deviation
                        return time_estimates
            
            # If we couldn't parse valid estimates, distribute proportionally
            return self._distribute_proportionally(subtask_count, total_time)
        except Exception as e:
            print(f"Error parsing time estimates: {e}")
            return self._distribute_proportionally(subtask_count, total_time)
    
    def _distribute_proportionally(self, subtask_count: int, total_time: int) -> List[int]:
        """
        Distribute time proportionally among subtasks (fallback method)
        
        Args:
            subtask_count: The number of subtasks
            total_time: The total estimated time for the parent task in minutes
            
        Returns:
            A list of estimated times for each subtask in minutes
        """
        base_time = total_time // subtask_count
        remainder = total_time % subtask_count
        
        return [base_time + 1 if i < remainder else base_time for i in range(subtask_count)]

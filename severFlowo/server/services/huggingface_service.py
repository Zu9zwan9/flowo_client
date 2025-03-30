import os
import json
import re
import httpx
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()

def _extract_text(response: Any) -> str:
    if response is None:
        return ""
    try:
        if isinstance(response, list) and response:
            if "generated_text" in response[0]:
                return response[0].get("generated_text", "")
            else:
                # Try to extract text from other fields
                return str(response[0])
        elif isinstance(response, dict):
            if "generated_text" in response:
                return response.get("generated_text", "")
            else:
                # Try to extract text from other fields
                for key, value in response.items():
                    if isinstance(value, str) and value:
                        return value
                return str(response)
        return str(response)
    except Exception as e:
        print(f"Error extracting text: {e}")
        return ""

def _parse_subtasks(text: str) -> List[Dict[str, Any]]:
    if not text:
        return []
    subtasks = []
    # Try different patterns to match subtasks
    patterns = [
        r'^\d+\.\s*(.+?)\s*\((\d+)\s*minutes?\)$',  # 1. Subtask (X minutes)
        r'^\d+\.\s*(.+?)\s*-\s*(\d+)\s*minutes?$',  # 1. Subtask - X minutes
        r'^\d+\.\s*(.+?)\s*:\s*(\d+)\s*minutes?$',  # 1. Subtask: X minutes
        r'^\d+\.\s*(.+?)\s*\((\d+)\s*min\)$',       # 1. Subtask (X min)
        r'^\d+\.\s*(.+?)\s*\((\d+)\)$',             # 1. Subtask (X)
        r'^\d+\.\s*(.+?)$'                          # 1. Subtask (no time specified)
    ]

    for line in text.strip().split('\n'):
        line = line.strip()
        if not line:
            continue

        matched = False
        for pattern in patterns:
            match = re.match(pattern, line)
            if match:
                title = match.group(1).strip()
                # If time is specified, use it; otherwise, default to 10 minutes
                estimated_time = int(match.group(2)) if len(match.groups()) > 1 else 10
                subtasks.append({
                    "title": title,
                    "estimated_time": estimated_time
                })
                matched = True
                break

        # If no pattern matched but line starts with a number, try to extract title
        if not matched and re.match(r'^\d+\.', line):
            title = re.sub(r'^\d+\.\s*', '', line).strip()
            if title:
                subtasks.append({
                    "title": title,
                    "estimated_time": 10  # Default to 10 minutes
                })

    return subtasks

def _distribute_proportionally(subtask_count: int, total_time: int) -> List[int]:
    base_time = total_time // subtask_count
    remainder = total_time % subtask_count
    return [base_time + 1 if i < remainder else base_time for i in range(subtask_count)]

class HuggingFaceService:
    def __init__(self):
        self.api_key = os.getenv("HUGGINGFACE_API_KEY")
        if not self.api_key:
            raise ValueError("HUGGINGFACE_API_KEY not set")
        self.model = "HuggingFaceH4/zephyr-7b-beta"
        self.api_url = f"https://api-inference.huggingface.co/models/{self.model}"

    async def _make_request(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        data = {
            "inputs": messages[0]["content"],
            "parameters": {"max_new_tokens": 500, "return_full_text": False},
        }
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(self.api_url, headers=headers, json=data, timeout=30.0)
                if response.status_code == 200:
                    return response.json()
                print(f"API Error: {response.status_code} - {response.text}")
                return {"generated_text": "1. Research (20 minutes)\n2. Draft (30 minutes)\n3. Review (10 minutes)"}
            except Exception as e:
                print(f"Request Exception: {e}")
                return {"generated_text": "1. Research (20 minutes)\n2. Draft (30 minutes)\n3. Review (10 minutes)"}

    async def breakdown_task(self, task: str, total_time: int) -> List[Dict[str, Any]]:
        if not task:
            return []
        messages = [{
            "role": "user",
            "content": (
                f"Break down this task into specific subtasks with estimated times in minutes, "
                f"ensuring the total equals {total_time} minutes. Format as a numbered list: "
                f"'1. Subtask (X minutes)'. Task: {task}"
            )
        }]
        response = await self._make_request(messages)
        text = _extract_text(response)
        return _parse_subtasks(text)

    async def estimate_subtask_times(
        self, subtask_titles: List[str], parent_estimated_time: int, parent_deadline: Optional[int] = None
    ) -> List[int]:
        if not subtask_titles:
            return []
        subtasks_list = "\n".join([f"{i+1}. {title}" for i, title in enumerate(subtask_titles)])
        deadline_info = f" and a deadline at {parent_deadline} (Unix timestamp in ms)" if parent_deadline else ""
        messages = [{
            "role": "user",
            "content": (
                f"Estimate time in minutes for these subtasks, given a total of {parent_estimated_time} minutes{deadline_info}. "
                f"Respond with a JSON array of integers, e.g., [20, 30, 10]. Subtasks:\n{subtasks_list}"
            )
        }]
        response = await self._make_request(messages)
        text = _extract_text(response)
        # Try multiple approaches to extract estimates
        try:
            # First, try to find a JSON array in the text
            match = re.search(r'\[[\d\s,]+\]', text)
            if match:
                estimates = json.loads(match.group(0))
                if len(estimates) == len(subtask_titles) and sum(estimates) <= parent_estimated_time * 1.2:
                    return estimates

            # If that fails, try to find numbers in the text
            if not match:
                # Look for patterns like "1: 20 minutes", "Task 1: 20", etc.
                estimates = []
                patterns = [
                    r'\b(\d+)\s*(?:minutes|mins|min)\b',  # 20 minutes, 20 mins, 20 min
                    r':\s*(\d+)',                         # : 20
                    r'-\s*(\d+)',                         # - 20
                    r'\((\d+)\)'                          # (20)
                ]

                lines = text.strip().split('\n')
                for i, line in enumerate(lines):
                    if i >= len(subtask_titles):
                        break

                    for pattern in patterns:
                        matches = re.findall(pattern, line)
                        if matches:
                            # Use the first match
                            estimates.append(int(matches[0]))
                            break

                if len(estimates) == len(subtask_titles):
                    return estimates

        except Exception as e:
            print(f"Parse Error: {e}")

        # If all else fails, distribute proportionally
        return _distribute_proportionally(len(subtask_titles), parent_estimated_time)

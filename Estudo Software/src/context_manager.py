from __future__ import annotations

from collections import deque
from typing import Deque, List


class ContextManager:
    def __init__(self, max_window: int = 8) -> None:
        self.max_window = max_window
        self.window: Deque[str] = deque(maxlen=max_window)
        self.summary = ""

    def update(self, transcript_segment: str) -> str:
        segment = transcript_segment.strip()
        if not segment:
            return self.summary
        self.window.append(segment)
        self.summary = " ".join(self.window)
        return self.summary

    def current_context(self) -> str:
        return self.summary

    def relevant_history(self, max_items: int = 4) -> List[str]:
        return list(self.window)[-max_items:]

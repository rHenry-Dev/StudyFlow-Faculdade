from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict


class TranscriptStorage:
    def __init__(self, base_dir: str = "transcripts") -> None:
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

    def save_transcript(self, text: str) -> Path:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_path = self.base_dir / f"transcricao_{timestamp}.txt"
        file_path.write_text(text, encoding="utf-8")
        return file_path

    def save_analysis(self, payload: Dict[str, Any]) -> Path:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_path = self.base_dir / f"analise_{timestamp}.json"
        file_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        return file_path

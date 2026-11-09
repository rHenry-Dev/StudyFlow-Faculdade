from __future__ import annotations

import queue
import logging
import threading
from typing import Callable, List, Optional

import numpy as np

try:
    from faster_whisper import WhisperModel
except ImportError:  # pragma: no cover
    WhisperModel = None


class TranscriptionService:
    def __init__(self, model_size: str = "small", device: str = "cpu") -> None:
        self.model = None
        self.model_error: Optional[str] = None
        self._initialize_model(model_size, device)

    def _initialize_model(self, model_size: str, device: str) -> None:
        if WhisperModel is None:
            self.model_error = "faster-whisper não instalado."
            return
        try:
            self.model = WhisperModel(model_size, device=device, compute_type="int8")
        except Exception as exc:  # pragma: no cover
            self.model_error = f"Não foi possível iniciar o Whisper: {exc}"
            logging.exception("Não foi possível iniciar o modelo Faster-Whisper")

    def transcribe_chunk(self, audio_chunk: np.ndarray) -> str:
        if audio_chunk is None or audio_chunk.size == 0:
            return ""

        if self.model is None:
            self.model_error = self.model_error or "O modelo Faster-Whisper não está disponível."
            return ""

        try:
            audio = np.asarray(audio_chunk, dtype=np.float32)
            if audio.ndim == 2:
                audio = audio.mean(axis=1)
            audio = np.ascontiguousarray(audio.reshape(-1))
            if audio.size == 0:
                return ""
            segments, _ = self.model.transcribe(
                audio,
                language="pt",
                vad_filter=True,
                beam_size=5,
            )
            texts = [segment.text.strip() for segment in segments if segment.text and segment.text.strip()]
            return " ".join(texts)
        except Exception as exc:
            self.model_error = f"Falha ao transcrever áudio com Whisper: {exc}"
            logging.exception("Falha ao transcrever áudio com Faster-Whisper")
            return ""


class TranscriptionWorker:
    def __init__(
        self,
        audio_queue: "queue.Queue[np.ndarray]",
        callback: Callable[[str], None],
        sample_rate: int = 16000,
        chunk_seconds: int = 5,
    ) -> None:
        self.audio_queue = audio_queue
        self.callback = callback
        self.service = TranscriptionService()
        self.sample_rate = sample_rate
        self.chunk_seconds = chunk_seconds
        self.last_error: Optional[str] = self.service.model_error
        self._thread: Optional[threading.Thread] = None
        self._running = False

    def start(self) -> bool:
        if self._running:
            return True
        if self.service.model is None:
            self.last_error = self.service.model_error or "O modelo Whisper não está disponível."
            return False
        self.last_error = None
        self._running = True
        self._thread = threading.Thread(target=self._consume, daemon=True)
        self._thread.start()
        return True

    def stop(self) -> None:
        self._running = False
        if self._thread is not None and self._thread.is_alive():
            self._thread.join()

    def _consume(self) -> None:
        buffered_chunks: List[np.ndarray] = []
        buffered_samples = 0
        minimum_samples = self.sample_rate * self.chunk_seconds

        while self._running or not self.audio_queue.empty():
            try:
                chunk = self.audio_queue.get(timeout=0.2)
            except queue.Empty:
                if not self._running:
                    break
                continue
            try:
                audio = np.asarray(chunk, dtype=np.float32)
                if audio.ndim == 2:
                    audio = audio.mean(axis=1)
                audio = audio.reshape(-1)
                if audio.size:
                    buffered_chunks.append(audio)
                    buffered_samples += audio.size
            finally:
                self.audio_queue.task_done()

            if buffered_samples >= minimum_samples:
                self._transcribe_buffer(buffered_chunks)
                buffered_chunks = []
                buffered_samples = 0

        if buffered_chunks:
            self._transcribe_buffer(buffered_chunks)

    def _transcribe_buffer(self, chunks: List[np.ndarray]) -> None:
        text = self.service.transcribe_chunk(np.concatenate(chunks))
        if self.service.model_error:
            self.last_error = self.service.model_error
        if text and text.strip():
            self.callback(text.strip())

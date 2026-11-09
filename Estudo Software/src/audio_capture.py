from __future__ import annotations

import queue
import threading
from dataclasses import dataclass
from typing import Optional

import numpy as np

try:
    import soundcard as sc
except ImportError:  # pragma: no cover
    sc = None


@dataclass
class AudioCaptureState:
    sample_rate: int = 16000
    channels: int = 1
    chunk_size: int = 2048
    loopback_device: Optional[str] = None


class AudioLoopbackCapture:
    def __init__(self, sample_rate: int = 16000, channels: int = 1, chunk_size: int = 2048):
        self.state = AudioCaptureState(sample_rate=sample_rate, channels=channels, chunk_size=chunk_size)
        self.audio_queue: "queue.Queue[np.ndarray]" = queue.Queue()
        self._stop_event = threading.Event()
        self._capture_thread: Optional[threading.Thread] = None
        self.last_error: Optional[str] = None

    def start(self) -> None:
        if self._capture_thread and self._capture_thread.is_alive():
            return
        self._stop_event.clear()
        self.last_error = None
        self._capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._capture_thread.start()

    def stop(self) -> None:
        self._stop_event.set()
        if self._capture_thread and self._capture_thread.is_alive():
            self._capture_thread.join(timeout=2)

    def drain(self):
        while not self.audio_queue.empty():
            yield self.audio_queue.get()

    def _capture_loop(self) -> None:
        if sc is None:
            self.last_error = "soundcard não está instalado; não é possível capturar o áudio do vídeo."
            return

        try:
            device = self._select_loopback_device()
            if device is None:
                self.last_error = "Nenhum dispositivo de loopback de áudio foi encontrado."
                return

            recorder = device.recorder(
                samplerate=self.state.sample_rate,
                channels=self.state.channels,
                blocksize=self.state.chunk_size,
            )
            with recorder:
                while not self._stop_event.is_set():
                    audio_chunk = recorder.record(self.state.chunk_size)
                    if audio_chunk is not None and audio_chunk.size:
                        self.audio_queue.put(audio_chunk.astype(np.float32, copy=False))
        except Exception as exc:
            self.last_error = f"Falha ao capturar o áudio do vídeo: {exc}"

    def _select_loopback_device(self):
        if sc is None:
            return None

        speaker = sc.default_speaker()
        device = sc.get_microphone(id=str(speaker.name), include_loopback=True)
        if not device.isloopback:
            raise RuntimeError(f"O dispositivo de saída '{speaker.name}' não oferece loopback.")
        self.state.loopback_device = str(device.name)
        return device

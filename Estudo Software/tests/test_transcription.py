import queue
import unittest
from unittest.mock import MagicMock, patch

import numpy as np

from src.audio_capture import AudioLoopbackCapture
from src.transcription import TranscriptionService, TranscriptionWorker


class TranscriptionServiceTests(unittest.TestCase):
    def test_converts_stereo_audio_to_mono_before_transcribing(self):
        segment = MagicMock()
        segment.text = " fala reconhecida "
        model = MagicMock()
        model.transcribe.return_value = ([segment], None)
        service = TranscriptionService.__new__(TranscriptionService)
        service.model = model
        service.model_error = None

        audio = np.column_stack((np.ones(80000), np.zeros(80000))).astype(np.float32)
        result = service.transcribe_chunk(audio)

        self.assertEqual(result, "fala reconhecida")
        model.transcribe.assert_called_once()
        transcribed_audio = model.transcribe.call_args.args[0]
        self.assertEqual(transcribed_audio.ndim, 1)
        np.testing.assert_allclose(transcribed_audio, 0.5)
        self.assertEqual(model.transcribe.call_args.kwargs["language"], "pt")

    def test_failed_or_silent_audio_never_creates_placeholder_text(self):
        service = TranscriptionService.__new__(TranscriptionService)
        service.model = None
        service.model_error = "modelo indisponível"

        self.assertEqual(service.transcribe_chunk(np.ones(80000, dtype=np.float32)), "")
        self.assertEqual(service.transcribe_chunk(np.array([], dtype=np.float32)), "")

    def test_worker_batches_short_stereo_frames_and_flushes_on_stop(self):
        audio_queue = queue.Queue()
        frame = np.ones((4, 2), dtype=np.float32)
        audio_queue.put(frame)
        audio_queue.put(frame * 3)
        callback = MagicMock()
        worker = TranscriptionWorker(audio_queue, callback, sample_rate=4, chunk_seconds=2)
        fake_service = MagicMock()
        fake_service.model = object()
        fake_service.model_error = None
        fake_service.transcribe_chunk.return_value = "fala reconhecida"
        worker.service = fake_service

        self.assertTrue(worker.start())
        worker.stop()

        callback.assert_called_once_with("fala reconhecida")
        transcribed_audio = fake_service.transcribe_chunk.call_args.args[0]
        self.assertEqual(transcribed_audio.shape, (8,))
        np.testing.assert_allclose(transcribed_audio[:4], 1)
        np.testing.assert_allclose(transcribed_audio[4:], 3)


class AudioLoopbackCaptureTests(unittest.TestCase):
    def test_selects_loopback_for_default_speaker(self):
        speaker = MagicMock()
        speaker.name = "Speakers"
        microphone = MagicMock()
        microphone.name = "Speakers Loopback"
        microphone.isloopback = True
        capture = AudioLoopbackCapture()

        with patch("src.audio_capture.sc.default_speaker", return_value=speaker), patch(
            "src.audio_capture.sc.get_microphone", return_value=microphone
        ) as get_microphone:
            selected = capture._select_loopback_device()

        self.assertIs(selected, microphone)
        self.assertEqual(capture.state.loopback_device, "Speakers Loopback")
        get_microphone.assert_called_once_with(id="Speakers", include_loopback=True)


if __name__ == "__main__":
    unittest.main()

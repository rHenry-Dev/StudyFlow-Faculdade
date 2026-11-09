from __future__ import annotations

import logging
import threading
from datetime import datetime
from typing import List

from PySide6.QtCore import QTimer, Signal
from PySide6.QtWidgets import (
    QApplication,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QTextEdit,
    QVBoxLayout,
    QWidget,
    QPushButton,
)

from src.ai_analysis import AulaMindAnalyzer
from src.audio_capture import AudioLoopbackCapture
from src.context_manager import ContextManager
from src.recommendation_engine import RecommendationEngine
from src.storage import TranscriptStorage
from src.transcription import TranscriptionWorker


class AulaMindWindow(QMainWindow):
    transcript_chunk_received = Signal(str)
    analysis_completed = Signal(object, str)

    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("AulaMind")
        self.resize(1200, 800)

        self.capture = AudioLoopbackCapture()
        self.context = ContextManager()
        self.recommendation_engine = RecommendationEngine()
        self.storage = TranscriptStorage("transcripts")
        self.ai = AulaMindAnalyzer()
        self.transcription_worker = TranscriptionWorker(
            self.capture.audio_queue,
            self._queue_transcript_chunk,
            sample_rate=self.capture.state.sample_rate,
        )
        self._analysis_running = False
        self._analysis_dirty = False

        self._build_ui()
        self.transcript_chunk_received.connect(self._handle_transcript_chunk)
        self.analysis_completed.connect(self._display_analysis)
        self._current_text: List[str] = []
        self._analysis_timer = QTimer(self)
        self._analysis_timer.setSingleShot(True)
        self._analysis_timer.setInterval(30_000)
        self._analysis_timer.timeout.connect(self._analyze_current_context)
        self._poll_timer = QTimer(self)
        self._poll_timer.timeout.connect(self._update_status)
        self._poll_timer.start(500)

    def _build_ui(self) -> None:
        root = QWidget(self)
        self.setCentralWidget(root)

        main_layout = QVBoxLayout(root)
        header = QHBoxLayout()
        self.title_label = QLabel("AulaMind")
        self.title_label.setStyleSheet("font-size: 24px; font-weight: 600; color: #8ab4ff;")
        header.addWidget(self.title_label)

        self.status_capture = QLabel("Status: parado")
        self.status_whisper = QLabel("Whisper: aguardando")
        self.status_ai = QLabel(f"IA: Ollama local ({self.ai.model})")
        header.addWidget(self.status_capture)
        header.addWidget(self.status_whisper)
        header.addWidget(self.status_ai)
        main_layout.addLayout(header)

        body = QHBoxLayout()
        left = QVBoxLayout()
        self.transcript_view = QTextEdit()
        self.transcript_view.setReadOnly(True)
        self.transcript_view.setPlaceholderText("A transcrição aparecerá aqui em tempo real...")
        left.addWidget(self.transcript_view)
        body.addLayout(left, 2)

        right = QVBoxLayout()
        self.analysis_view = QTextEdit()
        self.analysis_view.setReadOnly(True)
        right.addWidget(QLabel("Análise inteligente"))
        right.addWidget(self.analysis_view)

        self.recommendation_view = QTextEdit()
        self.recommendation_view.setReadOnly(True)
        right.addWidget(QLabel("Recomendações"))
        right.addWidget(self.recommendation_view)
        body.addLayout(right, 1)
        main_layout.addLayout(body)

        controls = QHBoxLayout()
        self.start_button = QPushButton("Iniciar aula")
        self.pause_button = QPushButton("Pausar")
        self.stop_button = QPushButton("Encerrar aula")
        self.save_button = QPushButton("Salvar transcrição")
        self.clear_button = QPushButton("Limpar visualização")
        for button in (self.start_button, self.pause_button, self.stop_button, self.save_button, self.clear_button):
            controls.addWidget(button)

        self.start_button.clicked.connect(self.start_capture)
        self.pause_button.clicked.connect(self.pause_capture)
        self.stop_button.clicked.connect(self.stop_capture)
        self.save_button.clicked.connect(self.save_transcription)
        self.clear_button.clicked.connect(self.clear_view)
        main_layout.addLayout(controls)

    def start_capture(self) -> None:
        if not self.transcription_worker.start():
            self.status_whisper.setText(f"Whisper: erro — {self.transcription_worker.last_error}")
            self.status_capture.setText("Status: não iniciado")
            return
        self.capture.start()
        self.status_capture.setText("Status: capturando áudio do vídeo")
        self.status_whisper.setText("Whisper: aguardando fala (blocos de 5 s)")

    def pause_capture(self) -> None:
        self.capture.stop()
        self.transcription_worker.stop()
        self.status_capture.setText("Status: pausado")
        self.status_whisper.setText("Whisper: pausado")

    def stop_capture(self) -> None:
        self.pause_capture()
        self.status_capture.setText("Status: encerrado")
        self.status_whisper.setText("Whisper: finalizado")

    def clear_view(self) -> None:
        self.transcript_view.clear()
        self.analysis_view.clear()
        self.recommendation_view.clear()
        self._current_text.clear()

    def save_transcription(self) -> None:
        content = "\n".join(self._current_text)
        if not content.strip():
            self.status_ai.setText("IA: nenhuma fala reconhecida para salvar")
            return
        path = self.storage.save_transcript(content)
        self.status_ai.setText(f"IA: transcrição salva em {path.resolve()}")

    def _handle_transcript_chunk(self, text: str) -> None:
        if not text or not text.strip():
            return
        timestamp = datetime.now().strftime("%H:%M:%S")
        normalized = text.strip()
        self._current_text.append(f"[{timestamp}] {normalized}")
        self.transcript_view.append(f"[{timestamp}] {normalized}")
        self.transcript_view.verticalScrollBar().setValue(self.transcript_view.verticalScrollBar().maximum())

        context = self.context.update(normalized)
        recommendations = self.recommendation_engine.analyze(context)

        if self._analysis_running:
            self._analysis_dirty = True
        elif not self._analysis_timer.isActive():
            self._analysis_timer.start()

        rec_lines: List[str] = []
        for item in recommendations:
            rec_lines.extend([
                f"{item['acao']} — {item['prioridade']}",
                f"Justificativa: {item['justificativa']}",
                f"Ação: {item['dica']}",
                "",
            ])
        self.recommendation_view.setPlainText("\n".join(rec_lines).strip())
        self.status_ai.setText("IA: análise agendada (intervalos de 30 s)")

    def _queue_transcript_chunk(self, text: str) -> None:
        self.transcript_chunk_received.emit(text)

    def _analyze_current_context(self) -> None:
        if self._analysis_running:
            self._analysis_dirty = True
            return
        context = self.context.current_context()
        if not context:
            return

        self._analysis_running = True
        self._analysis_dirty = False
        self.status_ai.setText(f"IA: consultando Ollama ({self.ai.model})...")
        threading.Thread(target=self._analyze_in_background, args=(context,), daemon=True).start()

    def _analyze_in_background(self, context: str) -> None:
        try:
            analysis = self.ai.analyze(context)
            status = f"IA: {self.ai.last_status}"
        except (OSError, ValueError, TypeError, KeyError, IndexError) as exc:
            logging.exception("Falha inesperada na análise do AulaMind")
            analysis = {}
            status = f"IA: erro inesperado na análise ({exc})"
        self.analysis_completed.emit(analysis, status)

    def _display_analysis(self, analysis: object, status: str) -> None:
        self._analysis_running = False
        if not isinstance(analysis, dict):
            self.status_ai.setText("IA: resposta inválida do serviço de análise")
            return
        analysis_lines = [
            f"Memorizar: {', '.join(analysis.get('memorizar', []) or ['Sem destaque.'])}",
            f"Compreender: {', '.join(analysis.get('compreender', []) or ['Sem destaque.'])}",
            f"Anotar: {', '.join(analysis.get('anotar', []) or ['Sem destaque.'])}",
            f"Questões de prova: {', '.join(analysis.get('prova', []) or ['Sem destaque.'])}",
            f"Prioridade: {', '.join(analysis.get('prioridade', []) or ['Sem destaque.'])}",
        ]
        self.analysis_view.setPlainText("\n".join(analysis_lines))
        self.status_ai.setText(status)
        if self._analysis_dirty and not self._analysis_timer.isActive():
            self._analysis_timer.start()

    def _update_status(self) -> None:
        if self.capture.last_error:
            self.status_capture.setText(f"Status: erro — {self.capture.last_error}")
        if self.transcription_worker.last_error:
            self.status_whisper.setText(f"Whisper: erro — {self.transcription_worker.last_error}")
            return
        if self.capture.last_error:
            self.status_whisper.setText("Whisper: sem áudio de loopback")
            return
        if self.capture.audio_queue.empty():
            if self.transcription_worker._running:
                self.status_whisper.setText("Whisper: aguardando áudio")
        else:
            self.status_whisper.setText("Whisper: processando áudio")


if __name__ == "__main__":
    app = QApplication([])
    window = AulaMindWindow()
    window.show()
    app.exec()

import json
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

from src.ai_analysis import AulaMindAnalyzer


class AulaMindAnalyzerTests(unittest.TestCase):
    def test_sends_transcript_to_local_ollama_and_parses_analysis(self):
        expected = {
            "memorizar": ["Conceito"],
            "compreender": [],
            "anotar": [],
            "prova": [],
            "prioridade": [],
        }
        response = MagicMock()
        response.__enter__.return_value.read.return_value = json.dumps(
            {"response": json.dumps(expected)}
        ).encode("utf-8")
        analyzer = AulaMindAnalyzer()

        with patch("urllib.request.urlopen", return_value=response) as urlopen:
            result = analyzer.analyze("Transcrição da aula")

        request = urlopen.call_args.args[0]
        self.assertEqual(request.full_url, "http://localhost:11434/api/generate")
        payload = json.loads(request.data.decode("utf-8"))
        self.assertEqual(payload["model"], "llama3.2")
        self.assertEqual(payload["format"], "json")
        self.assertIn("Transcrição da aula", payload["prompt"])
        self.assertEqual(result, expected)
        self.assertEqual(analyzer.last_status, "Ollama local (llama3.2)")

    def test_reports_server_not_running_and_uses_basic_fallback(self):
        analyzer = AulaMindAnalyzer()
        with patch("urllib.request.urlopen", side_effect=URLError("connection refused")):
            result = analyzer.analyze("conceito importante")

        self.assertEqual(result["memorizar"], ["Definições e conceitos fundamentais do tema."])
        self.assertIn("inicie o Ollama", analyzer.last_status)
        self.assertIn("análise básica", analyzer.last_status)

    def test_reports_missing_model_and_uses_basic_fallback(self):
        analyzer = AulaMindAnalyzer()
        error = HTTPError("http://localhost:11434/api/generate", 404, "Not Found", {}, None)
        with patch("urllib.request.urlopen", side_effect=error):
            result = analyzer.analyze("exemplo")

        self.assertEqual(result["compreender"], ["Relacionar a teoria com exemplos e aplicações práticas."])
        self.assertIn("modelo 'llama3.2' não encontrado", analyzer.last_status)


if __name__ == "__main__":
    unittest.main()

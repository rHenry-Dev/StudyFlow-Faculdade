from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any, Dict, Tuple


ANALYSIS_KEYS = ("memorizar", "compreender", "anotar", "prova", "prioridade")


def _validated_analysis(value: Any) -> Dict[str, Any]:
    if not isinstance(value, dict) or not any(key in value for key in ANALYSIS_KEYS):
        return {}
    return {
        key: [item.strip() for item in value.get(key, []) if isinstance(item, str) and item.strip()]
        if isinstance(value.get(key, []), list)
        else []
        for key in ANALYSIS_KEYS
    }


class AulaMindAnalyzer:
    def __init__(
        self,
        endpoint: str | None = None,
        model: str | None = None,
        timeout: int = 120,
    ) -> None:
        self.endpoint = endpoint or os.getenv(
            "AULAMIND_OLLAMA_URL",
            "http://localhost:11434/api/generate",
        )
        self.model = model or os.getenv("AULAMIND_OLLAMA_MODEL", "llama3.2")
        self.timeout = timeout
        self.last_status = ""

    def analyze(self, transcript_text: str) -> Dict[str, Any]:
        if not transcript_text.strip():
            return self._fallback_analysis(transcript_text)

        prompt = (
            "Analise a transcrição de uma aula em português brasileiro. "
            "Responda somente com um objeto JSON contendo as chaves memorizar, compreender, "
            "anotar, prova e prioridade; cada valor deve ser uma lista de strings em português. "
            "Não invente conteúdo nem atribua ao professor algo que não esteja na transcrição.\n"
            f"Transcrição:\n{transcript_text[:3500]}"
        )

        result, error = self._call_ollama(prompt)
        if result:
            self.last_status = f"Ollama local ({self.model})"
            return result

        self.last_status = f"Ollama indisponível ({error}); usando análise básica"
        return self._fallback_analysis(transcript_text)

    def _call_ollama(self, prompt: str) -> Tuple[Dict[str, Any], str]:
        payload = {
            "model": self.model,
            "prompt": prompt,
            "format": "json",
            "stream": False,
            "options": {"temperature": 0.2, "num_predict": 400},
        }
        request = urllib.request.Request(
            self.endpoint,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                parsed = json.loads(response.read().decode("utf-8"))
            result = _validated_analysis(json.loads(parsed.get("response", "")))
            if result:
                return result, ""
            return {}, "resposta fora do formato esperado"
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return {}, f"modelo '{self.model}' não encontrado; baixe-o com ollama pull {self.model}"
            return {}, f"erro HTTP {exc.code}"
        except urllib.error.URLError as exc:
            reason = getattr(exc, "reason", None)
            if isinstance(reason, TimeoutError):
                return {}, "tempo limite ao conectar ao servidor"
            return {}, "servidor não encontrado; inicie o Ollama com ollama serve"
        except TimeoutError:
            return {}, "tempo limite; o modelo pode estar carregando ou gerando resposta"
        except (json.JSONDecodeError, KeyError, TypeError, ValueError):
            return {}, "resposta inválida do Ollama"

    @staticmethod
    def _fallback_analysis(transcript_text: str) -> Dict[str, Any]:
        lowered = transcript_text.lower()
        items = {
            "memorizar": [],
            "compreender": [],
            "anotar": [],
            "prova": [],
            "prioridade": [],
        }
        if "definição" in lowered or "conceito" in lowered:
            items["memorizar"].append("Definições e conceitos fundamentais do tema.")
        if "exemplo" in lowered or "aplicação" in lowered:
            items["compreender"].append("Relacionar a teoria com exemplos e aplicações práticas.")
        if "importante" in lowered or "destaque" in lowered:
            items["anotar"].append("Registrar os destaques mencionados em sala.")
        if "exercício" in lowered or "questão" in lowered or "prova" in lowered:
            items["prova"].append("Possíveis tópicos de avaliação com base no conteúdo explicado.")
        if not any(items.values()):
            items["prioridade"].append("Conteúdo complementar e sem foco de avaliação claro.")
        else:
            items["prioridade"].append("ALTA: conceitos fundamentais; MÉDIA: exemplos e aplicações; BAIXA: complementos.")
        return items

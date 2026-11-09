from __future__ import annotations

from typing import Dict, List


class RecommendationEngine:
    def __init__(self) -> None:
        self.keyword_map = {
            "memorizar": ["definição", "conceito", "regra", "teorema", "fórmula", "datas", "classificação"],
            "compreender": ["explicação", "exemplo", "aplicação", "relação", "comparação", "diferença"],
            "anotar": ["importante", "destaque", "observação", "resumo", "notação"],
            "revisar": ["exceção", "detalhe", "equívoco", "erro", "repetição"],
            "praticar": ["exercício", "questão", "problema", "aplicação prática"],
            "complementar": ["comentário", "complemento", "contexto", "referência", "opcional"],
        }

    def analyze(self, text: str) -> List[Dict[str, str]]:
        cleaned = text.lower()
        recommendations: List[Dict[str, str]] = []
        for action, keywords in self.keyword_map.items():
            if any(keyword in cleaned for keyword in keywords):
                recommendations.append({
                    "acao": action.upper(),
                    "prioridade": self._priority_for(action),
                    "justificativa": self._justification_for(action),
                    "dica": self._action_hint(action),
                })

        if not recommendations:
            recommendations.append({
                "acao": "COMPLEMENTAR",
                "prioridade": "BAIXA",
                "justificativa": "Trecho de apoio ou contextualização sem foco direto na avaliação.",
                "dica": "Registrar apenas como contexto de estudo.",
            })

        return recommendations[:4]

    @staticmethod
    def _priority_for(action: str) -> str:
        mapping = {
            "memorizar": "ALTA",
            "compreender": "ALTA",
            "anotar": "MÉDIA",
            "revisar": "MÉDIA",
            "praticar": "ALTA",
            "complementar": "BAIXA",
        }
        return mapping.get(action, "MÉDIA")

    @staticmethod
    def _justification_for(action: str) -> str:
        mapping = {
            "memorizar": "É um conteúdo-base que sustenta a compreensão do tema.",
            "compreender": "Requer estabelecer relações conceituais e aplicação prática.",
            "anotar": "Vale ser registrado para evitar perda de detalhes relevantes.",
            "revisar": "Esse ponto pode exigir releitura por ser mais técnico ou complexo.",
            "praticar": "A melhor consolidação ocorre com exercícios ou questionamentos.",
            "complementar": "Informação útil, mas não central para a memorização imediata.",
        }
        return mapping.get(action, "Conteúdo útil para contextualizar o estudo.")

    @staticmethod
    def _action_hint(action: str) -> str:
        mapping = {
            "memorizar": "Registrar a definição e revisá-la em sequência.",
            "compreender": "Relacionar o conceito com exemplos e aplicações.",
            "anotar": "Adicionar ao material principal com linguagem objetiva.",
            "revisar": "Repetir o tema em pequenos blocos de revisão.",
            "praticar": "Resolver exercícios e formular perguntas sobre o tema.",
            "complementar": "Guardar como apoio sem sobrecarregar as anotações principais.",
        }
        return mapping.get(action, "Guardar como contexto de estudo.")

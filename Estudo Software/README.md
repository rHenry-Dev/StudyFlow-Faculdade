# AulaMind

AulaMind é um assistente local para apoiar o estudo de videoaulas em Windows 11. A captura, a transcrição e a análise pedagógica são feitas localmente com Faster-Whisper e Ollama.

## Estrutura

- `main.py`: ponto de entrada da aplicação.
- `config.json`: parâmetros do projeto.
- `src/audio_capture.py`: captura do áudio reproduzido pelo computador.
- `src/transcription.py`: integração com Faster-Whisper.
- `src/ai_analysis.py`: integração com a API local do Ollama e análise básica de fallback.
- `src/context_manager.py`: janela de contexto e memória da aula.
- `src/recommendation_engine.py`: geração de recomendações didáticas.
- `src/storage.py`: salvamento de transcrições e relatórios.
- `src/interface.py`: interface gráfica em PySide6.

## Requisitos

- Windows 11
- Python 3.11+
- PySide6
- soundcard
- faster-whisper
- Ollama instalado e em execução
- Modelo local do Ollama baixado (por exemplo, `llama3.2`)

## Instalação

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Execução

```powershell
ollama pull llama3.2
ollama serve
```

Em outro terminal, inicie o aplicativo:

```powershell
.\.venv\Scripts\python.exe main.py
```

## Observações

- O AulaMind acessa a API local em `http://localhost:11434/api/generate`. Configure `AULAMIND_OLLAMA_URL` ou `AULAMIND_OLLAMA_MODEL` se usar outro endpoint ou modelo.
- A análise ocorre localmente e não envia a transcrição a serviços externos. Se o servidor ou modelo não estiver disponível, o app informa o motivo e usa a análise básica.
- O AulaMind agenda análises em intervalos de 30 segundos, em vez de fazer uma chamada a cada fragmento transcrito.
- A captura de áudio em Windows é feita com `soundcard` e WAVE/loopback quando o dispositivo correspondente estiver disponível.
- Se não houver dispositivo de loopback ou ocorrer falha de captura, o aplicativo mostra o erro; ele não inventa texto nem substitui o áudio por um tom sintético.
- O áudio capturado é convertido em blocos de cinco segundos antes de ser enviado ao Whisper para reconhecimento da fala em português.
- A análise pedagógica evita atribuir conclusões ao professor sem base na transcrição.

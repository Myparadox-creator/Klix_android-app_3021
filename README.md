# KLIX - AI Coding Assistant & Ecosystem

> A powerful, multi-platform AI coding assistant with Flutter frontend, FastAPI backend, and memory-augmented intelligence. Combining cloud AI (Gemini, Groq), local models (Ollama), and persistent [...]

![Python](https://img.shields.io/badge/Python-3.11+-blue?style=flat-square&logo=python)
![Dart](https://img.shields.io/badge/Dart-3.1+-blue?style=flat-square&logo=dart)
![FastAPI](https://img.shields.io/badge/FastAPI-0.113+-green?style=flat-square&logo=fastapi)
![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat-square&logo=flutter)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 📊 Project Overview

**KLIX** is a comprehensive AI development ecosystem featuring:
- **AI-Powered Code Generation** - Intelligent coding assistance with memory
- **Multi-Platform Support** - Web, mobile, TUI interfaces
- **Hybrid AI Backend** - Cloud + Local model capabilities
- **Persistent Memory** - Long-term context across sessions
- **Real-time Communication** - WebSocket-based interactions

### Technology Stack

| Layer | Technology | Usage |
|-------|-----------|-------|
| **Frontend** | Flutter 3.10+, Dart 3.1+ | Web & Mobile UI |
| **Backend** | FastAPI 0.113+, Python 3.11+ | REST API, WebSocket server |
| **AI Models** | Gemini, Groq, Ollama | LLM inference |
| **Memory** | Mem0, Qdrant | Vector embeddings & storage |
| **TTS** | Microsoft Edge Neural | Voice synthesis |
| **Build** | CMake, C++ | Native modules |
| **Styling** | CSS | Web UI styling |

**Language Composition:**
- Python: 71.1% (Backend, AI logic)
- Dart: 12.4% (Flutter frontend)
- TypeScript: 8.7% (Web utilities)
- CSS: 2.6% (Styling)
- CMake: 2.3% (Build system)
- C++: 1.5% (Performance-critical components)
- Other: 1.4%

---

## 🏗️ Project Structure

```
Klix_android-app_3021/
├── README.md                          # This file
├── flutter_app/                       # Flutter Web Application
│   ├── lib/                          # Dart source code
│   ├── web/                          # Web assets
│   └── pubspec.yaml                  # Flutter dependencies
│
├── New_30_T-Klix-main/               # Main Backend Project
│   ├── main.py                       # TUI Agent entry point
│   ├── backend_api.py                # FastAPI server
│   ├── llm_client.py                 # LLM adapters (Gemini/Ollama)
│   ├── tui.py                        # Terminal UI (rich library)
│   ├── tools.py                      # Tool registry & implementations
│   ├── config.py                     # Configuration
│   ├── requirements.txt              # Python dependencies
│   │
│   ├── Nemo/                         # AI Companion Backend
│   │   ├── server.py                # FastAPI + WebSocket server
│   │   ├── core/
│   │   │   ├── memory.py           # Mem0 Memory Service
│   │   │   ├── llm.py              # Groq LLM Client
│   │   │   └── tts.py              # Edge-TTS Wrapper
│   │   ├── .env.example
│   │   └── requirements.txt
│   │
│   └── Nova/                         # Advanced Platform
│       ├── backend/                 # Python backend
│       ├── frontend/                # Web interface
│       └── README.md
```

---

## ⚙️ Core Components

### 1. **Main TUI Agent** (`New_30_T-Klix-main/main.py`)
A sophisticated terminal-based AI agent with Claude Code interface replication.

**Features:**
- 🎨 Beautiful dark mode TUI with Tangerine Orange accents
- 🧠 Hybrid AI (Gemini + Ollama support)
- 🧠 Persistent memory with Mem0
- 🔧 Built-in tools (file ops, shell, web search, OSINT)
- 💬 Slash commands for control
- 📝 Markdown syntax highlighting
- 🔄 Real-time streaming responses

**Slash Commands:**
```
/init [path]      - Initialize project context
/config           - View/change configuration
/model [name]     - Switch models (gemini/ollama)
/clear            - Clear conversation context
/tools            - Show available tools
/status           - Show current status
/memory           - View and search memories
/forget           - Delete memory/memories
/remember         - Add manual memory
/help             - Show all commands
/quit, /exit      - Exit application
```

**Available Tools:**
- `ls`, `read_file`, `write_file`, `append_file`, `delete_file`
- `run_command` - Execute shell commands
- `web_search` - Internet search
- `get_project_structure` - View project tree
- `dns_lookup`, `whois_lookup`, `port_scan` - OSINT suite
- `http_headers` - Analyze HTTP headers

### 2. **FastAPI Backend** (`New_30_T-Klix-main/backend_api.py`)
REST API server connecting Flutter frontend with AI capabilities.

**Key Features:**
- Dynamic backend URL detection (platform-aware)
- Real-time AI chat responses
- Vector database integration (Qdrant)
- Memory persistence layer

### 3. **Nemo - AI Companion** (`New_30_T-Klix-main/Nemo/`)
Low-latency voice AI companion with real-time streaming.

**Specifications:**
- **Speed:** ~400-800ms total response latency
  - Groq LLM: 200-400ms
  - Memory Search: 50-100ms
  - TTS: 100-300ms
- **LLM:** Groq llama-3.3-70b (ultra-fast inference)
- **Memory:** Mem0-powered personalization
- **Voice:** Microsoft Edge neural TTS (free, high-quality)
- **Protocol:** WebSocket + REST API

**API Endpoints:**
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API info |
| `/health` | GET | Service health |
| `/chat` | POST | Chat with audio response |
| `/talk` | WebSocket | Real-time voice conversation |
| `/voices` | GET | Available voices |
| `/memory` | POST/DELETE | Manage memories |

**Available Voices:**
- `shanaya_default` - en-IN-NeerjaNeural (warm Indian)
- `shanaya_expressive` - en-IN-NeerjaExpressiveNeural (emotional)
- `aria` - en-US-AriaNeural (US English)
- `sonia` - en-GB-SoniaNeural (British)

### 4. **Flutter Web Frontend**
Modern, high-performance web application with Material 3 design.

**UI Features:**
- Sleek "tech" aesthetic with custom animations
- Responsive Material 3 components
- Real-time chat interface
- Platform-aware backend detection
- Dynamic UI state management

### 5. **Nova Platform** (`New_30_T-Klix-main/Nova/`)
High-performance, modular platform for scale.

**Architecture:**
- **Backend:** Python with structured data models
- **Frontend:** Modern web interface with performance focus
- **Design:** Modular and extensible

---

## 🚀 Quick Start Guide

### Prerequisites
- Python 3.11+ (backend)
- Dart 3.1+ (Flutter)
- Flutter SDK 3.10+
- Node.js (optional, for web tools)

### 1. Backend Setup

#### TUI Agent
```bash
cd New_30_T-Klix-main
pip install -r requirements.txt
cp .env .env.local  # Configure your API keys
python main.py
```

#### FastAPI Server
```bash
cd New_30_T-Klix-main
pip install -r requirements.txt
python -m uvicorn backend_api:app --reload --host 0.0.0.0 --port 8000
```

#### Nemo Backend (Voice AI)
```bash
cd New_30_T-Klix-main/Nemo
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
cp .env.example .env
# Edit .env with API keys (GROQ_API_KEY, MEM0_API_KEY)
python server.py
# or: uvicorn server:app --reload --host 0.0.0.0 --port 8000
```

### 2. Frontend Setup

```bash
# Web application
flutter run -d chrome

# Build for production
flutter build web
```

### 3. Configuration

Create `.env` file with:
```bash
# AI Models
GOOGLE_API_KEY=your_google_api_key
GROQ_API_KEY=your_groq_api_key
MEM0_API_KEY=your_mem0_api_key
OLLAMA_HOST=http://localhost:11434

# Models
DEFAULT_MODEL=gemini-1.5-flash
GEMINI_MODEL=gemini-1.5-flash
OLLAMA_MODEL=qwen2.5-coder

# Memory
MEMORY_ENABLED=true

# Display
USER_NAME=YourName
ORG_NAME=YourOrg

# Nemo specific
TTS_VOICE=en-IN-NeerjaExpressiveNeural
PORT=8000
```

---

## 🔧 Architecture Deep Dive

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter Web UI                        │
│          (Material 3, Custom Animations)                │
└────────────────────┬────────────────────────────────────┘
                     │ (HTTP/WebSocket)
┌────────────────────▼────────────────────────────────────┐
│              FastAPI Gateway                            │
│         (backend_api.py + Nemo server.py)               │
└────────────────┬──────────────────┬──────────────────────┘
                 │                  │
        ┌────────▼────┐      ┌──────▼──────────┐
        │ TUI Agent   │      │ Voice Companion │
        │ (main.py)   │      │   (Nemo)        │
        └────────┬────┘      └──────┬──────────┘
                 │                  │
    ┌────────────┴──────────────────┼──────────────┐
    │                               │              │
┌───▼──────┐      ┌────────────┐    │    ┌────────▼──────┐
│  Gemini  │      │  Ollama    │    │    │ Groq LLM      │
│  (Cloud) │      │  (Local)   │    │    │ (Ultra-fast)  │
└──────────┘      └────────────┘    │    └───────────────┘
                                   │
                    ┌──────────────┴───────────────┐
                    │                              │
            ┌───────▼─────┐            ┌──────────▼─────┐
            │   Mem0      │            │ Microsoft Edge  │
            │   Memory    │            │ TTS (Free)      │
            │  (Qdrant)   │            │ (Voice Synth)   │
            └─────────────┘            └─────────────────┘
```

### Memory Flow

```
User Input
    ↓
Memory Search (Mem0 + Qdrant)
    ↓
Context Injection (System Prompt Enhancement)
    ↓
LLM Processing (Gemini/Groq/Ollama)
    ↓
Response Generation + TTS
    ↓
Background Memory Save (Async)
```

---

## 📡 API Examples

### Chat API (REST)
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Write a Python function to sort an array",
    "user_id": "user123"
  }'
```

### WebSocket (Real-time Voice)
```javascript
const ws = new WebSocket('ws://localhost:8000/talk');

ws.onopen = () => console.log('Connected to Nemo');

ws.onmessage = (event) => {
  const { audio, text, visemes } = JSON.parse(event.data);
  console.log('Nemo:', text);
  
  // Play audio response
  const audio_elem = new Audio('data:audio/mp3;base64,' + audio);
  audio_elem.play();
};

// Send message
ws.send(JSON.stringify({ 
  text: "Hey Nemo, can you help me debug this?",
  user_id: "user123"
}));
```

### Health Check
```bash
curl http://localhost:8000/health
```

---

## 🧠 Memory System

**How It Works:**
1. **Context Retrieval:** Before generating responses, relevant memories are semantically searched
2. **Prompt Enhancement:** Memories injected into system prompt for context-aware responses
3. **Asynchronous Saving:** Conversations saved in background (non-blocking)

**Example:**
```
User: "I'm having trouble with async/await"
    ↓
Mem0 Search: Finds "User prefers explanation through examples"
    ↓
System Prompt: "...MEMORIES: User prefers learning through examples..."
    ↓
AI Response: Provides detailed code examples for async/await
```

---

## 🔐 Security Features

- **Safety Settings:** Gemini safety settings set to `BLOCK_NONE` for maximum developer freedom
- **OSINT Tools:** Secure DNS/WHOIS/port scanning for network reconnaissance
- **HTTP Headers Analysis:** Analyze security headers and SSL/TLS configuration
- **Local-First Option:** Run Ollama locally for complete privacy

---

## 📦 Dependencies Overview

### Backend (Python)
- **FastAPI** - Web framework
- **Uvicorn** - ASGI server
- **google-generativeai** - Gemini API
- **groq** - Groq LLM
- **ollama** - Ollama client
- **mem0ai** - Memory management
- **qdrant-client** - Vector DB
- **rich** - TUI rendering
- **pydantic** - Data validation
- **aiohttp** - Async HTTP
- **pyttsx3, edge-tts** - Text-to-speech

### Frontend (Dart/Flutter)
- **flutter** - UI framework
- **material_3** - Material Design 3
- **http** - HTTP client
- **web_socket_channel** - WebSocket support
- **json_serializable** - JSON serialization

---

## 🎯 Use Cases

1. **AI-Assisted Development**
   - Real-time code generation
   - Bug detection and fixing
   - Code review and optimization

2. **Learning & Documentation**
   - Interactive coding tutorials
   - Context-aware explanations
   - Project structure analysis

3. **Productivity Tools**
   - Voice-based coding (Nemo)
   - Shell command execution
   - Web search integration

4. **Security Research**
   - OSINT capabilities
   - Network reconnaissance
   - HTTP header analysis

---

## 🛠️ Development

### Running in Development Mode

```bash
# Backend with auto-reload
uvicorn backend_api:app --reload --host 0.0.0.0 --port 8000

# TUI Agent
python main.py

# Nemo with hot reload
uvicorn server:app --reload --host 0.0.0.0 --port 8000 (in Nemo directory)
```

### Code Formatting
```bash
# Python
black .
flake8 .

# Dart
dart format .
dart analyze
```

---

## 📝 Configuration Files

- **`.env`** - Environment variables (API keys, model names)
- **`config.py`** - Python configuration (safety settings, defaults)
- **`pubspec.yaml`** - Flutter dependencies
- **`requirements.txt`** - Python dependencies

---

## 🤝 Project Ecosystem

### Integrated Components
- **Klix Code** - Main TUI agent
- **Nemo** - Voice AI companion
- **Nova** - Scalable platform
- **Flutter App** - Multi-platform frontend

---

## 📊 Performance Metrics

| Component | Latency | Notes |
|-----------|---------|-------|
| Groq LLM | 200-400ms | Ultra-fast inference |
| Memory Search | 50-100ms | Semantic vector search |
| TTS Synthesis | 100-300ms | Neural voices |
| **Total Response** | **400-800ms** | End-to-end latency |
| Web UI | <100ms | Modern Flutter rendering |

---

## 🔍 Troubleshooting

### Backend Issues
- Ensure `.env` is properly configured
- Check API keys validity
- Verify Ollama is running (if using local model)
- Check port availability (8000 default)

### Frontend Issues
- Clear Flutter build cache: `flutter clean`
- Ensure Chrome/Chromium is installed for web
- Check backend URL configuration

### Memory Issues
- Verify Mem0 API key
- Check Qdrant server connectivity
- Ensure sufficient storage space

---

## 📚 Documentation Links

- [Google AI Studio](https://aistudio.google.com/)
- [Groq Console](https://console.groq.com/)
- [Mem0 Dashboard](https://app.mem0.ai/)
- [Ollama Documentation](https://ollama.ai/)
- [Flutter Docs](https://flutter.dev/docs)
- [FastAPI Docs](https://fastapi.tiangolo.com/)

---

## 📄 License

MIT License - Open for personal and commercial use

---

## 🤝 Contributing

Contributions welcome! Areas of interest:
- Additional LLM integrations
- Extended OSINT capabilities
- UI/UX improvements
- Performance optimizations
- New voice personas

---

## 👨‍💻 Author

**Myparadox-creator**

Built with ❤️ for developers who need intelligent, context-aware coding assistance.

---

## 🌟 Highlights

✅ Multi-LLM support (Gemini, Groq, Ollama)  
✅ Persistent memory across sessions  
✅ Real-time voice AI companion  
✅ Cross-platform (Web, TUI, Mobile-ready)  
✅ OSINT suite integrated  
✅ 400-800ms response latency  
✅ Free neural TTS  
✅ Local-first privacy option  

---

*"Intelligent coding assistance, personalized for you."*

---

<!-- TEST COMMIT: This is a test update (random commit #7) to validate your repository health capture workflow -->

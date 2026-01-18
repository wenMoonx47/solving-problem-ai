# SolveAssist AI

> **Instant problem-solving guidance for teaching and learning**

SolveAssist AI is an AI-powered problem-solving assistant designed to help teachers and students understand and explain academic problems more effectively. It works **completely offline** after initial setup.

![SolveAssist AI Banner](https://via.placeholder.com/800x200/0c1222/0ea5e9?text=SolveAssist+AI)

## ✨ Features

### 📸 Screen & Image Capture
- **Upload images** of problems from textbooks, worksheets, or PDFs
- **Camera capture** for whiteboards, handwritten notes, or physical textbooks
- **Screen capture** for digital content and online resources
- **Paste from clipboard** (Ctrl+V) for quick problem input
- **Drag & drop** support for easy image upload

### 🤖 AI Solution Guidance
- Step-by-step solving methods with clear explanations
- Explanation of key formulas and concepts
- Multiple solution approaches where applicable
- Configurable "show answer" option for learning-focused guidance

### 📚 Supported Subjects
- **Mathematics**: Algebra, calculus, geometry, trigonometry, statistics
- **Physics**: Mechanics, motion, electricity, thermodynamics, waves
- **Chemistry**: Equations, reactions, stoichiometry, molecular structures
- **Word Problems**: Logical reasoning, applied mathematics

### 👨‍🏫 Teacher-Focused Benefits
- Helps explain complex topics clearly to students
- Saves lesson preparation time
- Supports interactive teaching methods
- Improves student understanding with visual explanations

## 🚀 Quick Start

### Prerequisites

- **Linux** (Ubuntu 20.04+, Fedora, or Arch)
- **Python 3.9+**
- **~10GB disk space** for AI models

### One-Line Setup

```bash
./setup.sh
```

This script will:
1. Create a Python virtual environment
2. Install all Python dependencies
3. Install Tesseract OCR (for text extraction)
4. Install Ollama (local AI runtime)
5. Download required AI models (~7GB)

### Running the Application

```bash
./run.sh
```

Then open **http://localhost:5000** in your browser.

## 📦 Installation (Detailed)

### Step 1: Clone or Download

```bash
cd /path/to/your/workspace
# If you have the project files already, skip this step
```

### Step 2: Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y python3 python3-venv python3-pip tesseract-ocr curl
```

**Fedora:**
```bash
sudo dnf install -y python3 python3-pip tesseract curl
```

**Arch Linux:**
```bash
sudo pacman -S python python-pip tesseract curl
```

### Step 3: Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Step 4: Run Setup

```bash
chmod +x setup.sh run.sh scripts/*.sh
./setup.sh
```

### Step 5: Download Models (for offline use)

While connected to the internet, download the AI models:

```bash
./scripts/download_models.sh
```

Choose your preferred option:
- **Minimal (2GB)**: Text-only reasoning
- **Standard (7GB)**: Recommended - includes vision capabilities
- **Full (15GB)**: Best quality with multiple model options

## 🔌 Offline Operation

After initial setup, SolveAssist AI works **completely offline**:

1. All AI models are stored locally in `~/.ollama/models/`
2. No internet connection required for problem solving
3. All processing happens on your local machine
4. Your data stays private - nothing is sent to external servers

### Verify Offline Readiness

```bash
# Check if models are installed
ollama list

# Expected output:
# NAME            SIZE     MODIFIED
# llava:7b        4.7 GB   ...
# llama3.2:latest 2.0 GB   ...
```

## 🖥️ Usage Guide

### Method 1: Upload Image

1. Click **"Upload Image"** button
2. Select an image containing a problem
3. Click **"Analyze & Solve"**

### Method 2: Camera Capture

1. Click **"Camera"** button
2. Point at the problem (whiteboard, textbook, etc.)
3. Click the capture button
4. Click **"Analyze & Solve"**

### Method 3: Screen Capture

1. Click **"Screen Capture"** button
2. Select the window or area with the problem
3. Click **"Analyze & Solve"**

### Method 4: Type Problem

1. Click **"Type Problem"** button
2. Enter the problem text
3. Click **"Analyze & Solve"**

### Options

- **Subject**: Auto-detect or manually select (Math, Physics, Chemistry, etc.)
- **Show Answer**: Toggle to hide final answers for learning-focused guidance

## 🏗️ Architecture

```
solve-assist-ai/
├── backend/
│   ├── app.py          # Flask API server
│   ├── ocr_engine.py   # Text extraction from images
│   └── solver.py       # AI problem solving engine
├── frontend/
│   ├── index.html      # Main UI
│   ├── styles.css      # Styling
│   └── app.js          # Frontend logic
├── scripts/
│   └── download_models.sh  # Model downloader
├── requirements.txt    # Python dependencies
├── setup.sh           # Setup script
├── run.sh             # Run script
└── README.md          # This file
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Backend | Python 3, Flask |
| Frontend | HTML5, CSS3, JavaScript |
| OCR | Tesseract |
| AI Runtime | Ollama |
| Vision Model | LLaVA 7B |
| Text Model | Llama 3.2 |

## ⚙️ Configuration

### Changing AI Models

Edit `backend/solver.py` to use different models:

```python
class ProblemSolver:
    VISION_MODEL = "llava:7b"      # Vision-language model
    TEXT_MODEL = "llama3.2:latest"  # Text reasoning model
```

Available alternatives:
- `llava:13b` - Higher quality vision (8GB)
- `mistral:latest` - Alternative text model (4GB)
- `codellama:7b` - Better for programming problems (4GB)

### Server Configuration

The server runs on port 5000 by default. To change:

```python
# In backend/app.py
app.run(host='0.0.0.0', port=8080, debug=False)
```

## 🔧 Troubleshooting

### "Ollama not found"

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### "Model not found"

```bash
ollama pull llava:7b
ollama pull llama3.2:latest
```

### "OCR not working"

```bash
# Ubuntu/Debian
sudo apt-get install tesseract-ocr tesseract-ocr-eng

# Verify installation
tesseract --version
```

### "Server not starting"

```bash
# Check if port 5000 is in use
lsof -i :5000

# Kill existing process
kill -9 $(lsof -t -i :5000)
```

### "Slow performance"

- Ensure you have sufficient RAM (8GB+ recommended)
- Use smaller models for faster inference
- Close other memory-intensive applications

## 📊 System Requirements

| Requirement | Minimum | Recommended |
|------------|---------|-------------|
| RAM | 8 GB | 16 GB |
| Storage | 10 GB | 20 GB |
| CPU | 4 cores | 8 cores |
| GPU | Optional | NVIDIA (for acceleration) |

### GPU Acceleration

If you have an NVIDIA GPU, Ollama will automatically use it for faster inference.

```bash
# Check GPU detection
ollama run llama3.2 --verbose
```

## 📝 License

This project is for educational purposes. The AI models (LLaVA, Llama) have their own licenses.

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- [ ] Support for more subjects (biology, history, etc.)
- [ ] Improved handwriting recognition
- [ ] Graph/diagram generation
- [ ] LaTeX math rendering
- [ ] Multiple language support

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Ensure all dependencies are properly installed
3. Verify AI models are downloaded correctly

---

**SolveAssist AI** — *Empowering teachers and students through AI-assisted learning*


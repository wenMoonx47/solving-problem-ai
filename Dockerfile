FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV OLLAMA_HOST=0.0.0.0:11434
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata

RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    curl \
    ca-certificates \
    git \
    tesseract-ocr \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    zstd \
 && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

WORKDIR /app
COPY . /app

# Python dependencies
RUN python3 -m venv /app/venv \
 && /app/venv/bin/pip install --upgrade pip \
 && /app/venv/bin/pip install -r /app/requirements.txt

# Pre-pull models (large; required for offline use)
RUN ollama serve & \
    sleep 5 && \
    OLLAMA_HOST=127.0.0.1:11434 ollama pull llava:7b && \
    OLLAMA_HOST=127.0.0.1:11434 ollama pull llama3.2:latest && \
    pkill ollama

RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 3333 11434

ENTRYPOINT ["/app/docker-entrypoint.sh"]


/**
 * SolveAssist AI - Frontend Application
 * Instant problem-solving guidance for teaching and learning
 */

class SolveAssistAI {
    constructor() {
        this.API_BASE = '';
        this.currentImage = null;
        this.currentMode = 'image'; // 'image' or 'text'
        this.cameraStream = null;
        
        this.initElements();
        this.bindEvents();
        this.checkServerStatus();
    }
    
    initElements() {
        // Status
        this.statusIndicator = document.getElementById('statusIndicator');
        
        // Capture buttons
        this.uploadBtn = document.getElementById('uploadBtn');
        this.cameraBtn = document.getElementById('cameraBtn');
        this.screenBtn = document.getElementById('screenBtn');
        this.textBtn = document.getElementById('textBtn');
        this.fileInput = document.getElementById('fileInput');
        
        // Preview
        this.previewArea = document.getElementById('previewArea');
        this.previewImage = document.getElementById('previewImage');
        
        // Text input
        this.textInputArea = document.getElementById('textInputArea');
        this.problemText = document.getElementById('problemText');
        
        // Camera
        this.cameraModal = document.getElementById('cameraModal');
        this.cameraVideo = document.getElementById('cameraVideo');
        this.cameraCanvas = document.getElementById('cameraCanvas');
        this.cameraCapture = document.getElementById('cameraCapture');
        this.cameraClose = document.getElementById('cameraClose');
        
        // Options
        this.subjectSelect = document.getElementById('subjectSelect');
        this.showAnswerToggle = document.getElementById('showAnswer');
        
        // Solve
        this.solveBtn = document.getElementById('solveBtn');
        
        // Results
        this.resultsSection = document.getElementById('resultsSection');
        this.problemTypeBadge = document.getElementById('problemTypeBadge');
        this.extractedText = document.getElementById('extractedText');
        this.solutionContent = document.getElementById('solutionContent');
        this.copyBtn = document.getElementById('copyBtn');
        this.newProblemBtn = document.getElementById('newProblemBtn');
        
        // Cards
        this.extractedTextCard = document.getElementById('extractedTextCard');
    }
    
    bindEvents() {
        // Capture buttons
        this.uploadBtn.addEventListener('click', () => this.triggerUpload());
        this.cameraBtn.addEventListener('click', () => this.openCamera());
        this.screenBtn.addEventListener('click', () => this.captureScreen());
        this.textBtn.addEventListener('click', () => this.switchToTextMode());
        
        // File input
        this.fileInput.addEventListener('change', (e) => this.handleFileSelect(e));
        
        // Camera controls
        this.cameraCapture.addEventListener('click', () => this.takePicture());
        this.cameraClose.addEventListener('click', () => this.closeCamera());
        
        // Text input
        this.problemText.addEventListener('input', () => this.updateSolveButton());
        
        // Solve button
        this.solveBtn.addEventListener('click', () => this.solve());
        
        // Result actions
        this.copyBtn.addEventListener('click', () => this.copySolution());
        this.newProblemBtn.addEventListener('click', () => this.reset());
        
        // Card toggles
        document.querySelectorAll('.card-toggle').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const card = e.target.closest('.result-card');
                card.classList.toggle('collapsed');
            });
        });
        
        // Drag and drop
        this.previewArea.addEventListener('dragover', (e) => this.handleDragOver(e));
        this.previewArea.addEventListener('drop', (e) => this.handleDrop(e));
        this.previewArea.addEventListener('dragleave', () => this.handleDragLeave());
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey || e.metaKey) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    if (!this.solveBtn.disabled) {
                        this.solve();
                    }
                } else if (e.key === 'v') {
                    // Paste image from clipboard
                    this.handlePaste();
                }
            }
        });
        
        // Paste event
        document.addEventListener('paste', (e) => this.handlePaste(e));
    }
    
    async checkServerStatus() {
        try {
            const response = await fetch(`${this.API_BASE}/api/health`);
            const data = await response.json();
            
            this.statusIndicator.classList.remove('error');
            
            if (data.ai_model.ollama_running && (data.ai_model.vision_model || data.ai_model.text_model)) {
                this.statusIndicator.classList.add('ready');
                this.statusIndicator.querySelector('.status-text').textContent = 'AI Ready';
            } else if (data.ai_model.ollama_running) {
                this.statusIndicator.classList.add('ready');
                this.statusIndicator.querySelector('.status-text').textContent = 'Models Loading...';
            } else {
                this.statusIndicator.querySelector('.status-text').textContent = 'Start Ollama';
            }
        } catch (error) {
            this.statusIndicator.classList.add('error');
            this.statusIndicator.querySelector('.status-text').textContent = 'Server Offline';
        }
    }
    
    triggerUpload() {
        this.switchToImageMode();
        this.fileInput.click();
    }
    
    handleFileSelect(event) {
        const file = event.target.files[0];
        if (file && file.type.startsWith('image/')) {
            this.loadImage(file);
        }
    }
    
    loadImage(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            this.currentImage = e.target.result;
            this.previewImage.src = this.currentImage;
            this.previewArea.classList.add('has-image');
            this.updateSolveButton();
        };
        reader.readAsDataURL(file);
    }
    
    async openCamera() {
        this.switchToImageMode();
        
        try {
            this.cameraStream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment', width: { ideal: 1920 }, height: { ideal: 1080 } }
            });
            
            this.cameraVideo.srcObject = this.cameraStream;
            this.cameraModal.classList.add('active');
        } catch (error) {
            alert('Unable to access camera. Please check permissions.');
            console.error('Camera error:', error);
        }
    }
    
    takePicture() {
        const video = this.cameraVideo;
        const canvas = this.cameraCanvas;
        
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        
        const ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0);
        
        this.currentImage = canvas.toDataURL('image/jpeg', 0.9);
        this.previewImage.src = this.currentImage;
        this.previewArea.classList.add('has-image');
        
        this.closeCamera();
        this.updateSolveButton();
    }
    
    closeCamera() {
        if (this.cameraStream) {
            this.cameraStream.getTracks().forEach(track => track.stop());
            this.cameraStream = null;
        }
        this.cameraModal.classList.remove('active');
    }
    
    async captureScreen() {
        this.switchToImageMode();
        
        try {
            const stream = await navigator.mediaDevices.getDisplayMedia({
                video: { displaySurface: 'monitor' }
            });
            
            const video = document.createElement('video');
            video.srcObject = stream;
            
            await new Promise((resolve) => {
                video.onloadedmetadata = () => {
                    video.play();
                    resolve();
                };
            });
            
            // Wait a moment for the frame to be ready
            await new Promise(resolve => setTimeout(resolve, 100));
            
            const canvas = document.createElement('canvas');
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            
            const ctx = canvas.getContext('2d');
            ctx.drawImage(video, 0, 0);
            
            // Stop the stream
            stream.getTracks().forEach(track => track.stop());
            
            this.currentImage = canvas.toDataURL('image/png');
            this.previewImage.src = this.currentImage;
            this.previewArea.classList.add('has-image');
            this.updateSolveButton();
            
        } catch (error) {
            if (error.name !== 'AbortError') {
                alert('Screen capture failed. Please try again.');
                console.error('Screen capture error:', error);
            }
        }
    }
    
    switchToTextMode() {
        this.currentMode = 'text';
        this.textInputArea.classList.add('active');
        this.previewArea.style.display = 'none';
        
        // Update button states
        document.querySelectorAll('.capture-btn').forEach(btn => btn.classList.remove('active'));
        this.textBtn.classList.add('active');
        
        this.problemText.focus();
        this.updateSolveButton();
    }
    
    switchToImageMode() {
        this.currentMode = 'image';
        this.textInputArea.classList.remove('active');
        this.previewArea.style.display = 'flex';
        
        // Update button states
        document.querySelectorAll('.capture-btn').forEach(btn => btn.classList.remove('active'));
    }
    
    handleDragOver(event) {
        event.preventDefault();
        this.previewArea.style.borderColor = 'var(--primary)';
    }
    
    handleDragLeave() {
        if (!this.currentImage) {
            this.previewArea.style.borderColor = '';
        }
    }
    
    handleDrop(event) {
        event.preventDefault();
        this.handleDragLeave();
        
        const file = event.dataTransfer.files[0];
        if (file && file.type.startsWith('image/')) {
            this.switchToImageMode();
            this.loadImage(file);
        }
    }
    
    handlePaste(event) {
        const items = event?.clipboardData?.items || [];
        
        for (const item of items) {
            if (item.type.startsWith('image/')) {
                const file = item.getAsFile();
                this.switchToImageMode();
                this.loadImage(file);
                event.preventDefault();
                break;
            }
        }
    }
    
    updateSolveButton() {
        const hasContent = this.currentMode === 'text' 
            ? this.problemText.value.trim().length > 0
            : this.currentImage !== null;
        
        this.solveBtn.disabled = !hasContent;
    }
    
    async solve() {
        this.solveBtn.classList.add('loading');
        this.solveBtn.disabled = true;
        
        // Show processing message
        const processingMsg = this.currentMode === 'image' 
            ? 'Processing image with AI vision model... This may take 1-3 minutes on first run.'
            : 'Analyzing problem...';
        
        this.showProcessing(processingMsg);
        
        try {
            let response;
            
            if (this.currentMode === 'text') {
                response = await fetch(`${this.API_BASE}/api/solve-text`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        text: this.problemText.value,
                        subject: this.subjectSelect.value,
                        show_answer: this.showAnswerToggle.checked
                    })
                });
            } else {
                response = await fetch(`${this.API_BASE}/api/analyze`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        image_base64: this.currentImage,
                        subject: this.subjectSelect.value,
                        show_answer: this.showAnswerToggle.checked
                    })
                });
            }
            
            const data = await response.json();
            
            if (data.success) {
                this.displayResults(data);
            } else {
                this.showError(data.error || 'Failed to analyze problem');
            }
            
        } catch (error) {
            this.showError('Connection error. Please ensure the server is running.');
            console.error('Solve error:', error);
        } finally {
            this.solveBtn.classList.remove('loading');
            this.updateSolveButton();
        }
    }
    
    showProcessing(message) {
        this.resultsSection.classList.add('active');
        this.extractedTextCard.style.display = 'none';
        this.solutionContent.innerHTML = `
            <div style="color: var(--primary); padding: var(--spacing-xl); text-align: center;">
                <div style="display: inline-block; width: 50px; height: 50px; border: 4px solid var(--primary-light); border-top-color: var(--primary); border-radius: 50%; animation: spin 1s linear infinite; margin-bottom: var(--spacing-md);"></div>
                <p><strong>${message}</strong></p>
                <p style="margin-top: var(--spacing-md); color: var(--text-secondary);">
                    Please wait... The AI is analyzing your problem.
                </p>
            </div>
        `;
        this.resultsSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    
    displayResults(data) {
        // Show results section
        this.resultsSection.classList.add('active');
        
        // Update problem type badge
        const typeLabels = {
            'math': 'Mathematics',
            'physics': 'Physics',
            'chemistry': 'Chemistry',
            'word_problem': 'Word Problem',
            'general': 'General'
        };
        this.problemTypeBadge.textContent = typeLabels[data.problem_type] || 'General';
        
        // Show/hide extracted text card
        if (data.extracted_text) {
            this.extractedTextCard.style.display = 'block';
            this.extractedText.textContent = data.extracted_text;
        } else {
            this.extractedTextCard.style.display = 'none';
        }
        
        // Render solution
        const solution = data.solution;
        let solutionHTML = '';
        
        if (solution.full_response) {
            // Parse markdown-like formatting
            solutionHTML = this.formatSolution(solution.full_response);
        } else if (solution.explanation) {
            solutionHTML = this.formatSolution(solution.explanation);
        }
        
        this.solutionContent.innerHTML = solutionHTML;
        
        // Scroll to results
        this.resultsSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    
    formatSolution(text) {
        // Escape HTML
        let html = text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
        
        // Format headers (** bold text ** as headers)
        html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
        
        // Format section headers with colons
        html = html.replace(/^(.*?:)\s*$/gm, '<h4>$1</h4>');
        
        // Format numbered lists
        html = html.replace(/^(\d+)\.\s+(.+)$/gm, '<div class="solution-step"><span class="step-number">$1</span><div class="step-content">$2</div></div>');
        
        // Format bullet points
        html = html.replace(/^[-•]\s+(.+)$/gm, '<li>$1</li>');
        html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>');
        
        // Format code blocks
        html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>');
        
        // Format inline code
        html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
        
        // Format line breaks (double newline = paragraph)
        html = html.replace(/\n\n/g, '</p><p>');
        html = html.replace(/\n/g, '<br>');
        
        // Wrap in paragraphs
        html = '<p>' + html + '</p>';
        
        // Clean up empty paragraphs
        html = html.replace(/<p>\s*<\/p>/g, '');
        html = html.replace(/<p><h4>/g, '<h4>');
        html = html.replace(/<\/h4><\/p>/g, '</h4>');
        html = html.replace(/<p><div class="solution-step">/g, '<div class="solution-step">');
        html = html.replace(/<\/div><\/p>/g, '</div>');
        
        return html;
    }
    
    showError(message) {
        this.resultsSection.classList.add('active');
        this.extractedTextCard.style.display = 'none';
        this.solutionContent.innerHTML = `
            <div style="color: var(--error); padding: var(--spacing-lg); text-align: center;">
                <p><strong>Error:</strong> ${message}</p>
                <p style="margin-top: var(--spacing-md); color: var(--text-secondary);">
                    Please ensure Ollama is running with the required models installed.
                </p>
            </div>
        `;
    }
    
    copySolution() {
        const text = this.solutionContent.innerText;
        navigator.clipboard.writeText(text).then(() => {
            const originalText = this.copyBtn.innerHTML;
            this.copyBtn.innerHTML = `
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="20,6 9,17 4,12"/>
                </svg>
                Copied!
            `;
            setTimeout(() => {
                this.copyBtn.innerHTML = originalText;
            }, 2000);
        });
    }
    
    reset() {
        // Reset image
        this.currentImage = null;
        this.previewImage.src = '';
        this.previewArea.classList.remove('has-image');
        this.fileInput.value = '';
        
        // Reset text
        this.problemText.value = '';
        
        // Reset mode
        this.switchToImageMode();
        
        // Reset options
        this.subjectSelect.value = 'auto';
        this.showAnswerToggle.checked = true;
        
        // Hide results
        this.resultsSection.classList.remove('active');
        
        // Update button
        this.updateSolveButton();
        
        // Scroll to top
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.solveAssist = new SolveAssistAI();
});


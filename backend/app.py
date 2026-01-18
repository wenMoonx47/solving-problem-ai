"""
SolveAssist AI - Main Flask Application
AI-powered problem-solving assistant for teaching and learning
"""

import os
import base64
import json
from io import BytesIO
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from PIL import Image, ImageEnhance, ImageFilter
import pytesseract
from solver import ProblemSolver
from ocr_engine import OCREngine
import cv2
import numpy as np

def preprocess_for_vision(image):
    """
    Preprocess image to make text clearer for vision model
    - Increase contrast
    - Sharpen
    - Remove noise
    - Ensure good size
    """
    # Convert to RGB if needed
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize if too small (min 800px width for better readability)
    width, height = image.size
    if width < 800:
        scale = 800 / width
        new_size = (int(width * scale), int(height * scale))
        image = image.resize(new_size, Image.Resampling.LANCZOS)
        print(f"[DEBUG] Resized image: {image.size}")
    
    # Increase contrast
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(1.5)  # 50% more contrast
    
    # Increase sharpness
    enhancer = ImageEnhance.Sharpness(image)
    image = enhancer.enhance(2.0)  # Double sharpness
    
    # Optional: Convert to grayscale then back to RGB (improves text clarity)
    # This helps the vision model focus on text structure
    img_array = np.array(image)
    gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
    
    # Apply bilateral filter to reduce noise while keeping edges
    denoised = cv2.bilateralFilter(gray, 9, 75, 75)
    
    # Increase contrast using CLAHE
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(denoised)
    
    # Convert back to RGB
    rgb_enhanced = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2RGB)
    image = Image.fromarray(rgb_enhanced)
    
    return image

app = Flask(__name__, static_folder='../frontend', static_url_path='')
CORS(app)

# Initialize engines
ocr_engine = OCREngine()
problem_solver = ProblemSolver()


@app.route('/')
def serve_frontend():
    """Serve the main frontend application"""
    return send_from_directory(app.static_folder, 'index.html')


@app.route('/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory(app.static_folder, path)


@app.route('/api/health', methods=['GET'])
def health_check():
    """Check if the server and AI models are running"""
    ai_status = problem_solver.check_model_status()
    return jsonify({
        'status': 'healthy',
        'ocr_available': ocr_engine.is_available(),
        'ai_model': ai_status
    })


@app.route('/api/analyze', methods=['POST'])
def analyze_image():
    """
    Main endpoint: Analyze an image containing a problem
    Accepts: base64 image or file upload
    Returns: Extracted text, problem type, and solution steps
    """
    try:
        image_data = None
        
        # Debug logging
        print(f"[DEBUG] Content-Type: {request.content_type}")
        print(f"[DEBUG] Has files: {'image' in request.files}")
        print(f"[DEBUG] Has JSON: {request.json is not None}")
        if request.json:
            print(f"[DEBUG] JSON keys: {list(request.json.keys())}")
        
        # Handle different input methods
        if 'image' in request.files:
            file = request.files['image']
            image_data = file.read()
            print(f"[DEBUG] Loaded image from file upload")
        elif request.json and 'image_base64' in request.json:
            base64_data = request.json['image_base64']
            print(f"[DEBUG] Base64 data length: {len(base64_data)}")
            # Remove data URL prefix if present
            if ',' in base64_data:
                base64_data = base64_data.split(',')[1]
                print(f"[DEBUG] Removed data URL prefix")
            image_data = base64.b64decode(base64_data)
            print(f"[DEBUG] Decoded image data: {len(image_data)} bytes")
        else:
            error_msg = f"No image provided. Has files: {'image' in request.files}, Has JSON: {request.json is not None}"
            print(f"[ERROR] {error_msg}")
            return jsonify({'error': 'No image provided', 'debug': error_msg}), 400

        # Process and enhance image for better AI reading
        image = Image.open(BytesIO(image_data))
        print(f"[DEBUG] Image opened: {image.size}, mode: {image.mode}")
        
        # Preprocess image for better vision model accuracy
        image = preprocess_for_vision(image)
        
        # Re-encode the processed image
        buffered = BytesIO()
        image.save(buffered, format="PNG")
        image_data = buffered.getvalue()
        print(f"[DEBUG] Image preprocessed for AI vision")
        
        # Get options from request
        options = request.json if request.json else {}
        show_answer = options.get('show_answer', True)
        subject_hint = options.get('subject', 'auto')
        
        # Step 1: Skip OCR - Let vision model read directly (more accurate for math)
        # OCR often misreads math symbols, equations, and handwriting
        # The vision model is trained to handle these better
        extracted_text = "[Vision model will read directly from image]"
        print("[INFO] Using vision model for direct image reading (more accurate than OCR for math)")
        
        # Step 2: Detect problem type
        print(f"[DEBUG] Detecting problem type...")
        problem_type = problem_solver.detect_problem_type(extracted_text, subject_hint)
        print(f"[DEBUG] Problem type: {problem_type}")
        
        # Step 3: Get AI solution with step-by-step explanation
        print(f"[DEBUG] Calling AI solver... (this may take 1-2 minutes for vision models)")
        solution = problem_solver.solve(
            image_data=image_data,
            extracted_text=extracted_text,
            problem_type=problem_type,
            show_answer=show_answer
        )
        print(f"[DEBUG] Solution received")
        
        return jsonify({
            'success': True,
            'extracted_text': extracted_text,
            'problem_type': problem_type,
            'solution': solution
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/solve-text', methods=['POST'])
def solve_text():
    """
    Solve a problem from text input (no image)
    Useful for typed problems or quick queries
    """
    try:
        data = request.json
        if not data or 'text' not in data:
            return jsonify({'error': 'No text provided'}), 400
        
        text = data['text']
        show_answer = data.get('show_answer', True)
        subject_hint = data.get('subject', 'auto')
        
        # Detect problem type
        problem_type = problem_solver.detect_problem_type(text, subject_hint)
        
        # Get solution
        solution = problem_solver.solve(
            image_data=None,
            extracted_text=text,
            problem_type=problem_type,
            show_answer=show_answer
        )
        
        return jsonify({
            'success': True,
            'problem_type': problem_type,
            'solution': solution
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/explain-step', methods=['POST'])
def explain_step():
    """
    Get a more detailed explanation of a specific step
    """
    try:
        data = request.json
        step_text = data.get('step', '')
        context = data.get('context', '')
        
        explanation = problem_solver.explain_step(step_text, context)
        
        return jsonify({
            'success': True,
            'explanation': explanation
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


if __name__ == '__main__':
    print("""
    ╔═══════════════════════════════════════════════════════════════╗
    ║                      SolveAssist AI                           ║
    ║         Instant problem-solving guidance for learning         ║
    ╚═══════════════════════════════════════════════════════════════╝
    """)
    print("Starting server at http://localhost:5000")
    print("Open your browser and navigate to http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)


"""
SolveAssist AI - OCR Engine
Handles text extraction from images including math symbols and handwriting
"""

import re
from PIL import Image, ImageFilter, ImageEnhance
import pytesseract
import cv2
import numpy as np


class OCREngine:
    """
    OCR Engine for extracting text from educational content
    Supports: printed text, handwriting, math equations, diagrams
    """
    
    def __init__(self):
        # Set custom tessdata path for snap-installed Tesseract
        import os
        import tempfile
        
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        tessdata_dir = os.path.join(project_root, 'tessdata')
        
        if os.path.exists(tessdata_dir):
            os.environ['TESSDATA_PREFIX'] = tessdata_dir
            
        # Use snap tesseract if available
        if os.path.exists('/snap/bin/tesseract'):
            pytesseract.pytesseract.tesseract_cmd = '/snap/bin/tesseract'
            # Set temp directory in user space (snap can access this)
            temp_dir = os.path.join(os.path.expanduser('~'), '.cache', 'solveassist-ocr')
            os.makedirs(temp_dir, exist_ok=True)
            os.environ['TMPDIR'] = temp_dir
            tempfile.tempdir = temp_dir
        
        self.tesseract_config = r'--oem 3 --psm 6'
        self.math_tesseract_config = r'--oem 3 --psm 6 -c tessedit_char_whitelist=0123456789+-×÷=()[]{}xyzXYZabcdefghijklmnopqrstuvwABCDEFGHIJKLMNOPQRSTUVW^√∫∑∏αβγδεζηθικλμνξοπρστυφχψω'
    
    def is_available(self):
        """Check if Tesseract OCR is available"""
        try:
            pytesseract.get_tesseract_version()
            return True
        except Exception:
            return False
    
    def preprocess_image(self, image):
        """
        Preprocess image for better OCR results
        Handles various input qualities (photos, screenshots, scans)
        """
        # Convert PIL Image to numpy array
        img_array = np.array(image)
        
        # Convert to grayscale if needed
        if len(img_array.shape) == 3:
            gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = img_array
        
        # Apply denoising
        denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
        
        # Increase contrast
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(denoised)
        
        # Apply adaptive thresholding for better text detection
        binary = cv2.adaptiveThreshold(
            enhanced, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY, 11, 2
        )
        
        # Convert back to PIL Image
        return Image.fromarray(binary)
    
    def extract_text(self, image):
        """
        Extract text from image using OCR
        Returns cleaned and structured text
        """
        try:
            # Try simple OCR first (faster, no preprocessing)
            try:
                text = pytesseract.image_to_string(
                    image, 
                    config=self.tesseract_config,
                    timeout=10  # 10 second timeout
                )
                if text and len(text.strip()) > 3:
                    return self._clean_text(text)
            except Exception as simple_error:
                print(f"[DEBUG] Simple OCR failed: {simple_error}")
            
            # If simple OCR fails or returns nothing, try with preprocessing
            try:
                processed_image = self.preprocess_image(image)
                
                # Try standard OCR
                text = pytesseract.image_to_string(
                    processed_image, 
                    config=self.tesseract_config,
                    timeout=10
                )
                
                # Clean and format the text
                cleaned_text = self._clean_text(text)
                return cleaned_text
            except Exception as preprocess_error:
                print(f"[DEBUG] Preprocessed OCR failed: {preprocess_error}")
                raise
            
        except Exception as e:
            print(f"[ERROR] OCR completely failed: {str(e)}")
            return f"OCR Error: {str(e)}"
    
    def _merge_ocr_results(self, standard_text, math_text):
        """
        Merge standard and math OCR results
        Choose the one with better math symbol coverage
        """
        math_symbols = set('+-×÷=()[]{}^√∫∑∏αβγδεζηθικλμνξοπρστυφχψω²³⁴⁵⁶⁷⁸⁹⁰')
        
        standard_math_count = sum(1 for c in standard_text if c in math_symbols)
        math_text_count = sum(1 for c in math_text if c in math_symbols)
        
        if math_text_count > standard_math_count:
            return math_text
        return standard_text
    
    def _clean_text(self, text):
        """
        Clean OCR output for better processing
        """
        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Fix common OCR errors for math
        replacements = {
            'x': '×',  # Only in obvious multiplication contexts
            'X': '×',
            '—': '-',
            '–': '-',
            ''': "'",
            ''': "'",
            '"': '"',
            '"': '"',
        }
        
        # Apply safe replacements
        for old, new in replacements.items():
            # Only replace in specific contexts
            pass  # Keep original for now, let AI handle interpretation
        
        return text.strip()
    
    def extract_equations(self, image):
        """
        Specifically extract mathematical equations from image
        Returns list of detected equations
        """
        text = self.extract_text(image)
        
        # Pattern for detecting equations
        equation_patterns = [
            r'[a-zA-Z0-9\s\+\-\*\/\=\(\)\[\]\{\}\^]+\s*=\s*[a-zA-Z0-9\s\+\-\*\/\(\)\[\]\{\}\^]+',
            r'\d+\s*[\+\-\*\/×÷]\s*\d+',
            r'[a-zA-Z]\s*=\s*\d+',
        ]
        
        equations = []
        for pattern in equation_patterns:
            matches = re.findall(pattern, text)
            equations.extend(matches)
        
        return equations
    
    def get_image_regions(self, image):
        """
        Detect different regions in the image (text, diagrams, graphs)
        Useful for complex problems with multiple parts
        """
        img_array = np.array(image)
        
        if len(img_array.shape) == 3:
            gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = img_array
        
        # Detect text regions using morphological operations
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 3))
        dilated = cv2.dilate(255 - gray, kernel, iterations=3)
        
        contours, _ = cv2.findContours(
            dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        
        regions = []
        for contour in contours:
            x, y, w, h = cv2.boundingRect(contour)
            if w > 50 and h > 20:  # Filter small noise
                regions.append({
                    'bbox': (x, y, w, h),
                    'type': 'text' if w > h else 'diagram'
                })
        
        return regions


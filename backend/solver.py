"""
SolveAssist AI - Problem Solver Engine
AI-powered solution generation using local Ollama models
"""

import base64
import json
import re
from typing import Optional, Dict, Any
import ollama
from gpu_detector import gpu_detector


class ProblemSolver:
    """
    AI Problem Solver using local Ollama models
    Supports: Math, Physics, Chemistry, Word Problems
    """
    
    # Model configuration
    VISION_MODEL = "llava:7b"  # For image understanding
    TEXT_MODEL = "llama3.2:latest"  # For text reasoning
    MATH_MODEL = "llama3.2:latest"  # For mathematical computations
    
    # System prompts for different problem types
    SYSTEM_PROMPTS = {
        'math': """You are a math teacher. Solve this problem step-by-step.

Format:
**Problem**: Identify the type (algebra, calculus, etc.)
**Solution**:
Step 1: [action and result]
Step 2: [action and result]
**Answer**: [final answer]

Keep it concise but clear.""",

        'physics': """You are a physics teacher. Solve step-by-step with units.

Format:
**Given**: List quantities with units
**Find**: What we need
**Formula**: Relevant equation
**Solution**:
Step 1: [calculation with units]
**Answer**: [result with units]

Keep it concise.""",

        'chemistry': """You are a chemistry teacher. Solve step-by-step.

Format:
**Problem**: Type of chemistry problem
**Solution**:
Step 1: [action and result]
**Answer**: [result with units]

Keep it concise.""",

        'word_problem': """You are a problem-solving teacher. Solve step-by-step.

Format:
**Given**: Key facts
**Find**: What we need
**Solution**:
Step 1: [action]
**Answer**: [result]

Keep it concise.""",

        'general': """You are a tutor. Explain clearly and concisely with step-by-step reasoning."""
    }
    
    def __init__(self):
        self.client = None
        self._init_client()
    
    def _init_client(self):
        """Initialize Ollama client with GPU support"""
        try:
            import httpx
            timeout = httpx.Timeout(300.0, connect=10.0)
            self.client = ollama.Client(timeout=timeout)
            
            # Get optimal settings based on GPU availability
            self.optimal_settings = gpu_detector.get_optimal_settings()
            
            if gpu_detector.has_gpu:
                print(f"[INFO] GPU Mode: Using optimized settings for {gpu_detector.gpu_info['name']}")
            else:
                print(f"[INFO] CPU Mode: Using conservative settings for speed")
                
        except Exception as e:
            print(f"Warning: Could not initialize Ollama client: {e}")
            self.client = None
            self.optimal_settings = {}
    
    def check_model_status(self) -> Dict[str, Any]:
        """Check if required AI models are available"""
        status = {
            'ollama_running': False,
            'vision_model': False,
            'text_model': False,
            'models_available': []
        }
        
        try:
            if self.client:
                models = self.client.list()
                status['ollama_running'] = True
                status['models_available'] = [m['name'] for m in models.get('models', [])]
                
                for model_name in status['models_available']:
                    if 'llava' in model_name.lower():
                        status['vision_model'] = True
                    if 'llama' in model_name.lower():
                        status['text_model'] = True
                        
        except Exception as e:
            status['error'] = str(e)
        
        return status
    
    def detect_problem_type(self, text: str, hint: str = 'auto') -> str:
        """
        Detect the type of problem from text
        Returns: 'math', 'physics', 'chemistry', 'word_problem', or 'general'
        """
        if hint != 'auto' and hint in self.SYSTEM_PROMPTS:
            return hint
        
        text_lower = text.lower()
        
        # Physics indicators (weighted)
        physics_keywords = [
            'velocity', 'acceleration', 'force', 'mass', 'newton',
            'joule', 'watt', 'energy', 'momentum', 'friction',
            'gravity', 'electric', 'magnetic', 'wave', 'frequency',
            'm/s', 'kg', 'meters per second'
        ]
        
        # Chemistry indicators (weighted)
        chemistry_keywords = [
            'molecule', 'atom', 'element', 'compound', 'reaction',
            'mole', 'molarity', 'concentration', 'acid', 'base',
            'ph', 'oxidation', 'reduction', 'bond', 'ion',
            'h2o', 'nacl', 'co2', 'chemical', 'balance equation'
        ]
        
        # Math indicators (weighted)
        math_keywords = [
            'solve', 'equation', 'algebra', 'calculus', 'geometry',
            'integral', 'derivative', 'function', 'graph',
            'polynomial', 'quadratic', 'linear', 'matrix', 'vector',
            'limit', 'series', 'sum', 'product',
            'sin', 'cos', 'tan', 'log', 'ln', 'sqrt', '√'
        ]
        
        # Count keyword matches
        physics_score = sum(1 for kw in physics_keywords if kw in text_lower)
        chemistry_score = sum(1 for kw in chemistry_keywords if kw in text_lower)
        math_score = sum(1 for kw in math_keywords if kw in text_lower)
        
        # Check for math expressions (most reliable indicator)
        has_math_expr = self._has_math_expressions(text)
        
        # Check for word problem indicators
        word_problem_indicators = [
            'how many', 'how much', 'find the', 'calculate the', 
            'what is the', 'if', 'when', 'total', 'remaining'
        ]
        is_word_problem = any(ind in text_lower for ind in word_problem_indicators)
        
        # Determine type with improved logic
        # If it has math expressions (=, x, equations), it's math-based
        if has_math_expr:
            # But check if it's physics/chemistry WITH math
            if physics_score >= 3:  # Strong physics indicators
                return 'physics'
            elif chemistry_score >= 3:  # Strong chemistry indicators
                return 'chemistry'
            else:
                return 'math'  # Default to math for equations
        
        # No math expressions, use keyword scoring
        max_score = max(physics_score, chemistry_score, math_score)
        
        # Need at least 2 matches to confidently assign
        if physics_score >= 2 and physics_score == max_score:
            return 'physics'
        elif chemistry_score >= 2 and chemistry_score == max_score:
            return 'chemistry'
        elif math_score > 0:
            return 'math'
        elif is_word_problem:
            return 'word_problem'
        else:
            return 'math'  # When in doubt, assume math (most common)
    
    def _has_math_expressions(self, text: str) -> bool:
        """Check if text contains mathematical expressions"""
        math_patterns = [
            r'\d+\s*[\+\-\*\/×÷\^]\s*\d+',  # Basic operations
            r'[a-zA-Z]\s*=\s*\d+',  # Variable assignment
            r'\d+\s*=\s*\d+',  # Equations
            r'\([^)]+\)',  # Parentheses
            r'x\^?\d*',  # Variable with exponent
        ]
        
        for pattern in math_patterns:
            if re.search(pattern, text):
                return True
        return False
    
    def solve(
        self,
        image_data: Optional[bytes],
        extracted_text: str,
        problem_type: str,
        show_answer: bool = True
    ) -> Dict[str, Any]:
        """
        Main solving function
        Uses vision model for images, text model for text-only
        """
        
        system_prompt = self.SYSTEM_PROMPTS.get(problem_type, self.SYSTEM_PROMPTS['general'])
        
        if not show_answer:
            system_prompt += "\n\nIMPORTANT: Do NOT provide the final numerical answer. Instead, guide the student through the solution process and let them arrive at the answer themselves."
        
        try:
            if image_data and self._has_vision_model():
                return self._solve_with_vision(image_data, extracted_text, system_prompt, problem_type)
            else:
                return self._solve_with_text(extracted_text, system_prompt, problem_type)
        except Exception as e:
            return {
                'steps': [],
                'explanation': f"Error solving problem: {str(e)}",
                'answer': None,
                'error': str(e)
            }
    
    def _has_vision_model(self) -> bool:
        """Check if vision model is available"""
        status = self.check_model_status()
        return status.get('vision_model', False)
    
    def _solve_with_vision(
        self,
        image_data: bytes,
        extracted_text: str,
        system_prompt: str,
        problem_type: str
    ) -> Dict[str, Any]:
        """Solve using vision-language model"""
        
        # Encode image to base64
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        
        # Let vision model read the image directly (most accurate)
        user_prompt = f"""STEP 1: First, carefully read and write down EXACTLY what you see in the image. Read every character, number, and symbol.

STEP 2: Then solve the problem you identified in Step 1.

Format:
**What I see**: [Write the exact equation/problem from the image]
**Solution**:
Step 1: [solving step]
Step 2: [solving step]
**Answer**: [final answer]"""

        try:
            print(f"[DEBUG] Sending request to vision model: {self.VISION_MODEL}")
            print(f"[INFO] Vision model inference may take 1-3 minutes on first run...")
            
            response = self.client.chat(
                model=self.VISION_MODEL,
                messages=[
                    {'role': 'system', 'content': system_prompt},
                    {
                        'role': 'user',
                        'content': user_prompt,
                        'images': [image_base64]
                    }
                ],
                options=self.optimal_settings  # Auto-adjust based on GPU/CPU
            )
            
            print(f"[DEBUG] Vision model response received")
            return self._parse_solution(response['message']['content'], problem_type)
            
        except Exception as e:
            print(f"[ERROR] Vision model failed: {e}")
            # Fallback to text-only if vision fails
            print(f"[INFO] Falling back to text-only model")
            return self._solve_with_text(extracted_text, system_prompt, problem_type)
    
    def _solve_with_text(
        self,
        text: str,
        system_prompt: str,
        problem_type: str
    ) -> Dict[str, Any]:
        """Solve using text-only model"""
        
        user_prompt = f"""Please solve this problem and provide a step-by-step solution:

{text}

Provide a clear, educational explanation suitable for teaching."""

        try:
            print(f"[DEBUG] Sending request to text model: {self.TEXT_MODEL}")
            
            response = self.client.chat(
                model=self.TEXT_MODEL,
                messages=[
                    {'role': 'system', 'content': system_prompt},
                    {'role': 'user', 'content': user_prompt}
                ],
                options=self.optimal_settings  # Auto-adjust based on GPU/CPU
            )
            
            print(f"[DEBUG] Text model response received")
            return self._parse_solution(response['message']['content'], problem_type)
            
        except Exception as e:
            print(f"[ERROR] Text model failed: {e}")
            return {
                'steps': [],
                'explanation': f"Could not connect to AI model. Please ensure Ollama is running.\n\nError: {str(e)}",
                'answer': None,
                'error': str(e)
            }
    
    def _parse_solution(self, response_text: str, problem_type: str) -> Dict[str, Any]:
        """Parse AI response into structured solution"""
        
        # Extract sections from response
        sections = {}
        current_section = 'explanation'
        current_content = []
        
        for line in response_text.split('\n'):
            # Check for section headers
            if line.startswith('**') and '**' in line[2:]:
                if current_content:
                    sections[current_section] = '\n'.join(current_content).strip()
                section_name = line.strip('*: ').lower().replace(' ', '_')
                current_section = section_name
                current_content = []
            else:
                current_content.append(line)
        
        # Don't forget the last section
        if current_content:
            sections[current_section] = '\n'.join(current_content).strip()
        
        # Extract steps from the solution
        steps = self._extract_steps(response_text)
        
        # Extract final answer
        answer = sections.get('final_answer', None)
        
        return {
            'full_response': response_text,
            'sections': sections,
            'steps': steps,
            'explanation': sections.get('explanation', response_text),
            'answer': answer,
            'problem_type': problem_type
        }
    
    def _extract_steps(self, text: str) -> list:
        """Extract numbered steps from solution text"""
        steps = []
        
        # Pattern for numbered steps
        step_patterns = [
            r'Step\s*(\d+)[:\.\)]\s*(.+?)(?=Step\s*\d+|$)',
            r'(\d+)[:\.\)]\s*(.+?)(?=\d+[:\.\)]|$)',
        ]
        
        for pattern in step_patterns:
            matches = re.findall(pattern, text, re.DOTALL | re.IGNORECASE)
            if matches:
                for num, content in matches:
                    steps.append({
                        'number': int(num),
                        'content': content.strip()
                    })
                break
        
        return steps
    
    def explain_step(self, step_text: str, context: str = '') -> str:
        """Get a more detailed explanation of a specific step"""
        
        prompt = f"""A student is confused about this step in a problem solution:

Step: {step_text}

Context of the full problem: {context}

Please provide a more detailed explanation of this step, including:
1. Why this step is necessary
2. The underlying concept or formula being applied
3. A simpler example if helpful
4. Common mistakes to avoid"""

        try:
            response = self.client.chat(
                model=self.TEXT_MODEL,
                messages=[
                    {'role': 'system', 'content': 'You are a patient and thorough teacher helping a student understand a problem solution.'},
                    {'role': 'user', 'content': prompt}
                ]
            )
            
            return response['message']['content']
            
        except Exception as e:
            return f"Could not get explanation: {str(e)}"


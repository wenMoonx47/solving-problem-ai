"""
SolveAssist AI - GPU Detection and Configuration
Automatically detects GPU and optimizes settings
"""

import subprocess
import os

class GPUDetector:
    """Detect GPU availability and configure optimal settings"""
    
    def __init__(self):
        self.has_gpu = self.detect_nvidia_gpu()
        self.gpu_info = self.get_gpu_info() if self.has_gpu else None
        self.configure_environment()
    
    def detect_nvidia_gpu(self):
        """Check if NVIDIA GPU is available"""
        try:
            result = subprocess.run(
                ['nvidia-smi'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False
    
    def get_gpu_info(self):
        """Get GPU information"""
        if not self.has_gpu:
            return None
        
        try:
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=name,memory.total', '--format=csv,noheader'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                gpu_data = result.stdout.strip().split(',')
                return {
                    'name': gpu_data[0].strip() if len(gpu_data) > 0 else 'Unknown',
                    'memory': gpu_data[1].strip() if len(gpu_data) > 1 else 'Unknown'
                }
        except Exception as e:
            print(f"[DEBUG] Could not get GPU info: {e}")
        
        return {'name': 'NVIDIA GPU', 'memory': 'Unknown'}
    
    def configure_environment(self):
        """Set environment variables for GPU if available"""
        if self.has_gpu:
            # Ollama will automatically use GPU
            os.environ['OLLAMA_GPU'] = '1'
            print(f"[INFO] GPU detected: {self.gpu_info['name']} ({self.gpu_info['memory']})")
            print(f"[INFO] Ollama will use GPU acceleration")
        else:
            print("[INFO] No GPU detected, using CPU")
    
    def get_optimal_settings(self):
        """Get optimal model settings based on hardware"""
        if self.has_gpu:
            # GPU settings - can handle larger context and faster inference
            return {
                'num_ctx': 4096,  # Larger context window
                'num_predict': 2048,  # Longer responses
                'temperature': 0.3,
                'top_p': 0.9,
                'top_k': 40,
                'num_gpu': 99,  # Use all available GPU layers
            }
        else:
            # CPU settings - smaller for speed
            return {
                'num_ctx': 1024,
                'num_predict': 500,
                'temperature': 0.3,
                'top_p': 0.9,
                'top_k': 40,
            }
    
    def get_recommended_workers(self):
        """Get recommended number of Gunicorn workers"""
        if self.has_gpu:
            # With GPU, can handle more concurrent requests
            return 4
        else:
            # CPU - keep it low
            return 2

# Global instance
gpu_detector = GPUDetector()


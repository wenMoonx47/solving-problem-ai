"""
SolveAssist AI - Mathematical Calculation Verification
Uses SymPy for symbolic computation to verify AI-generated solutions
"""

import re
from typing import Dict, Any, List, Optional, Tuple
from sympy import (
    symbols, sympify, solve, diff, integrate,
    simplify, expand, factor, sqrt, sin, cos, tan,
    pi, E, oo, Eq, parse_expr, N, Abs,
    log, ln, exp, Rational, Float
)
from sympy.parsing.sympy_parser import (
    parse_expr, standard_transformations,
    implicit_multiplication_application,
    convert_xor, implicit_application
)


class MathVerifier:
    """
    Verify mathematical calculations using symbolic computation.
    Helps ensure AI solutions are mathematically correct.
    """
    
    def __init__(self):
        self.transformations = (
            standard_transformations + 
            (implicit_multiplication_application, convert_xor)
        )
        # Common variable symbols
        self.common_symbols = symbols('x y z a b c t n m k')
    
    def parse_expression(self, expr_str: str) -> Optional[Any]:
        """
        Parse a string expression into SymPy format.
        Handles common mathematical notation.
        """
        if not expr_str or not isinstance(expr_str, str):
            return None
            
        try:
            # Clean up notation
            expr_str = expr_str.strip()
            
            # Replace common mathematical notation
            replacements = [
                ('^', '**'),          # Exponents
                ('×', '*'),           # Multiplication
                ('÷', '/'),           # Division
                ('√', 'sqrt'),        # Square root
                ('²', '**2'),         # Squared
                ('³', '**3'),         # Cubed
                ('π', 'pi'),          # Pi
                ('∞', 'oo'),          # Infinity
            ]
            
            for old, new in replacements:
                expr_str = expr_str.replace(old, new)
            
            # Handle implicit multiplication (e.g., 2x → 2*x)
            expr_str = re.sub(r'(\d)([a-zA-Z])', r'\1*\2', expr_str)
            
            return parse_expr(expr_str, transformations=self.transformations)
            
        except Exception as e:
            return None
    
    def verify_arithmetic(self, expression: str, claimed_result: str) -> Dict[str, Any]:
        """
        Verify a basic arithmetic calculation.
        
        Example: verify_arithmetic("2 + 3 * 4", "14")
        """
        try:
            expr = self.parse_expression(expression)
            claimed = self.parse_expression(claimed_result)
            
            if expr is None or claimed is None:
                return {'verified': False, 'error': 'Could not parse expression'}
            
            # Evaluate the expression
            result = simplify(expr)
            
            # Compare
            is_correct = simplify(result - claimed) == 0
            
            return {
                'verified': True,
                'expression': expression,
                'claimed': str(claimed_result),
                'actual': str(result),
                'is_correct': is_correct,
                'error': None if is_correct else f"Expected {result}, got {claimed_result}"
            }
            
        except Exception as e:
            return {'verified': False, 'error': str(e)}
    
    def verify_equation_solution(
        self, 
        equation_str: str, 
        variable: str, 
        claimed_solution: str
    ) -> Dict[str, Any]:
        """
        Verify if a solution to an equation is correct.
        
        Example: verify_equation_solution("2x + 5 = 13", "x", "4")
        """
        try:
            # Parse the equation
            if '=' not in equation_str:
                return {'verified': False, 'error': 'No equals sign found'}
            
            left, right = equation_str.split('=', 1)
            left_expr = self.parse_expression(left.strip())
            right_expr = self.parse_expression(right.strip())
            
            if left_expr is None or right_expr is None:
                return {'verified': False, 'error': 'Could not parse equation'}
            
            equation = Eq(left_expr, right_expr)
            
            # Get the variable symbol
            var = symbols(variable)
            
            # Solve symbolically
            solutions = solve(equation, var)
            
            # Parse claimed solution
            claimed = self.parse_expression(str(claimed_solution))
            
            if claimed is None:
                return {'verified': False, 'error': 'Could not parse claimed solution'}
            
            # Check if claimed solution matches any actual solution
            is_correct = any(simplify(sol - claimed) == 0 for sol in solutions)
            
            return {
                'verified': True,
                'equation': equation_str,
                'variable': variable,
                'claimed_solution': str(claimed_solution),
                'correct_solutions': [str(s) for s in solutions],
                'is_correct': is_correct,
                'error': None if is_correct else f"Correct solution(s): {solutions}"
            }
            
        except Exception as e:
            return {'verified': False, 'error': str(e)}
    
    def verify_derivative(
        self, 
        function_str: str, 
        variable: str, 
        claimed_derivative: str
    ) -> Dict[str, Any]:
        """
        Verify if a derivative calculation is correct.
        
        Example: verify_derivative("x^3", "x", "3x^2")
        """
        try:
            var = symbols(variable)
            f = self.parse_expression(function_str)
            
            if f is None:
                return {'verified': False, 'error': 'Could not parse function'}
            
            # Calculate the correct derivative
            correct_derivative = diff(f, var)
            
            # Parse claimed derivative
            claimed = self.parse_expression(claimed_derivative)
            
            if claimed is None:
                return {'verified': False, 'error': 'Could not parse claimed derivative'}
            
            # Compare (simplify both to handle equivalent forms)
            is_correct = simplify(correct_derivative - claimed) == 0
            
            return {
                'verified': True,
                'function': function_str,
                'variable': variable,
                'claimed_derivative': str(claimed_derivative),
                'correct_derivative': str(simplify(correct_derivative)),
                'is_correct': is_correct,
                'error': None if is_correct else f"Correct derivative: {simplify(correct_derivative)}"
            }
            
        except Exception as e:
            return {'verified': False, 'error': str(e)}
    
    def verify_integral(
        self, 
        function_str: str, 
        variable: str, 
        claimed_integral: str
    ) -> Dict[str, Any]:
        """
        Verify if an integral calculation is correct.
        Note: Ignores constant of integration.
        
        Example: verify_integral("2x", "x", "x^2")
        """
        try:
            var = symbols(variable)
            f = self.parse_expression(function_str)
            
            if f is None:
                return {'verified': False, 'error': 'Could not parse function'}
            
            # Parse claimed integral
            claimed = self.parse_expression(claimed_integral)
            
            if claimed is None:
                return {'verified': False, 'error': 'Could not parse claimed integral'}
            
            # Verify by differentiating the claimed answer
            derivative_of_claimed = diff(claimed, var)
            is_correct = simplify(derivative_of_claimed - f) == 0
            
            # Also calculate the correct integral for reference
            correct_integral = integrate(f, var)
            
            return {
                'verified': True,
                'function': function_str,
                'variable': variable,
                'claimed_integral': str(claimed_integral),
                'correct_integral': str(simplify(correct_integral)) + " + C",
                'is_correct': is_correct,
                'error': None if is_correct else f"Correct integral: {simplify(correct_integral)} + C"
            }
            
        except Exception as e:
            return {'verified': False, 'error': str(e)}
    
    def simplify_expression(self, expr_str: str) -> Dict[str, Any]:
        """
        Simplify a mathematical expression.
        
        Example: simplify_expression("2x + 3x")  →  "5x"
        """
        try:
            expr = self.parse_expression(expr_str)
            
            if expr is None:
                return {'success': False, 'error': 'Could not parse expression'}
            
            simplified = simplify(expr)
            
            return {
                'success': True,
                'original': expr_str,
                'simplified': str(simplified),
                'is_different': str(expr) != str(simplified)
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def evaluate_expression(self, expr_str: str, **variables) -> Dict[str, Any]:
        """
        Evaluate an expression with given variable values.
        
        Example: evaluate_expression("x^2 + 2x", x=3)  →  15
        """
        try:
            expr = self.parse_expression(expr_str)
            
            if expr is None:
                return {'success': False, 'error': 'Could not parse expression'}
            
            # Substitute variables
            result = expr.subs(variables)
            
            # Try to get numerical value
            try:
                numerical = float(N(result))
            except:
                numerical = str(result)
            
            return {
                'success': True,
                'expression': expr_str,
                'variables': variables,
                'result': numerical
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def check_quadratic_formula(
        self, 
        a: str, 
        b: str, 
        c: str, 
        claimed_solutions: List[str]
    ) -> Dict[str, Any]:
        """
        Verify quadratic equation solutions.
        For ax² + bx + c = 0
        """
        try:
            a_val = self.parse_expression(a)
            b_val = self.parse_expression(b)
            c_val = self.parse_expression(c)
            
            # Calculate discriminant
            discriminant = b_val**2 - 4*a_val*c_val
            
            # Calculate solutions
            x1 = (-b_val + sqrt(discriminant)) / (2*a_val)
            x2 = (-b_val - sqrt(discriminant)) / (2*a_val)
            
            correct_solutions = [simplify(x1), simplify(x2)]
            
            # Check claimed solutions
            results = []
            for claimed in claimed_solutions:
                claimed_val = self.parse_expression(claimed)
                is_correct = any(
                    simplify(sol - claimed_val) == 0 
                    for sol in correct_solutions
                )
                results.append({
                    'claimed': claimed,
                    'is_correct': is_correct
                })
            
            all_correct = all(r['is_correct'] for r in results)
            
            return {
                'verified': True,
                'a': str(a), 'b': str(b), 'c': str(c),
                'discriminant': str(simplify(discriminant)),
                'correct_solutions': [str(s) for s in correct_solutions],
                'verification': results,
                'all_correct': all_correct
            }
            
        except Exception as e:
            return {'verified': False, 'error': str(e)}


def verify_solution_steps(problem_text: str, solution_text: str) -> List[Dict[str, Any]]:
    """
    Analyze an AI-generated solution and verify key calculations.
    Returns a list of verification results for detected calculations.
    """
    verifier = MathVerifier()
    verifications = []
    
    # Pattern for detecting calculations
    patterns = [
        # Simple arithmetic: "2 + 3 = 5"
        (r'(\d+(?:\.\d+)?)\s*([+\-*/×÷])\s*(\d+(?:\.\d+)?)\s*=\s*(\d+(?:\.\d+)?)', 'arithmetic'),
        # Variable assignments: "x = 5"
        (r'([a-zA-Z])\s*=\s*([\d\.\-]+)', 'assignment'),
        # Equations solved: "x = (-5 + 7) / 4 = 0.5"
        (r'([a-zA-Z])\s*=\s*([^=]+)\s*=\s*([\d\.\-]+)', 'equation_result'),
    ]
    
    for pattern, pattern_type in patterns:
        matches = re.finditer(pattern, solution_text)
        
        for match in matches:
            if pattern_type == 'arithmetic':
                a, op, b, result = match.groups()
                
                # Map operators
                op_map = {'+': '+', '-': '-', '*': '*', '/': '/', '×': '*', '÷': '/'}
                safe_op = op_map.get(op, op)
                
                verification = verifier.verify_arithmetic(
                    f"{a} {safe_op} {b}",
                    result
                )
                verification['match'] = match.group(0)
                verification['type'] = 'arithmetic'
                verifications.append(verification)
            
            elif pattern_type == 'equation_result':
                var, expression, result = match.groups()
                verification = verifier.verify_arithmetic(expression.strip(), result)
                verification['match'] = match.group(0)
                verification['type'] = 'equation_result'
                verifications.append(verification)
    
    return verifications


def create_verification_report(verifications: List[Dict[str, Any]]) -> str:
    """
    Create a human-readable verification report.
    """
    if not verifications:
        return "No calculations detected for verification."
    
    report = ["## Calculation Verification Report\n"]
    
    correct_count = sum(1 for v in verifications if v.get('is_correct', False))
    total_count = len(verifications)
    
    report.append(f"**Result: {correct_count}/{total_count} calculations verified correct**\n")
    
    for i, v in enumerate(verifications, 1):
        status = "✓" if v.get('is_correct', False) else "✗"
        report.append(f"\n{i}. {status} `{v.get('match', v.get('expression', 'N/A'))}`")
        
        if not v.get('is_correct', True):
            if v.get('error'):
                report.append(f"   - Error: {v['error']}")
            if v.get('actual'):
                report.append(f"   - Expected: {v['actual']}")
    
    return "\n".join(report)


# Example usage and testing
if __name__ == "__main__":
    verifier = MathVerifier()
    
    print("=== Math Verifier Test ===\n")
    
    # Test arithmetic
    print("1. Arithmetic Verification:")
    result = verifier.verify_arithmetic("2 + 3 * 4", "14")
    print(f"   2 + 3 * 4 = 14: {result['is_correct']}")
    
    result = verifier.verify_arithmetic("2 + 3 * 4", "20")
    print(f"   2 + 3 * 4 = 20: {result['is_correct']} (Error: {result.get('error', 'N/A')})")
    
    # Test equation solving
    print("\n2. Equation Verification:")
    result = verifier.verify_equation_solution("2x + 5 = 13", "x", "4")
    print(f"   2x + 5 = 13, x = 4: {result['is_correct']}")
    
    # Test derivative
    print("\n3. Derivative Verification:")
    result = verifier.verify_derivative("x^3", "x", "3x^2")
    print(f"   d/dx[x³] = 3x²: {result['is_correct']}")
    
    # Test integral
    print("\n4. Integral Verification:")
    result = verifier.verify_integral("2x", "x", "x^2")
    print(f"   ∫2x dx = x²: {result['is_correct']}")
    
    # Test expression evaluation
    print("\n5. Expression Evaluation:")
    result = verifier.evaluate_expression("x^2 + 2*x + 1", x=3)
    print(f"   x² + 2x + 1 at x=3: {result['result']}")
    
    # Test quadratic formula
    print("\n6. Quadratic Formula:")
    result = verifier.check_quadratic_formula("1", "-5", "6", ["2", "3"])
    print(f"   x² - 5x + 6 = 0, solutions [2, 3]: {result['all_correct']}")
    
    print("\n=== All tests completed ===")


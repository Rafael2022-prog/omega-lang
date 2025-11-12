#!/usr/bin/env python3
"""
OMEGA Security Scanner - Vulnerability Detection
Identifies common smart contract vulnerabilities in OMEGA code
"""

import re
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional, Set
from dataclasses import dataclass
from enum import Enum

class VulnerabilitySeverity(Enum):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"
    INFO = "INFO"

@dataclass
class Vulnerability:
    """Security vulnerability finding"""
    rule_id: str
    title: str
    description: str
    severity: VulnerabilitySeverity
    line_number: int
    code_snippet: str
    recommendation: str
    references: List[str]

class SecurityRule:
    """Base class for security rules"""
    
    def __init__(self, rule_id: str, title: str, severity: VulnerabilitySeverity):
        self.rule_id = rule_id
        self.title = title
        self.severity = severity
    
    def check(self, content: str, file_path: Path) -> List[Vulnerability]:
        """Check for vulnerabilities in content"""
        raise NotImplementedError

class ReentrancyRule(SecurityRule):
    """Detect potential reentrancy vulnerabilities"""
    
    def __init__(self):
        super().__init__(
            "OMEGA-001",
            "Potential Reentrancy Vulnerability",
            VulnerabilitySeverity.HIGH
        )
    
    def check(self, content: str, file_path: Path) -> List[Vulnerability]:
        vulnerabilities = []
        lines = content.split('\n')
        
        # Patterns that might indicate reentrancy risk
        dangerous_patterns = [
            r'\.call\s*\(',
            r'\.transfer\s*\(',
            r'\.send\s*\(',
            r'external_call',
            r'reentrant'
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern in dangerous_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    vulnerabilities.append(Vulnerability(
                        rule_id=self.rule_id,
                        title=self.title,
                        description="External calls detected without reentrancy protection",
                        severity=self.severity,
                        line_number=i,
                        code_snippet=line.strip(),
                        recommendation="Use reentrancy guards or checks-effects-interactions pattern",
                        references=[
                            "https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/",
                            "https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html"
                        ]
                    ))
        
        return vulnerabilities

class IntegerOverflowRule(SecurityRule):
    """Detect potential integer overflow issues"""
    
    def __init__(self):
        super().__init__(
            "OMEGA-002",
            "Potential Integer Overflow",
            VulnerabilitySeverity.HIGH
        )
    
    def check(self, content: str, file_path: Path) -> List[Vulnerability]:
        vulnerabilities = []
        lines = content.split('\n')
        
        # Look for arithmetic operations without overflow protection
        arithmetic_patterns = [
            r'\+\s*=',
            r'-\s*=',
            r'\*\s*=',
            r'/\s*=',
            r'\+\s*[^=]',
            r'-\s*[^=]',
            r'\*\s*[^=]',
            r'/\s*[^=]'
        ]
        
        # Look for unsafe types
        unsafe_types = ['uint256', 'int256', 'uint', 'int']
        
        for i, line in enumerate(lines, 1):
            # Check for arithmetic operations
            for pattern in arithmetic_patterns:
                if re.search(pattern, line):
                    # Check if it's protected with SafeMath or similar
                    if not any(protected in line for protected in ['safe', 'checked', 'unchecked']):
                        vulnerabilities.append(Vulnerability(
                            rule_id=self.rule_id,
                            title=self.title,
                            description="Arithmetic operation without overflow protection",
                            severity=self.severity,
                            line_number=i,
                            code_snippet=line.strip(),
                            recommendation="Use safe math libraries or explicit overflow checks",
                            references=[
                                "https://consensys.github.io/smart-contract-best-practices/known_attacks/",
                                "https://docs.openzeppelin.com/contracts/3.x/api/math"
                            ]
                        ))
        
        return vulnerabilities

class AccessControlRule(SecurityRule):
    """Detect missing access control mechanisms"""
    
    def __init__(self):
        super().__init__(
            "OMEGA-003",
            "Missing Access Control",
            VulnerabilitySeverity.CRITICAL
        )
    
    def check(self, content: str, file_path: Path) -> List[Vulnerability]:
        vulnerabilities = []
        lines = content.split('\n')
        
        # Look for state-changing functions
        state_changing_patterns = [
            r'function\s+\w+\s*\([^)]*\)\s*(public|external)',
            r'function\s+\w+\s*\([^)]*\)\s*returns'
        ]
        
        # Look for access control patterns
        access_control_patterns = [
            'onlyOwner',
            'require',
            'modifier',
            'access_control',
            'auth',
            'permission'
        ]
        
        has_access_control = any(
            pattern in content.lower() 
            for pattern in access_control_patterns
        )
        
        if not has_access_control:
            for i, line in enumerate(lines, 1):
                for pattern in state_changing_patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        vulnerabilities.append(Vulnerability(
                            rule_id=self.rule_id,
                            title=self.title,
                            description="State-changing function without access control",
                            severity=self.severity,
                            line_number=i,
                            code_snippet=line.strip(),
                            recommendation="Implement access control modifiers (onlyOwner, roles, etc.)",
                            references=[
                                "https://consensys.github.io/smart-contract-best-practices/access-control/",
                                "https://docs.openzeppelin.com/contracts/3.x/access-control"
                            ]
                        ))
        
        return vulnerabilities

class UncheckedExternalCallRule(SecurityRule):
    """Detect unchecked external calls"""
    
    def __init__(self):
        super().__init__(
            "OMEGA-004",
            "Unchecked External Call",
            VulnerabilitySeverity.MEDIUM
        )
    
    def check(self, content: str, file_path: Path) -> List[Vulnerability]:
        vulnerabilities = []
        lines = content.split('\n')
        
        # Look for external calls
        external_call_patterns = [
            r'\.call\s*\(',
            r'\.delegatecall\s*\(',
            r'\.staticcall\s*\('
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern in external_call_patterns:
                if re.search(pattern, line):
                    # Check if return value is handled
                    if not any(check in line for check in ['require', 'assert', 'if']):
                        vulnerabilities.append(Vulnerability(
                            rule_id=self.rule_id,
                            title=self.title,
                            description="External call without return value checking",
                            severity=self.severity,
                            line_number=i,
                            code_snippet=line.strip(),
                            recommendation="Always check return values of external calls",
                            references=[
                                "https://consensys.github.io/smart-contract-best-practices/development-recommendations/",
                                "https://solidity.readthedocs.io/en/v0.8.0/control-structures.html"
                            ]
                        ))
        
        return vulnerabilities

class TimestampDependenceRule(SecurityRule):
    """Detect timestamp dependence vulnerabilities"""
    
    def __init__(self):
        super().__init__(
            "OMEGA-005",
            "Timestamp Dependence",
            VulnerabilitySeverity.MEDIUM
        )
    
    def check(self, content: str, file_path: Path) -> List[Vulnerability]:
        vulnerabilities = []
        lines = content.split('\n')
        
        # Look for timestamp usage
        timestamp_patterns = [
            r'block\.timestamp',
            r'now',
            r'timestamp'
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern in timestamp_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    vulnerabilities.append(Vulnerability(
                        rule_id=self.rule_id,
                        title=self.title,
                        description="Usage of timestamp for critical logic",
                        severity=self.severity,
                        line_number=i,
                        code_snippet=line.strip(),
                        recommendation="Avoid using timestamp for critical logic; use block.number instead",
                        references=[
                            "https://consensys.github.io/smart-contract-best-practices/development-recommendations/",
                            "https://ethereum.stackexchange.com/questions/5924/how-do-ethereum-mining-nodes-miners-validate-the-timestamp-of-a-block"
                        ]
                    ))
        
        return vulnerabilities

class OmegaSecurityScanner:
    """OMEGA Security Scanner - Main scanner class"""
    
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.rules: List[SecurityRule] = [
            ReentrancyRule(),
            IntegerOverflowRule(),
            AccessControlRule(),
            UncheckedExternalCallRule(),
            TimestampDependenceRule()
        ]
        
        # Setup logging
        log_level = logging.DEBUG if verbose else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def scan_file(self, file_path: Path) -> List[Vulnerability]:
        """Scan a single OMEGA file for vulnerabilities"""
        self.logger.info(f"Scanning file: {file_path}")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            vulnerabilities = []
            
            # Run all security rules
            for rule in self.rules:
                rule_vulnerabilities = rule.check(content, file_path)
                vulnerabilities.extend(rule_vulnerabilities)
                
                if self.verbose and rule_vulnerabilities:
                    self.logger.debug(f"Rule {rule.rule_id} found {len(rule_vulnerabilities)} issues")
            
            return vulnerabilities
            
        except Exception as e:
            self.logger.error(f"Error scanning file {file_path}: {e}")
            return []
    
    def scan_directory(self, directory: Path, pattern: str = "*.omega") -> Dict[str, List[Vulnerability]]:
        """Scan all OMEGA files in a directory"""
        self.logger.info(f"Scanning directory: {directory}")
        
        results = {}
        
        try:
            omega_files = list(directory.rglob(pattern))
            self.logger.info(f"Found {len(omega_files)} OMEGA files")
            
            for file_path in omega_files:
                vulnerabilities = self.scan_file(file_path)
                if vulnerabilities:
                    results[str(file_path)] = vulnerabilities
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error scanning directory {directory}: {e}")
            return {}
    
    def generate_report(self, scan_results: Dict[str, List[Vulnerability]]) -> Dict[str, any]:
        """Generate comprehensive security report"""
        total_vulnerabilities = sum(len(vulns) for vulns in scan_results.values())
        
        # Group by severity
        severity_counts = {
            'CRITICAL': 0,
            'HIGH': 0,
            'MEDIUM': 0,
            'LOW': 0,
            'INFO': 0
        }
        
        # Group by rule
        rule_counts = {}
        
        for file_path, vulnerabilities in scan_results.items():
            for vuln in vulnerabilities:
                severity_counts[vuln.severity.value] += 1
                
                if vuln.rule_id not in rule_counts:
                    rule_counts[vuln.rule_id] = 0
                rule_counts[vuln.rule_id] += 1
        
        # Calculate risk score
        risk_weights = {
            'CRITICAL': 10,
            'HIGH': 7,
            'MEDIUM': 4,
            'LOW': 1,
            'INFO': 0
        }
        
        risk_score = sum(risk_weights[sev] * count for sev, count in severity_counts.items())
        
        return {
            'summary': {
                'total_files_scanned': len(scan_results),
                'total_vulnerabilities': total_vulnerabilities,
                'severity_breakdown': severity_counts,
                'rule_breakdown': rule_counts,
                'risk_score': risk_score,
                'risk_level': self._get_risk_level(risk_score)
            },
            'recommendations': self._generate_recommendations(severity_counts),
            'detailed_findings': {
                file_path: [
                    {
                        'rule_id': vuln.rule_id,
                        'title': vuln.title,
                        'description': vuln.description,
                        'severity': vuln.severity.value,
                        'line_number': vuln.line_number,
                        'code_snippet': vuln.code_snippet,
                        'recommendation': vuln.recommendation,
                        'references': vuln.references
                    }
                    for vuln in vulnerabilities
                ]
                for file_path, vulnerabilities in scan_results.items()
            }
        }
    
    def _get_risk_level(self, risk_score: int) -> str:
        """Determine risk level based on score"""
        if risk_score >= 50:
            return "CRITICAL"
        elif risk_score >= 25:
            return "HIGH"
        elif risk_score >= 10:
            return "MEDIUM"
        elif risk_score >= 1:
            return "LOW"
        else:
            return "INFO"
    
    def _generate_recommendations(self, severity_counts: Dict[str, int]) -> List[str]:
        """Generate security recommendations based on findings"""
        recommendations = []
        
        if severity_counts['CRITICAL'] > 0:
            recommendations.append("🚨 Address CRITICAL vulnerabilities immediately before deployment")
        
        if severity_counts['HIGH'] > 0:
            recommendations.append("⚠️  Fix HIGH severity vulnerabilities before mainnet deployment")
        
        if severity_counts['MEDIUM'] > 0:
            recommendations.append("🔍 Review MEDIUM severity issues and fix based on risk assessment")
        
        if severity_counts['CRITICAL'] + severity_counts['HIGH'] > 5:
            recommendations.append("📋 Conduct comprehensive security audit before production")
        
        if not recommendations:
            recommendations.append("✅ No significant security issues found - maintain secure coding practices")
        
        return recommendations
    
    def save_report(self, report: Dict[str, any], output_file: str):
        """Save security report to file"""
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
        self.logger.info(f"Security report saved to: {output_file}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='OMEGA Security Scanner')
    parser.add_argument('path', help='File or directory to scan')
    parser.add_argument('--pattern', default='*.omega', help='File pattern for directory scanning')
    parser.add_argument('--output', default='security-report.json', help='Output report file')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Initialize scanner
    scanner = OmegaSecurityScanner(verbose=args.verbose)
    
    # Determine if path is file or directory
    path = Path(args.path)
    
    if not path.exists():
        print(f"Error: Path not found: {args.path}")
        return 1
    
    # Run scan
    if path.is_file():
        vulnerabilities = scanner.scan_file(path)
        scan_results = {str(path): vulnerabilities} if vulnerabilities else {}
    else:
        scan_results = scanner.scan_directory(path, args.pattern)
    
    # Generate and save report
    report = scanner.generate_report(scan_results)
    scanner.save_report(report, args.output)
    
    # Print summary
    summary = report['summary']
    print(f"\n🔒 Security Scan Summary:")
    print(f"Files scanned: {summary['total_files_scanned']}")
    print(f"Vulnerabilities found: {summary['total_vulnerabilities']}")
    print(f"Risk level: {summary['risk_level']}")
    print(f"Risk score: {summary['risk_score']}")
    
    if summary['total_vulnerabilities'] > 0:
        print(f"\nSeverity breakdown:")
        for severity, count in summary['severity_breakdown'].items():
            if count > 0:
                print(f"  {severity}: {count}")
    
    print(f"\n📋 Recommendations:")
    for rec in report['recommendations']:
        print(f"  {rec}")
    
    return 0 if summary['risk_level'] in ['LOW', 'INFO'] else 1

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='OMEGA Security Scanner')
    parser.add_argument('target', help='File or directory to scan')
    parser.add_argument('--output', '-o', help='Output file for report')
    parser.add_argument('--recursive', '-r', action='store_true', help='Scan directories recursively')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--stats', action='store_true', help='Show statistics')
    
    args = parser.parse_args()
    
    try:
        scanner = OmegaSecurityScanner(verbose=args.verbose)
        target_path = Path(args.target)
        
        if target_path.is_file():
            vulnerabilities = scanner.scan_file(target_path)
            scan_results = {str(target_path): vulnerabilities}
        else:
            scan_results = scanner.scan_directory(target_path, recursive=args.recursive)
        
        # Generate report
        report = scanner.generate_report(scan_results, args.output)
        print(report)
        
        # Show statistics if requested
        if args.stats:
            stats = scanner.get_statistics(scan_results)
            print("\n" + "=" * 50)
            print("SCAN STATISTICS")
            print("=" * 50)
            print(f"Files with vulnerabilities: {stats['files_with_vulnerabilities']}/{stats['total_files']}")
            print(f"Total vulnerabilities: {stats['total_vulnerabilities']}")
            print("Severity breakdown:")
            for severity, count in stats['severity_breakdown'].items():
                print(f"  {severity}: {count}")
            print("Most common vulnerabilities:")
            for rule_id, count in stats['most_common_vulnerabilities'].items():
                print(f"  {rule_id}: {count}")
        
        # Return appropriate exit code
        total_vulnerabilities = sum(len(vulns) for vulns in scan_results.values())
        critical_count = sum(
            1 for vulns in scan_results.values() 
            for vuln in vulns 
            if vuln.severity == VulnerabilitySeverity.CRITICAL
        )
        
        if critical_count > 0:
            return 2  # Critical vulnerabilities found
        elif total_vulnerabilities > 0:
            return 1  # Non-critical vulnerabilities found
        else:
            return 0  # No vulnerabilities found
            
    except Exception as e:
        print(f"Scanner error: {e}")
        return 1

if __name__ == '__main__':
    import sys
    sys.exit(main())
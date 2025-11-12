#!/usr/bin/env python3
"""
OMEGA Audit Framework - Comprehensive Security Audit Tool
Performs automated security audits with detailed vulnerability analysis
"""

import os
import sys
import json
import time
import hashlib
import logging
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
from enum import Enum

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))
from security_scanner import OmegaSecurityScanner, VulnerabilitySeverity

class AuditLevel(Enum):
    """Audit severity levels"""
    BASIC = "BASIC"
    STANDARD = "STANDARD"
    COMPREHENSIVE = "COMPREHENSIVE"
    CRITICAL = "CRITICAL"

class AuditStatus(Enum):
    """Audit status"""
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

@dataclass
class AuditFinding:
    """Individual audit finding"""
    finding_id: str
    title: str
    description: str
    severity: VulnerabilitySeverity
    category: str
    line_number: int
    code_snippet: str
    recommendation: str
    references: List[str]
    confidence: float  # 0.0 to 1.0
    automated: bool
    manual_review_required: bool

@dataclass
class AuditMetric:
    """Audit metrics"""
    total_lines: int
    complexity_score: float
    security_score: float
    gas_efficiency_score: float
    code_quality_score: float
    test_coverage_score: float
    documentation_score: float

@dataclass
class AuditReport:
    """Complete audit report"""
    audit_id: str
    project_name: str
    audit_level: AuditLevel
    status: AuditStatus
    start_time: str
    end_time: Optional[str]
    duration: Optional[float]
    findings: List[AuditFinding]
    metrics: Optional[AuditMetric]
    recommendations: List[str]
    risk_assessment: Dict[str, Any]
    auditor_notes: Optional[str]
    next_audit_date: Optional[str]

class OmegaAuditFramework:
    """OMEGA Comprehensive Audit Framework"""
    
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.audit_id = self._generate_audit_id()
        
        # Setup logging
        self._setup_logging()
        
        # Initialize security scanner
        self.security_scanner = OmegaSecurityScanner(verbose=verbose)
        
        # Audit rules and patterns
        self.audit_rules = self._initialize_audit_rules()
        
        self.logger.info(f"OMEGA Audit Framework initialized (ID: {self.audit_id})")
    
    def _generate_audit_id(self) -> str:
        """Generate unique audit ID"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        random_suffix = hashlib.md5(str(time.time()).encode()).hexdigest()[:6]
        return f"AUDIT_{timestamp}_{random_suffix}"
    
    def _setup_logging(self):
        """Setup logging configuration"""
        log_level = logging.DEBUG if self.verbose else logging.INFO
        
        # Create audit logs directory
        log_dir = Path(__file__).parent / "audit_logs"
        log_dir.mkdir(exist_ok=True)
        
        # Setup file handler
        log_file = log_dir / f"audit_{self.audit_id}.log"
        
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        
        self.logger = logging.getLogger(__name__)
    
    def _initialize_audit_rules(self) -> List[Any]:
        """Initialize comprehensive audit rules"""
        rules = []
        
        # Security rules (already implemented in security_scanner)
        # Additional audit-specific rules would go here
        
        return rules
    
    def analyze_complexity(self, content: str) -> float:
        """Analyze code complexity"""
        lines = content.split('\n')
        
        complexity_factors = {
            'cyclomatic': 0,  # Control flow complexity
            'cognitive': 0,   # Cognitive complexity
            'nesting_depth': 0,
            'function_count': 0,
            'state_variables': 0,
            'external_calls': 0
        }
        
        # Count complexity indicators
        for line in lines:
            line = line.strip()
            
            # Control flow statements
            if any(keyword in line for keyword in ['if', 'else', 'while', 'for', 'switch']):
                complexity_factors['cyclomatic'] += 1
            
            # Function definitions
            if 'function' in line and '(' in line:
                complexity_factors['function_count'] += 1
            
            # State variables
            if any(keyword in line for keyword in ['mapping', 'uint', 'int', 'bool', 'address']):
                if '=' in line:  # Variable declaration
                    complexity_factors['state_variables'] += 1
            
            # External calls
            if any(keyword in line for keyword in ['call', 'delegatecall', 'transfer']):
                complexity_factors['external_calls'] += 1
        
        # Calculate complexity score (0-100)
        base_score = (
            complexity_factors['cyclomatic'] * 2 +
            complexity_factors['function_count'] * 3 +
            complexity_factors['state_variables'] * 1 +
            complexity_factors['external_calls'] * 5
        )
        
        # Normalize to 0-100 scale
        complexity_score = min(base_score / max(len(lines), 1) * 10, 100)
        
        return complexity_score
    
    def analyze_gas_efficiency(self, content: str) -> float:
        """Analyze gas efficiency patterns"""
        lines = content.split('\n')
        
        gas_issues = {
            'storage_operations': 0,
            'loop_operations': 0,
            'external_calls': 0,
            'complex_math': 0,
            'string_operations': 0
        }
        
        for line in lines:
            line = line.strip()
            
            # Storage operations (expensive)
            if any(op in line for op in ['storage', 'mapping', '.push', '.pop']):
                gas_issues['storage_operations'] += 1
            
            # Loop operations
            if 'for' in line or 'while' in line:
                gas_issues['loop_operations'] += 1
            
            # External calls
            if any(call in line for call in ['.call', '.transfer', '.send']):
                gas_issues['external_calls'] += 1
            
            # Complex math operations
            if any(op in line for op in ['**', 'exp', 'log', 'sqrt']):
                gas_issues['complex_math'] += 1
            
            # String operations
            if any(op in line for op in ['string', 'concat', 'substring']):
                gas_issues['string_operations'] += 1
        
        # Calculate efficiency score (higher is better)
        total_issues = sum(gas_issues.values())
        efficiency_score = max(0, 100 - (total_issues * 5))
        
        return efficiency_score
    
    def analyze_code_quality(self, content: str) -> float:
        """Analyze code quality patterns"""
        lines = content.split('\n')
        
        quality_metrics = {
            'documentation': 0,  # Comments and documentation
            'naming_conventions': 0,
            'error_handling': 0,
            'modularity': 0,
            'security_patterns': 0
        }
        
        for line in lines:
            line = line.strip()
            
            # Documentation
            if line.startswith('//') or line.startswith('/*'):
                quality_metrics['documentation'] += 1
            
            # Naming conventions (simple heuristic)
            if 'function' in line and '_' in line:
                quality_metrics['naming_conventions'] += 1
            
            # Error handling
            if any(keyword in line for keyword in ['require', 'assert', 'revert']):
                quality_metrics['error_handling'] += 1
            
            # Modularity (function definitions)
            if 'function' in line and '(' in line:
                quality_metrics['modularity'] += 1
            
            # Security patterns
            if any(pattern in line for pattern in ['onlyOwner', 'modifier', 'access']):
                quality_metrics['security_patterns'] += 1
        
        # Calculate quality score
        total_lines = len(lines)
        if total_lines == 0:
            return 0
        
        quality_score = (
            (quality_metrics['documentation'] / total_lines * 30) +
            (quality_metrics['error_handling'] / total_lines * 40) +
            (quality_metrics['security_patterns'] / max(quality_metrics['modularity'], 1) * 30)
        )
        
        return min(quality_score, 100)
    
    def perform_security_audit(self, file_path: Path) -> List[AuditFinding]:
        """Perform comprehensive security audit"""
        self.logger.info(f"Performing security audit: {file_path}")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Run automated security scan
            vulnerabilities = self.security_scanner.scan_file(file_path)
            
            findings = []
            
            # Convert vulnerabilities to audit findings
            for vuln in vulnerabilities:
                finding = AuditFinding(
                    finding_id=f"SEC-{vuln.rule_id}",
                    title=vuln.title,
                    description=vuln.description,
                    severity=vuln.severity,
                    category="SECURITY",
                    line_number=vuln.line_number,
                    code_snippet=vuln.code_snippet,
                    recommendation=vuln.recommendation,
                    references=vuln.references,
                    confidence=0.8,  # High confidence for automated rules
                    automated=True,
                    manual_review_required=(vuln.severity == VulnerabilitySeverity.CRITICAL)
                )
                findings.append(finding)
            
            return findings
            
        except Exception as e:
            self.logger.error(f"Security audit error: {e}")
            return []
    
    def perform_comprehensive_audit(self, project_path: Path, audit_level: AuditLevel = AuditLevel.STANDARD) -> AuditReport:
        """Perform comprehensive audit of OMEGA project"""
        self.logger.info(f"Starting comprehensive audit: {project_path} (Level: {audit_level.value})")
        
        start_time = datetime.now()
        
        try:
            # Find all OMEGA files
            omega_files = list(project_path.rglob("*.omega"))
            
            if not omega_files:
                self.logger.warning("No OMEGA files found for audit")
                return self._create_empty_audit_report(project_path, audit_level, start_time)
            
            all_findings = []
            total_metrics = {
                'lines': 0,
                'complexity': [],
                'gas_efficiency': [],
                'quality': []
            }
            
            # Audit each file
            for omega_file in omega_files:
                self.logger.info(f"Auditing file: {omega_file}")
                
                # Read file content
                with open(omega_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Update metrics
                total_metrics['lines'] += len(content.split('\n'))
                total_metrics['complexity'].append(self.analyze_complexity(content))
                total_metrics['gas_efficiency'].append(self.analyze_gas_efficiency(content))
                total_metrics['quality'].append(self.analyze_code_quality(content))
                
                # Perform security audit
                security_findings = self.perform_security_audit(omega_file)
                all_findings.extend(security_findings)
                
                # Additional audits based on level
                if audit_level in [AuditLevel.COMPREHENSIVE, AuditLevel.CRITICAL]:
                    # Additional comprehensive checks would go here
                    pass
            
            # Calculate aggregate metrics
            metrics = AuditMetric(
                total_lines=total_metrics['lines'],
                complexity_score=sum(total_metrics['complexity']) / len(total_metrics['complexity']),
                security_score=self._calculate_security_score(all_findings),
                gas_efficiency_score=sum(total_metrics['gas_efficiency']) / len(total_metrics['gas_efficiency']),
                code_quality_score=sum(total_metrics['quality']) / len(total_metrics['quality']),
                test_coverage_score=0,  # Would need test data
                documentation_score=self._calculate_documentation_score(project_path)
            )
            
            # Generate recommendations
            recommendations = self._generate_audit_recommendations(all_findings, metrics)
            
            # Risk assessment
            risk_assessment = self._perform_risk_assessment(all_findings, metrics)
            
            # Create final report
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds() / 60  # minutes
            
            report = AuditReport(
                audit_id=self.audit_id,
                project_name=project_path.name,
                audit_level=audit_level,
                status=AuditStatus.COMPLETED,
                start_time=start_time.isoformat(),
                end_time=end_time.isoformat(),
                duration=duration,
                findings=all_findings,
                metrics=metrics,
                recommendations=recommendations,
                risk_assessment=risk_assessment,
                auditor_notes=None,
                next_audit_date=(end_time.replace(year=end_time.year + 1)).isoformat()
            )
            
            self.logger.info(f"Audit completed: {len(all_findings)} findings, duration: {duration:.1f} minutes")
            
            return report
            
        except Exception as e:
            self.logger.error(f"Comprehensive audit error: {e}")
            return self._create_error_audit_report(project_path, audit_level, start_time, str(e))
    
    def _calculate_security_score(self, findings: List[AuditFinding]) -> float:
        """Calculate security score based on findings"""
        if not findings:
            return 100.0
        
        severity_weights = {
            VulnerabilitySeverity.CRITICAL: 25,
            VulnerabilitySeverity.HIGH: 15,
            VulnerabilitySeverity.MEDIUM: 5,
            VulnerabilitySeverity.LOW: 2,
            VulnerabilitySeverity.INFO: 0
        }
        
        total_penalty = 0
        for finding in findings:
            total_penalty += severity_weights.get(finding.severity, 0)
        
        security_score = max(0, 100 - total_penalty)
        return security_score
    
    def _calculate_documentation_score(self, project_path: Path) -> float:
        """Calculate documentation score"""
        # Look for documentation files
        doc_files = list(project_path.rglob("*.md")) + list(project_path.rglob("*.txt"))
        
        # Check for specific documentation
        has_readme = any(f.name.lower().startswith('readme') for f in doc_files)
        has_api_docs = any('api' in f.name.lower() for f in doc_files)
        has_security_docs = any('security' in f.name.lower() for f in doc_files)
        
        score = 0
        if has_readme:
            score += 40
        if has_api_docs:
            score += 30
        if has_security_docs:
            score += 30
        
        return score
    
    def _perform_risk_assessment(self, findings: List[AuditFinding], metrics: AuditMetric) -> Dict[str, Any]:
        """Perform comprehensive risk assessment"""
        # Count findings by severity
        severity_counts = {}
        for severity in VulnerabilitySeverity:
            severity_counts[severity.value] = sum(
                1 for f in findings if f.severity == severity
            )
        
        # Calculate overall risk level
        risk_score = (
            severity_counts['CRITICAL'] * 10 +
            severity_counts['HIGH'] * 7 +
            severity_counts['MEDIUM'] * 3 +
            severity_counts['LOW'] * 1
        )
        
        if risk_score >= 50:
            risk_level = "CRITICAL"
        elif risk_score >= 25:
            risk_level = "HIGH"
        elif risk_score >= 10:
            risk_level = "MEDIUM"
        else:
            risk_level = "LOW"
        
        return {
            'risk_level': risk_level,
            'risk_score': risk_score,
            'severity_breakdown': severity_counts,
            'recommendation': self._get_risk_recommendation(risk_level),
            'deployment_recommendation': self._get_deployment_recommendation(risk_level, metrics)
        }
    
    def _get_risk_recommendation(self, risk_level: str) -> str:
        """Get risk-based recommendation"""
        recommendations = {
            'CRITICAL': 'DO NOT DEPLOY - Address all critical and high severity issues',
            'HIGH': 'Major security review required - Fix critical issues before deployment',
            'MEDIUM': 'Security improvements recommended - Review and fix medium severity issues',
            'LOW': 'Minor security enhancements suggested - Monitor and improve over time'
        }
        
        return recommendations.get(risk_level, 'Unknown risk level')
    
    def _get_deployment_recommendation(self, risk_level: str, metrics: AuditMetric) -> str:
        """Get deployment recommendation based on risk and metrics"""
        if risk_level in ['CRITICAL', 'HIGH']:
            return 'DEPLOYMENT NOT RECOMMENDED'
        
        if metrics.security_score < 70:
            return 'DEPLOYMENT RISKY - Security score below recommended threshold'
        
        if metrics.complexity_score > 80:
            return 'DEPLOYMENT WITH CAUTION - High complexity may introduce risks'
        
        return 'DEPLOYMENT ACCEPTABLE - Monitor and maintain security practices'
    
    def _generate_audit_recommendations(self, findings: List[AuditFinding], metrics: AuditMetric) -> List[str]:
        """Generate audit recommendations"""
        recommendations = []
        
        # Security-based recommendations
        critical_count = sum(1 for f in findings if f.severity == VulnerabilitySeverity.CRITICAL)
        high_count = sum(1 for f in findings if f.severity == VulnerabilitySeverity.HIGH)
        
        if critical_count > 0:
            recommendations.append("🚨 Address all CRITICAL vulnerabilities before deployment")
        
        if high_count > 0:
            recommendations.append("⚠️  Fix HIGH severity vulnerabilities in next release")
        
        if metrics.security_score < 80:
            recommendations.append("🔒 Improve security practices and patterns")
        
        if metrics.complexity_score > 70:
            recommendations.append("📊 Reduce code complexity to improve maintainability")
        
        if metrics.gas_efficiency_score < 60:
            recommendations.append("⛽ Optimize gas usage for better cost efficiency")
        
        if metrics.code_quality_score < 70:
            recommendations.append("📝 Improve code quality and documentation")
        
        if not recommendations:
            recommendations.append("✅ Good security posture - maintain current practices")
        
        return recommendations
    
    def _create_empty_audit_report(self, project_path: Path, audit_level: AuditLevel, start_time: datetime) -> AuditReport:
        """Create empty audit report when no files found"""
        return AuditReport(
            audit_id=self.audit_id,
            project_name=project_path.name,
            audit_level=audit_level,
            status=AuditStatus.COMPLETED,
            start_time=start_time.isoformat(),
            end_time=datetime.now().isoformat(),
            duration=0.1,
            findings=[],
            metrics=None,
            recommendations=["No OMEGA files found for audit"],
            risk_assessment={'risk_level': 'LOW', 'risk_score': 0, 'recommendation': 'No files to audit'},
            auditor_notes="No OMEGA contract files were found in the specified project directory",
            next_audit_date=None
        )
    
    def _create_error_audit_report(self, project_path: Path, audit_level: AuditLevel, start_time: datetime, error: str) -> AuditReport:
        """Create error audit report"""
        return AuditReport(
            audit_id=self.audit_id,
            project_name=project_path.name,
            audit_level=audit_level,
            status=AuditStatus.FAILED,
            start_time=start_time.isoformat(),
            end_time=datetime.now().isoformat(),
            duration=(datetime.now() - start_time).total_seconds() / 60,
            findings=[],
            metrics=None,
            recommendations=["Audit failed due to technical error"],
            risk_assessment={'risk_level': 'UNKNOWN', 'risk_score': -1, 'recommendation': 'Audit could not be completed'},
            auditor_notes=f"Audit failed with error: {error}",
            next_audit_date=None
        )
    
    def save_audit_report(self, report: AuditReport, output_dir: Optional[str] = None) -> str:
        """Save audit report to file"""
        if not output_dir:
            output_dir = Path(__file__).parent / "audit_reports"
        else:
            output_dir = Path(output_dir)
        
        output_dir.mkdir(exist_ok=True)
        
        # Save JSON report
        json_file = output_dir / f"audit_report_{report.audit_id}.json"
        with open(json_file, 'w') as f:
            json.dump(asdict(report), f, indent=2, default=str)
        
        # Save human-readable report
        txt_file = output_dir / f"audit_report_{report.audit_id}.txt"
        self._save_human_readable_report(report, txt_file)
        
        self.logger.info(f"Audit report saved to: {json_file}")
        
        return str(json_file)
    
    def _save_human_readable_report(self, report: AuditReport, output_file: Path):
        """Save human-readable audit report"""
        with open(output_file, 'w') as f:
            f.write("OMEGA SECURITY AUDIT REPORT\n")
            f.write("=" * 60 + "\n\n")
            
            f.write(f"Audit ID: {report.audit_id}\n")
            f.write(f"Project: {report.project_name}\n")
            f.write(f"Audit Level: {report.audit_level.value}\n")
            f.write(f"Status: {report.status.value}\n")
            f.write(f"Duration: {report.duration:.1f} minutes\n\n")
            
            if report.metrics:
                f.write("AUDIT METRICS\n")
                f.write("-" * 30 + "\n")
                f.write(f"Total Lines of Code: {report.metrics.total_lines}\n")
                f.write(f"Complexity Score: {report.metrics.complexity_score:.1f}/100\n")
                f.write(f"Security Score: {report.metrics.security_score:.1f}/100\n")
                f.write(f"Gas Efficiency Score: {report.metrics.gas_efficiency_score:.1f}/100\n")
                f.write(f"Code Quality Score: {report.metrics.code_quality_score:.1f}/100\n\n")
            
            if report.findings:
                f.write("SECURITY FINDINGS\n")
                f.write("-" * 30 + "\n")
                
                # Group by severity
                severity_groups = {}
                for finding in report.findings:
                    severity = finding.severity.value
                    if severity not in severity_groups:
                        severity_groups[severity] = []
                    severity_groups[severity].append(finding)
                
                for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO']:
                    if severity in severity_groups:
                        f.write(f"\n{severity} SEVERITY ({len(severity_groups[severity])} findings):\n")
                        for finding in severity_groups[severity]:
                            f.write(f"  • {finding.title} (Line {finding.line_number})\n")
                            f.write(f"    {finding.description}\n")
                            f.write(f"    Recommendation: {finding.recommendation}\n\n")
            
            if report.risk_assessment:
                f.write("RISK ASSESSMENT\n")
                f.write("-" * 30 + "\n")
                f.write(f"Risk Level: {report.risk_assessment['risk_level']}\n")
                f.write(f"Risk Score: {report.risk_assessment['risk_score']}\n")
                f.write(f"Recommendation: {report.risk_assessment['recommendation']}\n")
                f.write(f"Deployment: {report.risk_assessment['deployment_recommendation']}\n\n")
            
            if report.recommendations:
                f.write("AUDIT RECOMMENDATIONS\n")
                f.write("-" * 30 + "\n")
                for rec in report.recommendations:
                    f.write(f"• {rec}\n")
            
            if report.next_audit_date:
                f.write(f"\nNext Audit Recommended: {report.next_audit_date}\n")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='OMEGA Audit Framework')
    parser.add_argument('project_path', help='Path to OMEGA project')
    parser.add_argument('--level', choices=['BASIC', 'STANDARD', 'COMPREHENSIVE', 'CRITICAL'], 
                       default='STANDARD', help='Audit level')
    parser.add_argument('--output', help='Output directory for reports')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    try:
        # Initialize audit framework
        auditor = OmegaAuditFramework(verbose=args.verbose)
        
        # Perform audit
        project_path = Path(args.project_path)
        if not project_path.exists():
            print(f"Error: Project path not found: {args.project_path}")
            return 1
        
        audit_level = AuditLevel[args.level]
        report = auditor.perform_comprehensive_audit(project_path, audit_level)
        
        # Save report
        report_file = auditor.save_audit_report(report, args.output)
        
        # Print summary
        print(f"\n🔍 OMEGA Audit Summary:")
        print(f"Audit ID: {report.audit_id}")
        print(f"Project: {report.project_name}")
        print(f"Level: {report.audit_level.value}")
        print(f"Status: {report.status.value}")
        print(f"Duration: {report.duration:.1f} minutes")
        
        if report.metrics:
            print(f"Security Score: {report.metrics.security_score:.1f}/100")
            print(f"Risk Level: {report.risk_assessment['risk_level']}")
        
        if report.findings:
            print(f"Total Findings: {len(report.findings)}")
            
            # Count by severity
            severity_counts = {}
            for finding in report.findings:
                severity = finding.severity.value
                severity_counts[severity] = severity_counts.get(severity, 0) + 1
            
            print("Findings by severity:")
            for severity, count in severity_counts.items():
                print(f"  {severity}: {count}")
        
        print(f"Report saved to: {report_file}")
        
        # Return appropriate exit code
        if report.risk_assessment['risk_level'] in ['CRITICAL', 'HIGH']:
            return 1
        else:
            return 0
            
    except Exception as e:
        print(f"Audit framework error: {e}")
        return 1

if __name__ == '__main__':
    import sys
    sys.exit(main())
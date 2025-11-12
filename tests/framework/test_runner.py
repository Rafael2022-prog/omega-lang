#!/usr/bin/env python3
"""
OMEGA Test Framework - Comprehensive Testing Suite
Supports cross-platform testing, performance benchmarking, and security validation
"""

import os
import sys
import json
import time
import shutil
import logging
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))
from security_scanner import OmegaSecurityScanner

@dataclass
class TestResult:
    """Individual test result"""
    test_name: str
    status: str  # PASS, FAIL, SKIP, ERROR
    duration: float
    message: str
    output: str
    error_output: str
    metrics: Dict[str, Any]
    platform: str
    timestamp: str

@dataclass
class TestSuite:
    """Test suite configuration"""
    name: str
    description: str
    test_files: List[str]
    expected_outputs: Dict[str, Any]
    timeout: int = 30
    platforms: List[str] = None
    skip_on_failure: bool = False

class OmegaTestFramework:
    """OMEGA Comprehensive Test Framework"""
    
    def __init__(self, omega_cli_path: Optional[str] = None, verbose: bool = False):
        self.verbose = verbose
        self.platform = self._detect_platform()
        self.omega_cli = self._find_omega_cli(omega_cli_path)
        self.test_results: List[TestResult] = []
        self.start_time = None
        
        # Setup logging
        self._setup_logging()
        
        # Initialize security scanner
        self.security_scanner = OmegaSecurityScanner(verbose=verbose)
        
        self.logger.info(f"OMEGA Test Framework initialized on {self.platform}")
        self.logger.info(f"Using OMEGA CLI: {self.omega_cli}")
    
    def _detect_platform(self) -> str:
        """Detect current platform"""
        import platform
        return f"{platform.system()}-{platform.machine()}"
    
    def _find_omega_cli(self, custom_path: Optional[str] = None) -> str:
        """Find OMEGA CLI executable"""
        if custom_path and Path(custom_path).exists():
            return custom_path
        
        # Search in common locations
        search_paths = [
            Path(__file__).parent.parent.parent / "omega-cli.ps1",
            Path(__file__).parent.parent.parent / "omega-cli.sh",
            Path(__file__).parent.parent.parent / "target" / "release" / "omega",
            Path(__file__).parent.parent.parent / "target" / "debug" / "omega",
            Path.cwd() / "omega-cli.ps1",
            Path.cwd() / "omega-cli.sh",
            "omega-cli.ps1",  # Try in PATH
            "omega-cli.sh",   # Try in PATH
            "omega"           # Try in PATH
        ]
        
        for path in search_paths:
            if Path(path).exists():
                return str(path)
        
        raise RuntimeError("OMEGA CLI not found. Please specify path or install OMEGA.")
    
    def _setup_logging(self):
        """Setup logging configuration"""
        log_level = logging.DEBUG if self.verbose else logging.INFO
        
        # Create logs directory
        log_dir = Path(__file__).parent / "logs"
        log_dir.mkdir(exist_ok=True)
        
        # Setup file handler
        log_file = log_dir / f"test_framework_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        
        self.logger = logging.getLogger(__name__)
    
    def discover_tests(self, test_dir: str = "test_contracts") -> List[TestSuite]:
        """Discover test contracts and create test suites"""
        test_path = Path(__file__).parent / test_dir
        
        if not test_path.exists():
            self.logger.warning(f"Test directory not found: {test_path}")
            return []
        
        test_suites = []
        
        # Look for test contract files
        omega_files = list(test_path.rglob("*.omega"))
        
        self.logger.info(f"Found {len(omega_files)} test contracts in {test_path}")
        
        # Group by target platform if specified
        for omega_file in omega_files:
            # Try to read test configuration from JSON file
            config_file = omega_file.with_suffix('.json')
            
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = json.load(f)
                
                test_suite = TestSuite(
                    name=config.get('name', omega_file.stem),
                    description=config.get('description', f'Test suite for {omega_file.name}'),
                    test_files=[str(omega_file)],
                    expected_outputs=config.get('expected_outputs', {}),
                    timeout=config.get('timeout', 30),
                    platforms=config.get('platforms', None),
                    skip_on_failure=config.get('skip_on_failure', False)
                )
            else:
                # Create default test suite
                test_suite = TestSuite(
                    name=omega_file.stem,
                    description=f"Auto-generated test for {omega_file.name}",
                    test_files=[str(omega_file)],
                    expected_outputs={},
                    timeout=30,
                    platforms=None,
                    skip_on_failure=False
                )
            
            test_suites.append(test_suite)
        
        return test_suites
    
    def compile_contract(self, contract_path: str, target: str = "evm") -> Tuple[bool, str, str, Dict[str, Any]]:
        """Compile an OMEGA contract"""
        self.logger.info(f"Compiling {contract_path} for {target}")
        
        start_time = time.time()
        
        try:
            # Determine CLI command based on platform
            if self.platform.startswith("Windows"):
                cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", self.omega_cli, "compile", contract_path, "--target", target]
            else:
                cmd = ["bash", self.omega_cli, "compile", contract_path, "--target", target]
            
            # Run compilation
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=Path(contract_path).parent
            )
            
            duration = time.time() - start_time
            
            success = result.returncode == 0
            output = result.stdout
            error_output = result.stderr
            
            # Extract metrics from output
            metrics = self._extract_compilation_metrics(output, error_output, duration)
            
            self.logger.info(f"Compilation {'succeeded' if success else 'failed'} in {duration:.2f}s")
            
            return success, output, error_output, metrics
            
        except subprocess.TimeoutExpired:
            self.logger.error(f"Compilation timed out for {contract_path}")
            return False, "", "Compilation timed out", {'duration': time.time() - start_time}
            
        except Exception as e:
            self.logger.error(f"Compilation error for {contract_path}: {e}")
            return False, "", str(e), {'duration': time.time() - start_time}
    
    def _extract_compilation_metrics(self, output: str, error_output: str, duration: float) -> Dict[str, Any]:
        """Extract compilation metrics from output"""
        metrics = {
            'duration': duration,
            'output_size': len(output),
            'error_size': len(error_output),
            'gas_usage': None,
            'bytecode_size': None,
            'warnings': 0,
            'errors': 0
        }
        
        # Count warnings and errors
        metrics['warnings'] = output.lower().count('warning') + error_output.lower().count('warning')
        metrics['errors'] = output.lower().count('error') + error_output.lower().count('error')
        
        # Try to extract gas usage (example patterns)
        gas_patterns = [
            r'gas usage[:\s]*(\d+)',
            r'gas[:\s]*(\d+)',
            r'cost[:\s]*(\d+)'
        ]
        
        for pattern in gas_patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                metrics['gas_usage'] = int(match.group(1))
                break
        
        # Try to extract bytecode size
        size_patterns = [
            r'bytecode size[:\s]*(\d+)',
            r'size[:\s]*(\d+)\s*bytes',
            r'(\d+)\s*bytes'
        ]
        
        for pattern in size_patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                metrics['bytecode_size'] = int(match.group(1))
                break
        
        return metrics
    
    def run_security_scan(self, contract_path: str) -> Tuple[bool, str, Dict[str, Any]]:
        """Run security scan on contract"""
        self.logger.info(f"Running security scan on {contract_path}")
        
        try:
            vulnerabilities = self.security_scanner.scan_file(Path(contract_path))
            
            # Generate security report
            scan_results = {contract_path: vulnerabilities}
            security_report = self.security_scanner.generate_report(scan_results)
            
            success = security_report['summary']['risk_level'] in ['LOW', 'INFO']
            
            return success, "Security scan completed", security_report
            
        except Exception as e:
            self.logger.error(f"Security scan error: {e}")
            return False, str(e), {}
    
    def run_test_suite(self, test_suite: TestSuite) -> List[TestResult]:
        """Run a complete test suite"""
        self.logger.info(f"Running test suite: {test_suite.name}")
        
        results = []
        
        for test_file in test_suite.test_files:
            # Skip if platform not supported
            if test_suite.platforms and self.platform not in test_suite.platforms:
                self.logger.info(f"Skipping {test_file} - platform {self.platform} not supported")
                continue
            
            # Run compilation tests
            for target in ['evm', 'solana']:
                test_name = f"{test_suite.name}_{target}_compile"
                
                self.logger.info(f"Running test: {test_name}")
                
                start_time = time.time()
                
                try:
                    # Compile contract
                    success, output, error_output, metrics = self.compile_contract(test_file, target)
                    
                    # Run security scan
                    sec_success, sec_message, sec_report = self.run_security_scan(test_file)
                    
                    duration = time.time() - start_time
                    
                    # Determine test status
                    if success and sec_success:
                        status = "PASS"
                        message = f"Compilation and security scan successful for {target}"
                    elif success and not sec_success:
                        status = "WARN"
                        message = f"Compilation successful but security issues found for {target}"
                    else:
                        status = "FAIL"
                        message = f"Compilation failed for {target}"
                    
                    # Combine all metrics
                    all_metrics = {
                        **metrics,
                        'security_scan': sec_report.get('summary', {}),
                        'target': target
                    }
                    
                    result = TestResult(
                        test_name=test_name,
                        status=status,
                        duration=duration,
                        message=message,
                        output=output,
                        error_output=error_output,
                        metrics=all_metrics,
                        platform=self.platform,
                        timestamp=datetime.now().isoformat()
                    )
                    
                    results.append(result)
                    
                    # Handle failure based on suite configuration
                    if not success and test_suite.skip_on_failure:
                        self.logger.warning(f"Skipping remaining tests due to failure in {test_name}")
                        break
                        
                except Exception as e:
                    duration = time.time() - start_time
                    
                    result = TestResult(
                        test_name=test_name,
                        status="ERROR",
                        duration=duration,
                        message=f"Test execution error: {str(e)}",
                        output="",
                        error_output=str(e),
                        metrics={'error': str(e)},
                        platform=self.platform,
                        timestamp=datetime.now().isoformat()
                    )
                    
                    results.append(result)
        
        return results
    
    def run_all_tests(self, test_dir: str = "test_contracts") -> Dict[str, Any]:
        """Run all discovered test suites"""
        self.logger.info("Starting comprehensive test run")
        
        self.start_time = time.time()
        
        # Discover tests
        test_suites = self.discover_tests(test_dir)
        
        if not test_suites:
            self.logger.warning("No test suites found")
            return {
                'status': 'NO_TESTS',
                'message': 'No test suites discovered',
                'summary': {},
                'results': []
            }
        
        # Run all test suites
        all_results = []
        
        for test_suite in test_suites:
            suite_results = self.run_test_suite(test_suite)
            all_results.extend(suite_results)
        
        # Generate comprehensive report
        report = self.generate_report(all_results)
        
        return report
    
    def generate_report(self, results: List[TestResult]) -> Dict[str, Any]:
        """Generate comprehensive test report"""
        total_tests = len(results)
        
        # Count by status
        status_counts = {
            'PASS': 0,
            'FAIL': 0,
            'SKIP': 0,
            'ERROR': 0,
            'WARN': 0
        }
        
        for result in results:
            status_counts[result.status] += 1
        
        # Calculate success rate
        success_rate = (status_counts['PASS'] / total_tests * 100) if total_tests > 0 else 0
        
        # Calculate total duration
        total_duration = sum(result.duration for result in results)
        
        # Platform breakdown
        platform_breakdown = {}
        for result in results:
            platform = result.platform
            if platform not in platform_breakdown:
                platform_breakdown[platform] = {'PASS': 0, 'FAIL': 0, 'ERROR': 0}
            platform_breakdown[platform][result.status] += 1
        
        # Target breakdown
        target_breakdown = {}
        for result in results:
            target = result.metrics.get('target', 'unknown')
            if target not in target_breakdown:
                target_breakdown[target] = {'PASS': 0, 'FAIL': 0, 'ERROR': 0}
            target_breakdown[target][result.status] += 1
        
        report = {
            'summary': {
                'total_tests': total_tests,
                'status_counts': status_counts,
                'success_rate': success_rate,
                'total_duration': total_duration,
                'platform_breakdown': platform_breakdown,
                'target_breakdown': target_breakdown,
                'test_run_date': datetime.now().isoformat(),
                'framework_version': '1.0.0'
            },
            'results': [asdict(result) for result in results],
            'recommendations': self._generate_test_recommendations(status_counts)
        }
        
        # Save report
        self.save_report(report)
        
        return report
    
    def _generate_test_recommendations(self, status_counts: Dict[str, int]) -> List[str]:
        """Generate test recommendations based on results"""
        recommendations = []
        
        total = sum(status_counts.values())
        pass_rate = (status_counts['PASS'] / total * 100) if total > 0 else 0
        
        if pass_rate < 50:
            recommendations.append("🚨 Critical: Less than 50% test pass rate - review implementation")
        elif pass_rate < 80:
            recommendations.append("⚠️  Warning: Test pass rate below 80% - investigate failures")
        
        if status_counts['ERROR'] > 0:
            recommendations.append("🔧 Fix test execution errors before proceeding")
        
        if status_counts['FAIL'] > 0:
            recommendations.append("📋 Review test failures and fix underlying issues")
        
        if pass_rate >= 95:
            recommendations.append("✅ Excellent test coverage - maintain quality standards")
        
        return recommendations
    
    def save_report(self, report: Dict[str, Any], filename: Optional[str] = None):
        """Save test report to file"""
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"test_report_{timestamp}.json"
        
        report_path = Path(__file__).parent / "reports" / filename
        report_path.parent.mkdir(exist_ok=True)
        
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.logger.info(f"Test report saved to: {report_path}")
        
        # Also save summary as text
        summary_path = report_path.with_suffix('.txt')
        self._save_text_summary(report, summary_path)
    
    def _save_text_summary(self, report: Dict[str, Any], path: Path):
        """Save human-readable summary"""
        with open(path, 'w') as f:
            f.write("OMEGA Test Framework Summary Report\n")
            f.write("=" * 50 + "\n\n")
            
            summary = report['summary']
            
            f.write(f"Test Run Date: {summary['test_run_date']}\n")
            f.write(f"Total Tests: {summary['total_tests']}\n")
            f.write(f"Success Rate: {summary['success_rate']:.1f}%\n")
            f.write(f"Total Duration: {summary['total_duration']:.2f}s\n\n")
            
            f.write("Status Breakdown:\n")
            for status, count in summary['status_counts'].items():
                f.write(f"  {status}: {count}\n")
            
            f.write("\nPlatform Breakdown:\n")
            for platform, counts in summary['platform_breakdown'].items():
                f.write(f"  {platform}: PASS={counts['PASS']}, FAIL={counts['FAIL']}, ERROR={counts['ERROR']}\n")
            
            f.write("\nTarget Breakdown:\n")
            for target, counts in summary['target_breakdown'].items():
                f.write(f"  {target}: PASS={counts['PASS']}, FAIL={counts['FAIL']}, ERROR={counts['ERROR']}\n")
            
            if 'recommendations' in report and report['recommendations']:
                f.write("\nRecommendations:\n")
                for rec in report['recommendations']:
                    f.write(f"  {rec}\n")
    
    def print_summary(self, report: Dict[str, Any]):
        """Print test summary to console"""
        summary = report['summary']
        
        print(f"\n🔬 OMEGA Test Framework Results:")
        print(f"Total Tests: {summary['total_tests']}")
        print(f"Success Rate: {summary['success_rate']:.1f}%")
        print(f"Total Duration: {summary['total_duration']:.2f}s")
        
        print(f"\nStatus Breakdown:")
        for status, count in summary['status_counts'].items():
            if count > 0:
                print(f"  {status}: {count}")
        
        if 'recommendations' in report and report['recommendations']:
            print(f"\nRecommendations:")
            for rec in report['recommendations']:
                print(f"  {rec}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='OMEGA Test Framework')
    parser.add_argument('--test-dir', default='test_contracts', help='Test contracts directory')
    parser.add_argument('--omega-cli', help='Path to OMEGA CLI')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--output', help='Output report file')
    parser.add_argument('--suite', help='Run specific test suite')
    
    args = parser.parse_args()
    
    try:
        # Initialize framework
        framework = OmegaTestFramework(
            omega_cli_path=args.omega_cli,
            verbose=args.verbose
        )
        
        # Run tests
        if args.suite:
            # Run specific suite (would need to implement suite selection)
            print(f"Running specific suite: {args.suite}")
            # This would require additional implementation
        else:
            # Run all tests
            report = framework.run_all_tests(args.test_dir)
            
            # Print summary
            framework.print_summary(report)
            
            # Return appropriate exit code
            if report['summary']['success_rate'] >= 80:
                return 0
            else:
                return 1
                
    except Exception as e:
        print(f"Test framework error: {e}")
        return 1

if __name__ == '__main__':
    import sys
    sys.exit(main())
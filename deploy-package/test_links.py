#!/usr/bin/env python3
"""
Comprehensive link testing script for OMEGA website
Tests all internal links and resources for 404 errors
"""

import requests
import time
from urllib.parse import urljoin, urlparse
import sys

# Base URL for testing
BASE_URL = "http://localhost:8000"

# List of all pages and resources to test
TEST_URLS = [
    # Main pages
    "/",
    "/index.html",
    "/docs.html", 
    "/playground.html",
    "/blog.html",
    "/roadmap.html",
    "/security.html",
    "/forum.html",
    
    # Documentation pages
    "/docs/getting-started.html",
    "/docs/language-spec.html", 
    "/docs/best-practices.html",
    "/docs/examples.html",
    
    # Assets and resources
    "/styles.css",
    "/script.js",
    "/lang.js",
    "/performance.js",
    "/logo.svg",
    "/service-worker.js",
    "/robots.txt",
    "/sitemap.xml",
    
    # Error pages
    "/404.html",
    
    # Test non-existent page (should return 404)
    "/non-existent-page.html"
]

def test_url(url):
    """Test a single URL and return status info"""
    full_url = urljoin(BASE_URL, url)
    try:
        response = requests.get(full_url, timeout=10)
        return {
            'url': url,
            'full_url': full_url,
            'status_code': response.status_code,
            'status': 'PASS' if response.status_code == 200 else 'FAIL',
            'error': None,
            'content_length': len(response.content)
        }
    except requests.exceptions.RequestException as e:
        return {
            'url': url,
            'full_url': full_url,
            'status_code': None,
            'status': 'ERROR',
            'error': str(e),
            'content_length': 0
        }

def main():
    print("🧪 OMEGA Website Link Testing")
    print("=" * 50)
    print(f"Base URL: {BASE_URL}")
    print(f"Testing {len(TEST_URLS)} URLs...\n")
    
    results = []
    passed = 0
    failed = 0
    errors = 0
    
    for i, url in enumerate(TEST_URLS, 1):
        print(f"[{i:2d}/{len(TEST_URLS)}] Testing: {url}", end=" ... ")
        
        result = test_url(url)
        results.append(result)
        
        if result['status'] == 'PASS':
            print(f"✅ {result['status_code']} ({result['content_length']} bytes)")
            passed += 1
        elif result['status'] == 'FAIL':
            print(f"❌ {result['status_code']}")
            failed += 1
        else:
            print(f"🔥 ERROR: {result['error']}")
            errors += 1
        
        # Small delay to avoid overwhelming the server
        time.sleep(0.1)
    
    print("\n" + "=" * 50)
    print("📊 TEST SUMMARY")
    print("=" * 50)
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    print(f"🔥 Errors: {errors}")
    print(f"📈 Success Rate: {(passed / len(TEST_URLS)) * 100:.1f}%")
    
    # Show failed tests
    if failed > 0 or errors > 0:
        print("\n🚨 FAILED TESTS:")
        print("-" * 30)
        for result in results:
            if result['status'] != 'PASS':
                if result['status'] == 'FAIL':
                    print(f"❌ {result['url']} → {result['status_code']}")
                else:
                    print(f"🔥 {result['url']} → {result['error']}")
    
    # Special checks
    print("\n🔍 SPECIAL CHECKS:")
    print("-" * 30)
    
    # Check if 404 page works
    non_existent_result = next((r for r in results if r['url'] == '/non-existent-page.html'), None)
    if non_existent_result:
        if non_existent_result['status_code'] == 404:
            print("✅ 404 error handling works correctly")
        else:
            print(f"⚠️  404 error handling issue: got {non_existent_result['status_code']} instead of 404")
    
    # Check critical pages
    critical_pages = ['/', '/docs.html', '/playground.html']
    critical_failed = [r for r in results if r['url'] in critical_pages and r['status'] != 'PASS']
    
    if not critical_failed:
        print("✅ All critical pages are working")
    else:
        print("🚨 Critical pages have issues:")
        for result in critical_failed:
            print(f"   - {result['url']}: {result['status_code'] or result['error']}")
    
    # Check documentation pages
    doc_pages = ['/docs/getting-started.html', '/docs/language-spec.html', '/docs/best-practices.html', '/docs/examples.html']
    doc_failed = [r for r in results if r['url'] in doc_pages and r['status'] != 'PASS']
    
    if not doc_failed:
        print("✅ All documentation pages are working")
    else:
        print("🚨 Documentation pages have issues:")
        for result in doc_failed:
            print(f"   - {result['url']}: {result['status_code'] or result['error']}")
    
    # Check resource pages
    resource_pages = ['/blog.html', '/roadmap.html', '/security.html', '/forum.html']
    resource_failed = [r for r in results if r['url'] in resource_pages and r['status'] != 'PASS']
    
    if not resource_failed:
        print("✅ All resource pages are working")
    else:
        print("🚨 Resource pages have issues:")
        for result in resource_failed:
            print(f"   - {result['url']}: {result['status_code'] or result['error']}")
    
    print("\n" + "=" * 50)
    
    if failed == 0 and errors == 0:
        print("🎉 ALL TESTS PASSED! Website is ready for deployment.")
        return 0
    else:
        print("🚨 Some tests failed. Please fix the issues before deployment.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
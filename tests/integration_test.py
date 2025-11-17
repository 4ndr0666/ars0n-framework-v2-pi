"""
Basic integration test for ars0n-framework-v2-pi.

This test ensures that the docker-compose.yml file can be parsed and that
all of the expected service names are present.  It does not attempt to
start containers or execute the tools, but it serves as a quick sanity
check for CI systems.
"""

import os
import yaml


def test_compose_services():
    # Determine the path to the repository root relative to this file
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    compose_path = os.path.join(repo_root, 'docker-compose.yml')
    with open(compose_path, 'r', encoding='utf-8') as f:
        compose = yaml.safe_load(f)

    # List of services expected in the compose file
    expected_services = [
        'db', 'api', 'client', 'ai_service',
        'subfinder', 'assetfinder', 'katana', 'sublist3r',
        'cloud_enum', 'ffuf', 'subdomainizer', 'cewl',
        'metabigor', 'httpx', 'gospider', 'dnsx',
        'github-recon', 'nuclei', 'shuffledns'
    ]

    for service_name in expected_services:
        assert service_name in compose.get('services', {}), f"Service '{service_name}' missing from docker-compose.yml"
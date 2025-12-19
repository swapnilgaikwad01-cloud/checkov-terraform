#!/bin/bash

set -e

echo "Starting Checkov security scan..."

# Create reports directory
mkdir -p reports

# Run Checkov with multiple output formats
docker run --rm \
  -v "$(pwd):/app" \
  -w /app \
  bridgecrew/checkov:latest \
  checkov -d . \
    --framework terraform \
    --output cli \
    --output junitxml \
    --output json \
    --output sarif \
    --output-file-path console,reports/checkov-junit.xml,reports/checkov-report.json,reports/checkov-sarif.json \
    --soft-fail

echo "Checkov scan completed. Reports generated in ./reports/"
echo "- JUnit XML: reports/checkov-junit.xml"
echo "- JSON Report: reports/checkov-report.json"
echo "- SARIF Report: reports/checkov-sarif.json"
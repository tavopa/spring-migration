#!/bin/bash
# Script para analizar compatibilidad JDK usando jdeps y jdeprscan

set -e

TARGET_JAVA="${1:-21}"
CLASSES_DIR="${2:-target/classes}"

if [ ! -d "$CLASSES_DIR" ]; then
    echo "Warning: $CLASSES_DIR not found. Skipping JDK compatibility analysis."
    exit 0
fi

echo "Analyzing JDK compatibility for Java $TARGET_JAVA..."
echo "Classes directory: $CLASSES_DIR"

# Run jdeps to check for internal API usage
echo "Running jdeps analysis..."
jdeps --multi-release "$TARGET_JAVA" --jdk-internals "$CLASSES_DIR" > jdeps-report.txt 2>&1 || true

if grep -q "JDK internal API" jdeps-report.txt; then
    echo "⚠️  WARNING: JDK internal API usage detected!"
    cat jdeps-report.txt
    echo "jdeps_issues=true" >> $GITHUB_OUTPUT
else
    echo "✅ No JDK internal API usage detected"
    echo "jdeps_issues=false" >> $GITHUB_OUTPUT
fi

# Run jdeprscan to find deprecated APIs
echo "Running jdeprscan analysis..."
jdeprscan --multi-release "$TARGET_JAVA" --class-path "$CLASSES_DIR" "$CLASSES_DIR" > jdeprscan-report.txt 2>&1 || true

if [ -s jdeprscan-report.txt ] && ! grep -q "no deprecated API usage" jdeprscan-report.txt; then
    echo "⚠️  WARNING: Deprecated API usage detected!"
    cat jdeprscan-report.txt
    echo "deprecated_apis=true" >> $GITHUB_OUTPUT
else
    echo "✅ No deprecated API usage detected"
    echo "deprecated_apis=false" >> $GITHUB_OUTPUT
fi

echo "JDK compatibility analysis completed"


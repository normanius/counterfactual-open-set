#!/bin/bash
RESULTS_DIR="${1:-out_new}"

echo "Baseline and OpenMax results (non-generative):"
cat `find "${RESULTS_DIR}/evaluations/" | grep json | sort | head -1`
echo

echo
echo "Results with generated data:"
cat `find "${RESULTS_DIR}/evaluations/" | grep json | sort | tail -1`

#!/bin/bash
# Break on any error
set -e

RESULTS_DIR="out_all"

# Options are: baso blast eo ig lymph mono neut nrbc
HOLD_OUT="baso"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="blast"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="eo"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="ig"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="lymph"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="mono"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="neut"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"
HOLD_OUT="nrbc"
./start_boston.sh "params_boston_32.json" "${HOLD_OUT}" "${RESULTS_DIR}/${HOLD_OUT}"

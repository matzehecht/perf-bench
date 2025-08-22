#!/bin/bash

# Zwei Test-URLs definieren
URL_A="$1"
URL_B="$2"

# Anzahl Runs für Lighthouse
LIGHTHOUSE_RUNS=3

# Apache Benchmark Einstellungen
AB_REQUESTS=200
AB_CONCURRENCY=10

echo "=== Performance Vergleich ==="
echo ""
echo "Test mit Lighthouse und Apache Benchmark"
echo ""

run_lighthouse() {
  local url=$1
  echo ">>> Lighthouse Test für $url"
  local outputPath="$(echo $url | sed -E 's|https?://([^/]*)/?|\1|').json"
  echo "DEBUG: $outputPath"
  # lhci collect --url=$url --numberOfRuns=$LIGHTHOUSE_RUNS --outputPath="./lhci-report-$outputPath" >/dev/null 2>&1
  lhci collect --url=$url --numberOfRuns=$LIGHTHOUSE_RUNS --outputPath="./lhci-report-$outputPath"
  # Auswertung aus den JSON-Ergebnissen (Performance Score)
  SCORE=$(jq -r '.[].summary.performance' ./lhci-report-$outputPath | awk '{ total += $1 } END { print total/NR }')
  echo "Performance Score (Ø aus $LIGHTHOUSE_RUNS Läufen): $SCORE"
  echo ""
}

run_ab() {
  local url=$1
  echo ">>> Apache Benchmark Test für $url"
  ab -n $AB_REQUESTS -c $AB_CONCURRENCY $url/ | grep "Requests per second\|Time per request"
  echo ""
}

echo "=== Hoster A ($URL_A) ==="
run_lighthouse $URL_A
run_ab $URL_A

echo "=== Hoster B ($URL_B) ==="
run_lighthouse $URL_B
run_ab $URL_B

#!/bin/bash

# Default values
LIGHTHOUSE_RUNS=5
AB_REQUESTS=200
AB_CONCURRENCY=10
CSV_FILE="./perf_bench_results.csv"

# Display help message
show_help() {
  echo "Usage: $0 [options] url1 [url2 url3 ...]"
  echo "Options:"
  echo "  -l NUMBER  Number of Lighthouse runs (default: $LIGHTHOUSE_RUNS)"
  echo "  -r NUMBER  Number of Apache Benchmark requests (default: $AB_REQUESTS)"
  echo "  -c NUMBER  Concurrency level for Apache Benchmark (default: $AB_CONCURRENCY)"
  echo "  -o FILE    Output CSV file path (default: $CSV_FILE)"
  echo "  -h         Display this help message"
  exit 1
}

# Parse options with getopt for more robust parsing
TEMP=$(getopt -o l:r:c:o:h --name "$0" -- "$@")
if [ $? -ne 0 ]; then
  echo "Error parsing arguments" >&2
  show_help
fi

# Reset the positional parameters to the parsed output
eval set -- "$TEMP"

# Process options
while true; do
  case "$1" in
    -l)
      LIGHTHOUSE_RUNS="$2"
      shift 2
      ;;
    -r)
      AB_REQUESTS="$2"
      shift 2
      ;;
    -c)
      AB_CONCURRENCY="$2"
      shift 2
      ;;
    -o)
      CSV_FILE="$2"
      shift 2
      ;;
    -h)
      show_help
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!" >&2
      exit 1
      ;;
  esac
done

# Create CSV header if file doesn't exist
if [ ! -f "$CSV_FILE" ]; then
  # Ensure directory exists
  mkdir -p "$(dirname "$CSV_FILE")"
  echo "timestamp,url,lighthouse_runs,lighthouse_perf_score,lighthouse_accessibility_score,lighthouse_best_practices_score,lighthouse_seo_score,apache_benchmark_requests,apache_benchmark_concurrency,requests_per_sec,time_per_request_ms,transfer_rate" >> "$CSV_FILE"
fi

# Check if at least one URL was provided
if [ $# -eq 0 ]; then
  echo "Error: No URLs provided."
  show_help
fi

# Print debug info - what's left should be URLs only
echo "Debug: Remaining arguments (should be URLs): $@"

run_lighthouse() {
  rm -rf .lighthouseci .results

  local url=$1
  lhci autorun --upload.target=filesystem --upload.outputDir='.results/' --collect.url=$url --collect.numberOfRuns=$LIGHTHOUSE_RUNS --collect.settings.chromeFlags="--no-sandbox --disable-gpu" > /dev/null 2>&1

  # Auswertung aus den JSON-Ergebnissen (Performance Score)
  PERF_SCORE=$(jq -r '.[].summary.performance' .results/manifest.json)
  ACCESS_SCORE=$(jq -r '.[].summary.accessibility' .results/manifest.json)
  BP_SCORE=$(jq -r '.[].summary["best-practices"]' .results/manifest.json)
  SEO_SCORE=$(jq -r '.[].summary.seo' .results/manifest.json)

  echo "$PERF_SCORE" "$ACCESS_SCORE" "$BP_SCORE" "$SEO_SCORE"
}

run_ab() {
  local url=$1

  AB_RESULT=$(ab -n $AB_REQUESTS -c $AB_CONCURRENCY $url/ 2>/dev/null)

  REQ_SEC=$(echo "$AB_RESULT" | grep "Requests per second" | awk '{print $4}')
  TIME_REQ=$(echo "$AB_RESULT" | grep "Time per request" | head -n 1 | awk '{print $4}')
  TRANSFER_RATE=$(echo "$AB_RESULT" | grep "Transfer rate" | awk '{print $3}')

  echo "$REQ_SEC" "$TIME_REQ" "$TRANSFER_RATE"
}

run_test() {
  local url=$1

  echo ">>> Testing $url"

  SCORE=$(run_lighthouse $url)
  AB_DATA=$(run_ab $url)

  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

  read PERF_SCORE ACCESS_SCORE BP_SCORE SEO_SCORE < <(echo "$SCORE")
  read REQ_SEC TIME_REQ TRANSFER_RATE < <(echo "$AB_DATA")

  # Append result to CSV
  echo "\"$TIMESTAMP\",\"$url\",\"$LIGHTHOUSE_RUNS\",\"$PERF_SCORE\",\"$ACCESS_SCORE\",\"$BP_SCORE\",\"$SEO_SCORE\",\"$AB_REQUESTS\",\"$AB_CONCURRENCY\",\"$REQ_SEC\",\"$TIME_REQ\",\"$TRANSFER_RATE\"" >> "$CSV_FILE"

  echo "✅ Result saved: $TIMESTAMP $url Score=\"$PERF_SCORE\",\"$ACCESS_SCORE\",\"$BP_SCORE\",\"$SEO_SCORE\" Benchmark=\"$REQ_SEC\",\"$TIME_REQ\",\"$TRANSFER_RATE\""
}

echo "=== Performance Comparison ==="
echo "Configuration:"
echo "- Lighthouse Runs: $LIGHTHOUSE_RUNS"
echo "- Apache Benchmark Requests: $AB_REQUESTS"
echo "- Apache Benchmark Concurrency: $AB_CONCURRENCY"
echo "- CSV File: $CSV_FILE"
echo "-----------------------------------"
echo "URLs to test: $@"
echo "-----------------------------------"

# Process all provided URLs
for url in "$@"; do
  run_test "$url"
done

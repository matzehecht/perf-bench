
# perf-bench

A Docker-based performance benchmarking tool.

## Features
- Benchmarks web applications using Lighthouse CI and ApacheBench
- Outputs results to CSV files in `tmp/result/`
- Includes a shell script (`perf-bench.sh`) for running benchmarks
- Dockerfile sets up all required dependencies

## Usage

### Build the Docker image

```sh
docker build -t perf-bench .
```

### Run the benchmark

```sh
docker run --rm -v $(pwd)/tmp/result:/app/tmp/result perf-bench
```

Results will be saved in `tmp/result/perf_bench_results.csv` and `tmp/result/performance_results.csv`.

## GitHub Actions

A workflow is included to build and push the Docker image to GitHub Container Registry on every push to `main`.

## License

MIT

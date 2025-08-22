FROM node

RUN mkdir -p /app
WORKDIR /app

RUN apt-get update && apt-get install -y apache2-utils jq
RUN npm install -g @lhci/cli

COPY perf-bench.sh /usr/local/bin/perf-bench
RUN chmod +x /usr/local/bin/perf-bench

ENTRYPOINT ["/usr/local/bin/perf-bench"]

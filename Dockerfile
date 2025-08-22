FROM node

RUN mkdir -p /app
WORKDIR /app

RUN apt-get update
RUN apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils

# Install Chrome
RUN wget -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable

ENV CHROME_PATH=/usr/bin/google-chrome
ENV CHROME_FLAGS="--no-sandbox --disable-gpu --disable-features=UseOzonePlatform"

RUN apt-get install -y \
    apache2-utils \
    jq

RUN npm install -g @lhci/cli

COPY perf-bench.sh /usr/local/bin/perf-bench
RUN chmod +x /usr/local/bin/perf-bench

ENTRYPOINT ["/usr/local/bin/perf-bench"]

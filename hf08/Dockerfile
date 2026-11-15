FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash curl jq ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN useradd --create-home --uid 1000 --shell /bin/bash logtool
WORKDIR /app
COPY --chmod=755 logtool.sh /app/logtool.sh
USER logtool
ENTRYPOINT ["/app/logtool.sh"]
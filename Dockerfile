FROM node:24-bookworm-slim

# Pin the harness: upstream is a developer preview with breaking changes.
ARG DSH_VERSION=0.2.1-rc.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git tini \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 10001 dsh
USER dsh

ENV DSH_HOME=/home/dsh/.dsh \
    NPM_CONFIG_PREFIX=/home/dsh/.npm-global \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    PATH=/home/dsh/.npm-global/bin:$PATH

RUN npm install --global "@deepseek-ai/dsh@${DSH_VERSION}" \
 && npm cache clean --force \
 && mkdir -p "$DSH_HOME"

COPY --chmod=0755 entrypoint.sh /usr/local/bin/dsh-entrypoint

WORKDIR /workspace
EXPOSE 3080
ENTRYPOINT ["tini", "--", "dsh-entrypoint"]

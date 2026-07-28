# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/typescript/instruqt/Dockerfile \
#     -t temporal-typescript-workshop .
FROM --platform=linux/amd64 node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl git jq nano procps psmisc python3 python3-venv \
       tmux vim-tiny zip \
    && rm -rf /var/lib/apt/lists/*

RUN printf 'set -g status off\nset -g mouse on\nset -g history-limit 50000\nsetw -g aggressive-resize on\n' \
    > /root/.tmux.conf

RUN curl -sSf https://temporal.download/cli.sh -o /tmp/install-temporal.sh \
    && sh /tmp/install-temporal.sh \
    && rm /tmp/install-temporal.sh \
    && ln -s /root/.temporalio/bin/temporal /usr/local/bin/temporal

WORKDIR /root/workshop
COPY tracks/typescript/ .

RUN npm ci \
    && python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt

RUN mkdir -p /tmp/stage/temporal-typescript-workshop /root/workshop/dist \
    && cp -r README.md package.json package-lock.json tsconfig.json exercises services \
       /tmp/stage/temporal-typescript-workshop/ \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-typescript-workshop.zip \
           temporal-typescript-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

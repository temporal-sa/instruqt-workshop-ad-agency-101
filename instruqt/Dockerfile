# Workshop workstation image. Build from the repo root:
#   docker build --platform linux/amd64 -f instruqt/Dockerfile -t temporal-python-workshop .
FROM --platform=linux/amd64 python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates git jq procps psmisc nano vim-tiny tmux zip \
    && rm -rf /var/lib/apt/lists/*

# Terminal tabs attach to named tmux sessions so running processes survive
# challenge transitions. Invisible tmux: no status bar, mouse scrolling.
RUN printf 'set -g status off\nset -g mouse on\nset -g history-limit 50000\nsetw -g aggressive-resize on\n' > /root/.tmux.conf

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN curl -sSf https://temporal.download/cli.sh | sh \
    && ln -s /root/.temporalio/bin/temporal /usr/local/bin/temporal

WORKDIR /root/workshop
COPY . .
RUN uv sync && rm -rf /root/.cache/uv

# Take-home zip: the exact laptop-mode subset of what the editor shows,
# served by a static file server on :8000 (started in track setup).
RUN mkdir -p /tmp/stage/temporal-python-workshop /root/workshop/dist \
    && cp -r README.md pyproject.toml uv.lock conftest.py exercises services tests \
         /tmp/stage/temporal-python-workshop/ \
    && find /tmp/stage -name __pycache__ -type d -exec rm -rf {} + \
    && (cd /tmp/stage && zip -qr /root/workshop/dist/temporal-python-workshop.zip temporal-python-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

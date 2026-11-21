# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/go/instruqt/Dockerfile \
#     -t temporal-go-workshop .
FROM --platform=linux/amd64 golang:1.27.4-bookworm

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

# Use the image's Go toolchain; never download another one in the lab.
ENV GOTOOLCHAIN=local

WORKDIR /root/workshop
COPY tracks/go/ .

# Download modules and warm the build cache so `go run` starts quickly and
# works without network access during the lab.
RUN go mod download \
    && go build ./... \
    && go vet ./... \
    && python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt

RUN mkdir -p /tmp/stage/temporal-go-workshop /root/workshop/dist \
    && cp -r README.md go.mod go.sum exercises services \
       /tmp/stage/temporal-go-workshop/ \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-go-workshop.zip \
           temporal-go-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/rust/instruqt/Dockerfile \
#     -t temporal-rust-workshop .
FROM --platform=linux/amd64 rust:1.99.1-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl git jq libprotobuf-dev nano procps protobuf-compiler \
       psmisc python3 python3-venv tmux vim-tiny zip \
    && rm -rf /var/lib/apt/lists/*

RUN printf 'set -g status off\nset -g mouse on\nset -g history-limit 50000\nsetw -g aggressive-resize on\n' \
    > /root/.tmux.conf

RUN curl -sSf https://temporal.download/cli.sh -o /tmp/install-temporal.sh \
    && sh /tmp/install-temporal.sh \
    && rm /tmp/install-temporal.sh \
    && ln -s /root/.temporalio/bin/temporal /usr/local/bin/temporal

WORKDIR /root/workshop

# Compile the dependency graph first, in its own layer, so editing exercise
# code does not recompile the Temporal SDK when this image is rebuilt.
COPY tracks/rust/Cargo.toml tracks/rust/Cargo.lock ./
RUN mkdir -p /tmp/deps/src \
    && printf '[package]\nname = "workshop-deps"\nversion = "0.0.0"\nedition = "2024"\n\n' > /tmp/deps/Cargo.toml \
    && sed -n '/^\[dependencies\]/,/^$/p' Cargo.toml >> /tmp/deps/Cargo.toml \
    && sed -n '/^\[profile/,/^$/p' Cargo.toml >> /tmp/deps/Cargo.toml \
    && cp Cargo.lock /tmp/deps/ \
    && echo 'fn main() {}' > /tmp/deps/src/main.rs \
    && CARGO_TARGET_DIR=/root/workshop/target cargo build --manifest-path /tmp/deps/Cargo.toml \
    && rm -rf /tmp/deps

COPY tracks/rust/ .

# Build every learner-facing binary so the first `cargo run` of each exercise
# starts immediately. The *-solution binaries build on demand (smoke test).
RUN python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt \
    && cargo build --locked \
       --bin campaign-app --bin tagline-worker --bin social-post-worker \
       --bin publish-worker --bin approval-worker --bin campaign-worker \
       --bin replay --bin cloud-worker

RUN mkdir -p /tmp/stage/temporal-rust-workshop /root/workshop/dist \
    && cp -r README.md Cargo.toml Cargo.lock .gitignore exercises services \
       /tmp/stage/temporal-rust-workshop/ \
    && find /tmp/stage -name target -type d -prune -exec rm -rf {} + \
    && rm -f /tmp/stage/temporal-rust-workshop/exercises/07-bonus-observability/history.json \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-rust-workshop.zip \
           temporal-rust-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

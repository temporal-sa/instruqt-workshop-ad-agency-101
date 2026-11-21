# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/ruby/instruqt/Dockerfile \
#     -t temporal-ruby-workshop .
FROM --platform=linux/amd64 ruby:4.0.10-slim-bookworm

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

# Interactive shells keep the Ruby image's gem locations even when a
# terminal does not inherit the image ENV.
RUN printf 'export GEM_HOME=/usr/local/bundle\nexport BUNDLE_APP_CONFIG=/usr/local/bundle\nexport PATH="/usr/local/bundle/bin:$PATH"\n' \
    >> /root/.bashrc

WORKDIR /root/workshop

# Install gems first so code edits do not invalidate this layer. The
# temporalio gem ships a precompiled x86_64-linux native extension; json and
# bigdecimal compile small C extensions, so the compiler is installed only
# for this step.
COPY tracks/ruby/Gemfile tracks/ruby/Gemfile.lock ./
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && bundle config set --global frozen true \
    && bundle install --jobs 4 \
    && apt-get purge -y --auto-remove build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && bundle exec ruby -e 'require "temporalio/worker"; puts "temporalio #{Temporalio::VERSION}"'

COPY tracks/ruby/ .

RUN python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt \
    && chmod +x scripts/*.sh scripts/instruqt-workshop-helpers \
    && bash scripts/check.sh

RUN mkdir -p /tmp/stage/temporal-ruby-workshop /root/workshop/dist \
    && cp -r README.md Gemfile Gemfile.lock exercises services \
       /tmp/stage/temporal-ruby-workshop/ \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-ruby-workshop.zip \
           temporal-ruby-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

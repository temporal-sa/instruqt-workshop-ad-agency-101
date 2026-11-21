# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/dotnet/instruqt/Dockerfile \
#     -t temporal-dotnet-workshop .
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:10.0.404-noble

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

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
COPY tracks/dotnet/ .

# Restore NuGet packages and compile every exercise project at build time so
# the first `dotnet run` in the lab is an incremental build that works offline.
RUN python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt \
    && dotnet build CatNipCola.Workshop.slnx -nologo -v quiet

RUN mkdir -p /tmp/stage/temporal-dotnet-workshop /root/workshop/dist \
    && cp -r README.md .editorconfig .gitignore CatNipCola.Workshop.slnx \
       Directory.Build.props Directory.Packages.props exercises services \
       /tmp/stage/temporal-dotnet-workshop/ \
    && find /tmp/stage \( -name bin -o -name obj \) -type d -prune -exec rm -rf {} + \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-dotnet-workshop.zip \
           temporal-dotnet-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

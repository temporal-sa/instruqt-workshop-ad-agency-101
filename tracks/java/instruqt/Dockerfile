# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/java/instruqt/Dockerfile \
#     -t temporal-java-workshop .
FROM --platform=linux/amd64 maven:3.9.11-eclipse-temurin-21

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
COPY tracks/java/ .

RUN python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt \
    && mvn -q install -N \
    && for pom in $(find exercises -name pom.xml -type f); do \
         mvn -q -f "$pom" dependency:go-offline compile; \
       done

RUN mkdir -p /tmp/stage/temporal-java-workshop /root/workshop/dist \
    && cp -r README.md pom.xml exercises services \
       /tmp/stage/temporal-java-workshop/ \
    && find /tmp/stage -name target -type d -prune -exec rm -rf {} + \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-java-workshop.zip \
           temporal-java-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

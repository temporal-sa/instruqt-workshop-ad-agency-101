# Build from the repository root:
#   docker build --platform linux/amd64 \
#     -f tracks/php/instruqt/Dockerfile \
#     -t temporal-php-workshop .
FROM --platform=linux/amd64 php:8.4.27-cli-bookworm

ARG ROADRUNNER_VERSION=3.0.1

COPY --from=composer:2.11.1 /usr/bin/composer /usr/local/bin/composer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl git jq nano procps psmisc python3 python3-venv \
       tmux unzip vim-tiny zip \
    && rm -rf /var/lib/apt/lists/*

# temporal/sdk needs ext-sockets (RoadRunner's Goridge relay); curl and json
# ship with the official image.
RUN docker-php-ext-install sockets

# RoadRunner runs the PHP Workers. Keep it in step with roadrunner/roadrunner
# in composer.lock.
RUN curl -fsSL "https://github.com/roadrunner-server/roadrunner/releases/download/v${ROADRUNNER_VERSION}/roadrunner-${ROADRUNNER_VERSION}-linux-amd64.tar.gz" \
       | tar -xz -C /tmp \
    && mv "/tmp/roadrunner-${ROADRUNNER_VERSION}-linux-amd64/rr" /usr/local/bin/rr \
    && rm -rf /tmp/roadrunner-*

RUN printf 'set -g status off\nset -g mouse on\nset -g history-limit 50000\nsetw -g aggressive-resize on\n' \
    > /root/.tmux.conf

RUN curl -sSf https://temporal.download/cli.sh -o /tmp/install-temporal.sh \
    && sh /tmp/install-temporal.sh \
    && rm /tmp/install-temporal.sh \
    && ln -s /root/.temporalio/bin/temporal /usr/local/bin/temporal

WORKDIR /root/workshop
COPY tracks/php/ .

RUN composer install --no-interaction --no-progress --optimize-autoloader \
    && php scripts/check.php \
    && python3 -m venv .adnet-venv \
    && .adnet-venv/bin/pip install --no-cache-dir -r services/requirements.txt

RUN mkdir -p /tmp/stage/temporal-php-workshop /root/workshop/dist \
    && cp -r README.md composer.json composer.lock .rr.yaml .gitignore exercises services \
       /tmp/stage/temporal-php-workshop/ \
    && (cd /tmp/stage \
        && zip -qr /root/workshop/dist/temporal-php-workshop.zip \
           temporal-php-workshop) \
    && cp services/downloads/index.html /root/workshop/dist/ \
    && rm -rf /tmp/stage

ENV SHELL=/bin/bash
CMD ["/bin/bash"]

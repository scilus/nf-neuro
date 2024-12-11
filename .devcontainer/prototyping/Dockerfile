FROM scilus/scilus:2.0.2

ARG POETRY_VERSION

ENV POETRY_VERSION=${POETRY_VERSION:-1.8.*}

RUN apt update && apt install -y \
        curl \
        git \
        openjdk-17-jre \
        python3-venv \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install pipx && \
    python3 -m pipx ensurepath && \
    pipx install poetry==${POETRY_VERSION}

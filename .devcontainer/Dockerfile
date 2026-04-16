FROM ubuntu:22.04

# 対話的プロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

# HPCツール、システムツール、および日本語フォント(Noto CJK)のインストール
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    gdb \
    make \
    openmpi-bin \
    libopenmpi-dev \
    libomp-dev \
    htop \
    git \
    openssh-client \
    curl \
    xz-utils \
    fonts-noto-cjk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# グローバルスタンダードに合わせたユーザー「vscode」の作成
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash

# デフォルトユーザーの設定
USER $USERNAME
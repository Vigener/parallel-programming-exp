FROM ubuntu:22.04

# 対話的プロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

# コンパイラ、OpenMP、MPI、git、その他必須ツールのインストール
# （ここに git と、念のため ssh-client を追加しました）
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 一般ユーザーの作成
RUN useradd -m -s /bin/bash hpcuser
USER hpcuser
WORKDIR /home/hpcuser/workspace
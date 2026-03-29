FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# システム依存パッケージ
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git wget curl python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 rclone vim && rm -rf /var/lib/apt/lists/*

# ComfyUI 本体のセットアップ
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && pip3 install -r requirements.txt

# カスタムノードのインストール（Snapshotから特定した5種）
RUN cd custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone https://github.com/sylym/comfy_vid2vid.git && \
    find . -maxdepth 2 -name "requirements.txt" -exec pip3 install -r {} +

# ★ ここでローカルに用意した OSS モデル群を一気に焼き込む
COPY ./models/ /app/models/

EXPOSE 8188
# Vast.ai での起動を想定したフラグ設定
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--normalvram", "--use-sage-attention", "--fast"]

FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# システム依存パッケージ
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git wget curl python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 rclone vim && rm -rf /var/lib/apt/lists/*

# ComfyUI 本体のセットアップ
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && pip3 install -r requirements.txt

# --- 【修正】Manager を pip からインストール ---
RUN pip3 install comfyui-manager

# カスタムノードのインストール（Manager以外を列挙）
RUN cd custom_nodes && \
    git clone --depth 1 https://github.com/city96/ComfyUI-GGUF.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    # 先ほど特定した sylym 版
    git clone --depth 1 https://github.com/sylym/comfy_vid2vid comfyui-vid2vid && \
    find . -maxdepth 2 -name "requirements.txt" -exec pip3 install -r {} +

# 30GBの重量級モデル焼き込み
COPY ./models/ /app/models/

EXPOSE 8188

# --- 【修正】起動オプションに --enable-manager を追加 ---
# ※お使いの環境のフラグ名に合わせて調整してください（通常 --enable-manager 等）
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--normalvram", "--use-sage-attention", "--fast", "--enable-manager"]

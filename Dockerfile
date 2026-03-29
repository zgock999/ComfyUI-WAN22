FROM nvidia/cuda:12.6.0-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
# build-essential, g++, python3-dev を追加してコンパイルエラーを防ぐ
RUN apt-get update && apt-get install -y \
    git wget curl python3-pip python3-dev build-essential g++ \
    libgl1-mesa-glx libglib2.0-0 rclone vim && \
    rm -rf /var/lib/apt/lists/*

# pip 自体を最新にする（重要）
RUN pip3 install --upgrade pip --break-system-packages

WORKDIR /app

COPY ./pkgs /app/pkgs

RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    pip3 install -r requirements.txt --break-system-packages

RUN pip3 install /app/pkgs/sageattention-2.2.0-cp312-cp312-linux_x86_64.whl --break-system-packages

RUN pip3 install /app/pkgs/spas_sage_attn-0.1.0-cp312-cp312-linux_x86_64.whl --break-system-packages

# Manager を pip から入れる（前回特定した最新仕様）
RUN pip3 install comfyui-manager

# カスタムノードのインストール
# 一つの RUN で && を多用せず、分割するか個別に実行することで原因を特定しやすくします
RUN cd custom_nodes && \
    git clone --depth 1 https://github.com/city96/ComfyUI-GGUF.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone --depth 1 https://github.com/sylym/comfy_vid2vid comfyui-vid2vid

# 各ノードの依存関係を個別にインストール（エラーが出たノードを特定するため）
# 失敗してもビルドを止めない `--no-cache-dir` などを付けて安定させます
RUN for req in custom_nodes/*/requirements.txt; do pip3 install --no-cache-dir -r "$req"; done

# 30GBの重量級モデル焼き込み
COPY ./models/ /app/models/

EXPOSE 8188
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--normalvram", "--use-sage-attention", "--fast", "--enable-manager"]

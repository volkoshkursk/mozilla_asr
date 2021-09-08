# Please refer to the TRAINING documentation, "Basic Dockerfile for training"

FROM tensorflow/tensorflow:latest-gpu-py3
ENV DEBIAN_FRONTEND=noninteractive \
    DEEPSPEECH_REPO=https://github.com/mozilla/DeepSpeech.git \
    DEEPSPEECH_SHA=master
# RUN apt --purge remove "cublas*" "cuda*" \
#     apt --purge remove "nvidia*"
# RUN apt list cuda
# RUN apt list cuda -a
# RUN apt show cuda
RUN add-apt-repository ppa:graphics-drivers/ppa

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    nvidia-driver-410 \
    bash-completion \
    build-essential \
    cmake \
    curl \
    git \
    libboost-all-dev \
    libbz2-dev \
    liblzma-dev \
    locales \
    python3-venv \
    unzip \
    xz-utils \
    sox \
    libsox-fmt-mp3 \
    wget && \
    # We need to remove it because it's breaking deepspeech install later with \
    # weird errors about setuptools \
    apt-get purge -y python3-xdg && \
    # Install dependencies for audio augmentation \
    apt-get install -y --no-install-recommends libopus0 libsndfile1 && \
    # Try and free some space \
    rm -rf /var/lib/apt/lists/*
# RUN apt show cuda
WORKDIR /

COPY ./DeepSpeech /DeepSpeech

RUN  cd /DeepSpeech/native_client

# Build CTC decoder first, to avoid clashes on incompatible versions upgrades
RUN cd /DeepSpeech/native_client/ctcdecode && make NUM_PROCESSES=$(nproc) bindings && \
    pip3 install --upgrade dist/*.whl
# RUN apt show cuda
# Prepare deps
RUN cd /DeepSpeech && pip3 install --upgrade pip==20.2.2 wheel==0.34.2 setuptools==49.6.0 && \
    # Install DeepSpeech \
    #  - No need for the decoder since we did it earlier \
    #  - There is already correct TensorFlow GPU installed on the base image, \
    #    we don't want to break that \
    DS_NODECODER=y DS_NOTENSORFLOW=y pip3 install --upgrade -e . && \
    # Tool to convert output graph for inference \
    curl -vsSL https://github.com/mozilla/DeepSpeech/releases/download/v0.9.3/linux.amd64.convert_graphdef_memmapped_format.xz | xz -d > convert_graphdef_memmapped_format && \
    chmod +x convert_graphdef_memmapped_format
# RUN apt show cuda
# RUN pip3 uninstall tensorflow
RUN pip3 install 'tensorflow-gpu==1.15.4'

# Build KenLM to generate new scorers
WORKDIR /DeepSpeech/kenlm
RUN wget -O - https://gitlab.com/libeigen/eigen/-/archive/3.3.8/eigen-3.3.8.tar.bz2 | tar xj && \
    mkdir -p build && \
    cd build && \
    EIGEN3_ROOT=/DeepSpeech/kenlm/eigen-3.3.8 cmake .. && \
    make -j $(nproc)
# RUN apt show cuda
WORKDIR /DeepSpeech

COPY boot.sh /DeepSpeech/boot.sh
RUN chmod +x /DeepSpeech/boot.sh
# RUN apt list cuda
# RUN apt list cuda -a
# RUN apt show cuda
ENTRYPOINT ["./boot.sh"]

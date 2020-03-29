ARG BASE_CONTAINER=s390x/ubuntu
FROM $BASE_CONTAINER
# Define the label for this image
LABEL maintainer="IBM PoC"
# Switch to root user for the following steps
USER root
# Install all OS dependencies for notebook server that starts but lacks all features
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    git \
    default-jre \
    vim \
    curl \
    fonts-liberation \
    run-one
# Get the installed code-page
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
# Configure environment
ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PYTHON_PACKAGE_NAME="python"
ENV PYTHON_PACKAGE_VERSION="3.7.4"
#Configure and build and install Python3
RUN apt-get install -y gcc g++ libbz2-dev libdb-dev libffi-dev libgdbm-dev liblzma-dev libncurses-dev libreadline-dev libsqlite3-dev libssl-dev make tar tk-dev uuid-dev wget xz-utils zlib1g-dev \
    && wget "https://www.python.org/ftp/${PYTHON_PACKAGE_NAME}/${PYTHON_PACKAGE_VERSION}/Python-${PYTHON_PACKAGE_VERSION}.tgz" \
    && tar -xzvf "Python-${PYTHON_PACKAGE_VERSION}.tgz" \
    && rm "Python-${PYTHON_PACKAGE_VERSION}.tgz" \
    && cd "Python-${PYTHON_PACKAGE_VERSION}" \
    && ./configure \
    && make \
    && make install \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install notebook \
    jupyterlab \
    plotly \
    numpy \
    pandas \
    ipywidgets \
    jaydebeapi \
    ibm_db \
    matplotlib \
    && python3 -m pip install JPype1==0.6.3 --force-reinstall

RUN jupyter notebook --generate-config

# Copy all files from local zCX db2jars folder into the ubuntu images /db2jars folder
RUN mkdir /db2jars
ADD db2jars /db2jars

# Create a new group and user to run the notebook server
RUN groupadd jupyter-group && useradd -ms /bin/bash -G jupyter-group jupyter-user
USER jupyter-user
RUN mkdir /home/jupyter-user/notebooks
ENTRYPOINT ["jupyter","notebook","--ip=0.0.0.0","--port=8888","--allow-root","--notebook-dir=/home/jupyter-user/notebooks"]
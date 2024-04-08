#!/usr/bin/env bash

TMP_DIR=/tmp
CUDA_VERSION=${1:-"11.8.89"}
TRT_VERSION=${2:-"8.5.3.1"}
OS_VERSION=${3:-"ubuntu20.04"}
TARGETARCH=${4:-"amd64"}
CATCH2_VERSION=${5:-v3.2.1}
NUM_THREADS=${6:-"-1"}
ABSL_VERSION=${7:-"lts_2021_11_02"}
CMAKE_VERSION=${8:-"3.19.2"}
FMT_VERSION=${9:-"9.0.0"}
TMUX_VERSION=${10:-"3.1b"}
LIBEVENT_VERSION=${11:-"2.1.11"}
ROS1_DISTRO=${12:-"noetic"}
ROS1_METAPACKAGE=${13:-"ros-base"}
ROS1_PYTHON=${14:-"python3"}
USE_MIRROR=${15:-"false"}
ROS2_DISTRO=${16:-"humble"}
ROS2_ROOT=/opt/ros/${ROS2_DISTRO}
ROS2_METAPACKAGE=${17:-"ros_base"}
SKIP_KEYS=${18:-"cyclonedds"}
GCC_VERSION=${19:-"9"}
CERES_VERSION=${20:-"2.0.0"}
DOXYGEN_VERSION=${21:-"Release_1_9_8"}
GEOGRAPHICLIB_VERSION=${22:-"v2.3"}
PROJ_VERSION=${23:-"9.0.0"}
SOPHUS_VERSION=${24:-"1.22.10"}
C_PERIPHERY_VERSION=${25:-"v2.4.1"}
OPENCV_VERSION=${26:-"4.5.2"}

status() {
    if [ -z $TERM ]; then
        echo $1
    else
        tput setaf 6
        echo $1
        tput sgr0
    fi
}

warning() {
    if [ -z $TERM ]; then
        echo $1
    else
        tput setaf 3
        echo $1
        tput sgr0
    fi
}

error() {
    if [ -z $TERM ]; then
        echo $1
    else
        tput setaf 1
        echo $1
        tput sgr0
    fi
}

# USAGE: confirm [func] [text]
# EXAMPLE: confirm say_ok "Are you OK?"
confirm() {
    prompt_func=$1
    prompt_text=${@:2}

    if confirmation ${prompt_text}; then
        ${prompt_func}
    fi
}

# USAGE: confirm [text]
# EXAMPLE: confirmation "Are you OK?"
confirmation() {
    display_text="> $@?[y/N]"
    while true; do
        if [ -z $TERM ]; then
            echo $1
        else
            tput setaf 4
            echo -n ${display_text}
            tput sgr0
        fi

        read -p " " yn

        case ${yn} in
        [Yy]*)
            return
            break
            ;;
        "") break ;;
        [Nn]*) break ;;
        *) warning "Please answer yes or no." ;;
        esac
    done
    false
}

# USAGE: prompt [variable] [text]
prompt() {
    display_text="> ${@:2}:"

    if [ -z $TERM ]; then
        echo $1
    else
        tput setaf 4
        echo -n ${display_text}
        tput sgr0
    fi

    read -p " " $1
}

# USAGE: prompt_default [variable name] [text]
prompt_default() {
    display_text="> ${@:2}:"

    if [ -z $TERM ]; then
        echo $1
    else
        tput setaf 4
        echo -n ${display_text}
        tput sgr0
    fi

    default_value=${!1}
    read -p " " $1
    if [[ "${!1}" == "" ]]; then
        read $1 <<<"${default_value}"
    fi
}

# Check args
OS_PATH_NAME="${OS_VERSION}"
if [[ "${OS_VERSION}" =~ .*\..* ]]; then
    # delete the dot in os string
    OS_PATH_NAME="${OS_VERSION//./}"
fi

# set apt mirror
set_apt_mirror() {
    apt-get update &&
        apt-get install -y --no-install-recommends ca-certificates &&
        apt-get clean &&
        rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
    sed -i 's/ports.ubuntu.com/mirrors.sjtug.sjtu.edu.cn/g' /etc/apt/sources.list
    sed -i 's/archive.ubuntu.com/mirrors.sjtug.sjtu.edu.cn/g' /etc/apt/sources.list
    sed -i 's/archive.canonical.com/mirrors.sjtug.sjtu.edu.cn/g' /etc/apt/sources.list
    sed -i 's/security.ubuntu.com/mirrors.sjtug.sjtu.edu.cn/g' /etc/apt/sources.list
    sed -i 's/http:\/\/mirrors.sjtug.sjtu.edu.cn/https:\/\/mirrors.sjtug.sjtu.edu.cn/g' /etc/apt/sources.list
}

# Install requried libraries
install_base_libs() {
    apt-get update && apt-get install -y --no-install-recommends software-properties-common
    # add-apt-repository ppa:ubuntu-toolchain-r/test
    apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        wget \
        git \
        pkg-config \
        ssh \
        libssl-dev \
        pbzip2 \
        pv \
        bzip2 \
        unzip \
        devscripts \
        lintian \
        fakeroot \
        dh-make \
        build-essential \
        libyaml-cpp-dev
}

# install python3
install_python3() {
    apt-get update &&
        apt-get install -y --no-install-recommends \
            python3 \
            python3-pip \
            python3-dev \
            python3-wheel &&
        cd /usr/local/bin &&
        ln -sf /usr/bin/python3 python &&
        ln -sf /usr/bin/pip3 pip
    apt-get clean &&
        rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
    python3 -m pip install -U pip
}

# install extra tools
install_extra_tools() {
    apt-get update &&
        apt-get install -y --no-install-recommends \
            gawk \
            tmux \
            zsh \
            vim \
            htop \
            iotop \
            iftop \
            nvtop \
            powertop \
            tree \
            wget \
            git \
            curl \
            net-tools \
            gdb
}

# install zsh (not sudo)
install_zsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &&
        git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions &&
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &&
        git clone https://github.com/zsh-users/zsh-completions.git $HOME/.oh-my-zsh/custom/plugins/zsh-completions &&
        git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

    # set zsh as default shell
    chsh -s /bin/zsh
}

# install clangd via apt
install_clang_format() {
    apt-get update &&
        apt-get install -y --no-install-recommends clang-format isort flake8 &&
        apt-get install -y --no-install-recommends black || true &&
        apt-get install -y --no-install-recommends yapf || apt-get install -y --no-install-recommends yapf3 &&
        apt-get install -y --no-install-recommends clangd || apt-get install -y --no-install-recommends clangd-10 &&
        apt-get clean
}

# install nvidia drivers
install_nvidia_driver() {
    apt-get install linux-headers-$(uname -r)
    apt-key del 7fa2af80
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
    dpkg -i cuda-keyring_1.0-1_all.deb
    apt-get update
    apt-get -y install nvidia-driver-535 cuda-toolkit-11-8
}

# install nvidia tensorrt
install_nvidia_tensorrt() {
    v="${TRT_VERSION%.*}-1+cuda${CUDA_VERSION%.*}" &&
        apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/${OS_PATH_NAME}/$(uname -m)/3bf863cc.pub &&
        apt-get update &&
        apt-get install -y --no-install-recommends \
            libnvinfer8=${v} \
            libnvonnxparsers8=${v} \
            libnvparsers8=${v} \
            libnvinfer-plugin8=${v} \
            libnvinfer-dev=${v} \
            libnvonnxparsers-dev=${v} \
            libnvparsers-dev=${v} \
            libnvinfer-plugin-dev=${v} \
            python3-libnvinfer=${v}
}

# install cmake
install_cmake() {
    # install dependencies for SSL support
    apt-get install zlib1g-dev libssl-dev
    cd /tmp &&
        wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
    tar -xzvf cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}/

    # build cmake
    ./bootstrap --prefix=/usr/local # use system curl to enable SSL support
    make -j
    sudo make install

    # show cmake version
    cmake --version
}

# install catch2
install_catch2() {
    # get latest source code
    cd /tmp &&
        git clone https://github.com/catchorg/Catch2 &&
        cd Catch2 &&
        git checkout ${CATCH2_VERSION}

    # build and install
    cd /tmp/Catch2 &&
        mkdir build &&
        cd build &&
        cmake .. &&
        make install -j${NUM_THREADS}
}

# install absl
install_absl() {
    # get latest cmake source
    cd /tmp &&
        git clone https://github.com/abseil/abseil-cpp.git &&
        cd abseil-cpp &&
        git checkout ${ABSL_VERSION}

    # build cmake
    mkdir build && cd build &&
        cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON .. &&
        make -j${MAKE_JOBS} &&
        make install &&
        cd /tmp &&
        rm -rf abseil-cpp
}

#install opencv
install_opencv_desktop_gpu() {
    prompt_default OPENCV_VERSION "OpenCV Version [${OPENCV_VERSION}]"

    status "Install dependencies of OpenCV"
    apt update

    # install developer tools
    apt -yq install build-essential checkinstall cmake pkg-config
    apt -yq install git gfortran

    # install image I/O packages for loading various image file formats from disk
    apt -yq install libjpeg8-dev libjpeg-dev libpng-dev
    apt install libjasper1 libjasper-dev

    #  GTK development library to build Graphical User Interfaces
    apt -y install libgtk-3-dev libtbb-dev qt5-default

    apt-get install -yq \
        libglew-dev \
        libtiff5-dev \
        zlib1g-dev \
        libpostproc-dev \
        libeigen3-dev \
        libtbb-dev \
        unzip \
        libgoogle-glog-dev \
        libgflags-dev
    apt-get install -yq \
        ffmpeg \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libswscale-dev
    apt-get install -yq \
        libgstreamer1.0-0 \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-doc \
        gstreamer1.0-tools \
        gstreamer1.0-x \
        gstreamer1.0-alsa \
        gstreamer1.0-gl \
        gstreamer1.0-gtk3 \
        gstreamer1.0-qt5 \
        gstreamer1.0-pulseaudio \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgstreamer-plugins-bad1.0-dev
    apt -y install libv4l-dev libdc1394-22-dev
    apt -y install libatlas-base-dev
    apt -y install libfaac-dev libmp3lame-dev libtheora-dev
    apt -y install libxvidcore-dev libx264-dev
    apt -y install libopencore-amrnb-dev libopencore-amrwb-dev
    apt -y install libgphoto2-dev libeigen3-dev libhdf5-dev doxygen x264 v4l-utils
    apt-get install -yq python-dev python-numpy python-py python-pytest
    apt-get install -yq python3-dev python3-numpy python3-py python3-pytest

    status "Downloading source code of OpenCV"
    pushd ${TMP_DIR}
    if [[ ! -d "opencv-${OPENCV_VERSION}" ]]; then
        wget --no-check-certificate https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip -O opencv.zip
        unzip opencv.zip
    fi
    if [[ ! -d "opencv_contrib-${OPENCV_VERSION}" ]]; then
        wget --no-check-certificate https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip -O opencv_contrib.zip
        unzip opencv_contrib.zip
    fi

    status "Building OpenCV"
    cd opencv-${OPENCV_VERSION}
    mkdir -p build && cd build

    echo 'Build OpenCV on PC with CUDA'
    CUDA_ARCH="6.1"
    prompt_default CUDA_ARCH "CUDA Arch [${CUDA_ARCH}]"
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DBUILD_PNG=OFF \
        -DBUILD_TIFF=OFF \
        -DBUILD_TBB=OFF \
        -DBUILD_JPEG=OFF \
        -DBUILD_JASPER=OFF \
        -DBUILD_ZLIB=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_opencv_java=OFF \
        -DBUILD_opencv_python2=ON \
        -DBUILD_opencv_python3=ON \
        -DWITH_OPENCL=OFF \
        -DWITH_OPENMP=ON \
        -DWITH_FFMPEG=ON \
        -DWITH_GSTREAMER=ON \
        -DWITH_CUDA=ON \
        -DWITH_NVCUVID=OFF \
        -DWITH_CUBLAS=ON \
        -DENABLE_FAST_MATH=1 \
        -DCUDA_FAST_MATH=1 \
        -DWITH_GTK=ON \
        -DWITH_VTK=ON \
        -DWITH_TBB=ON \
        -DWITH_1394=OFF \
        -DWITH_OPENEXR=OFF \
        -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
        -DCUDA_ARCH_BIN=${CUDA_ARCH} \
        -DCUDA_ARCH_PTX="" \
        -DINSTALL_C_EXAMPLES=OFF \
        -DINSTALL_PYTHON_EXAMPLES=OFF \
        -DINSTALL_TESTS=OFF \
        -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules \
        -DOPENCV_ENABLE_NONFREE=ON \
        -DOPENCV_GENERATE_PKGCONFIG=YES \
        .. &&
        make -j6 &&
        make install
}

# install fmt
install_fmt() {
    # get latest source code
    cd /tmp &&
        git clone https://github.com/fmtlib/fmt &&
        cd fmt &&
        git checkout ${FMT_VERSION}

    # build cmake
    cmake -Bbuild -H. -DCMAKE_POSITION_INDEPENDENT_CODE=ON &&
        cmake --build build -j${NUM_THREADS} &&
        cmake --build build --target install &&
        cd /tmp &&
        rm -rf fmt
}

# install docker
install_docker() {
    # install docker
    curl https://get.docker.com | sh &&
        systemctl start docker &&
        systemctl enable docker

    # non-root user
    groupadd docker
    usermod -aG docker $USER
    warning "Please log out and log in to take effects"
    # docker run hello-world
}

install_nvidia_docker() {
    warning "Note that with the release of Docker 19.03, usage of nvidia-docker2 packages are deprecated since NVIDIA GPUs are now natively supported as devices in the Docker runtime. If you are an existing user of the nvidia-docker2 packages, use $(update_with_nvidia_docker2) function."
    # Add the package repositories
    distribution=$(
        . /etc/os-release
        echo $ID$VERSION_ID
    ) &&
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add - &&
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

    # Install the package
    apt-get update && apt-get install -y nvidia-docker2
    systemctl restart docker

    # Test nvidia-smi with the latest official CUDA image
    docker run --gpus all nvidia/cuda:11.0-base nvidia-smi
}

update_with_nvidia_docker2() {
    # On debian based distributions: Ubuntu / Debian
    apt-get update
    apt-get --only-upgrade install docker-ce nvidia-docker2
    systemctl restart docker

    # Test nvidia-smi with the latest official CUDA image
    docker run --gpus all nvidia/cuda:9.0-base nvidia-smi
}

# install tmux
install_tmux() {
    prompt_default TMUX_VERSION "Tmux Version [${TMUX_VERSION}]"
    prompt_default LIBEVENT_VERSION "Libevent Build [${LIBEVENT_VERSION}]"

    # uninstall installed tmux
    apt-get remove -y tmux
    apt-get remove -y 'libevent-*'

    # install libncurses
    apt-get install -y libncurses5-dev

    # download source
    pushd ${TMP_DIR}
    if [[ ! -d "tmux-${TMUX_VERSION}" ]]; then
        wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
        tar xvzf "tmux-${TMUX_VERSION}.tar.gz"
    fi

    if [[ ! -d "libevent-${LIBEVENT_VERSION}-stable" ]]; then
        wget "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz"
        tar xvzf "libevent-${LIBEVENT_VERSION}-stable.tar.gz"
    fi

    # install libevent
    cd "libevent-${LIBEVENT_VERSION}-stable"
    ./configure && make
    make install
    cd ..

    # build tmux and install
    cd "tmux-${TMUX_VERSION}"
    ./configure && make
    make install

    popd
}

# install colcon
install_colcon() {
    curl -s https://packagecloud.io/install/repositories/dirk-thomas/colcon/script.deb.sh | bash
    apt install python3-colcon-common-extensions ccache
}

#install gstreamer
install_gstreamer() {
    apt-get install \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-tools \
        gstreamer1.0-rtsp \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        libgstrtspserver-1.0-dev
}

# install ecal
install_ecal() {
    apt install libprotobuf-dev protobuf-compiler
    add-apt-repository ppa:ecal/ecal-latest
    apt-get update
    apt-get install ecal
}

# install ros1
install_ros1() {
    apt-get update &&
        apt-get install -q -y --no-install-recommends dirmngr gnupg2 lsb-core curl

    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
    if [ "x${USE_MIRROR}" = "xtrue" ]; then
        echo "Use mirror for ROS installation"
        echo "deb https://mirrors.sjtug.sjtu.edu.cn/ros/ubuntu $(lsb_release -sc) main" >/etc/apt/sources.list.d/ros-latest.list
    else
        echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" >/etc/apt/sources.list.d/ros1-latest.list
    fi

    if [ "x${ROS1_PYTHON}" = "xpython2" ]; then
        apt-get update &&
            apt-get install --no-install-recommends -y \
                python-rosdep \
                python-rosinstall \
                python-vcstools
    else
        apt-get update &&
            apt-get install --no-install-recommends -y \
                python3-rosdep \
                python3-rosinstall \
                python3-vcstools
    fi

    rosdep init &&
        rosdep update --rosdistro "${ROS1_DISTRO}"

    apt-get update &&
        apt-get install -q -y ros-"${ROS1_DISTRO}"-${ROS1_METAPACKAGE} \
            ros-"${ROS1_DISTRO}"-camera-calibration-parsers \
            ros-"${ROS1_DISTRO}"-camera-info-manager \
            ros-"${ROS1_DISTRO}"-cv-bridge \
            ros-"${ROS1_DISTRO}"-vision-opencv \
            ros-"${ROS1_DISTRO}"-vision-msgs \
            ros-"${ROS1_DISTRO}"-image-geometry \
            ros-"${ROS1_DISTRO}"-image-pipeline \
            ros-"${ROS1_DISTRO}"-image-transport \
            ros-"${ROS1_DISTRO}"-compressed-image-transport \
            ros-"${ROS1_DISTRO}"-compressed-depth-image-transport \
            ros-"${ROS1_DISTRO}"-grid-map \
            ros-"${ROS1_DISTRO}"-pcl-conversions \
            ros-"${ROS1_DISTRO}"-pcl-ros

    python3 -m pip install -U pip
    python3 -m pip install -U colcon-common-extensions vcstool
}

# install ros2
install_ros2() {
    # Ensure the script is run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root" >&2
        exit 1
    fi

    # Determine OS Distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi

    apt-get update
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        gnupg2 \
        lsb-release \
        ca-certificates

    # add the ROS deb repo to the apt sources list
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list >/dev/null

    # install development packages
    apt-get update
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libbullet-dev \
        libpython3-dev \
        python3-flake8 \
        python3-pip \
        python3-numpy \
        python3-pytest-cov \
        python3-rosdep \
        python3-setuptools \
        python3-rosinstall-generator \
        libasio-dev \
        libtinyxml2-dev \
        libcunit1-dev
    python3 -m pip install -U colcon-common-extensions vcstool

    # install some pip packages needed for testing
    pip3 install --upgrade --no-cache-dir \
        argcomplete \
        flake8-blind-except \
        flake8-builtins \
        flake8-class-newline \
        flake8-comprehensions \
        flake8-deprecated \
        flake8-docstrings \
        flake8-import-order \
        flake8-quotes \
        pytest-repeat \
        pytest-rerunfailures \
        pytest

    # build ros2
    # create the ROS2_ROOT directory
    mkdir -p ${ROS2_ROOT}/src
    cd ${ROS2_ROOT}

    # download ROS sources
    # https://answers.ros.org/question/325245/minimal-ros2-installation/?answer=325249#post-id-325249
    rosinstall_generator --deps --rosdistro ${ROS2_DISTRO} ${ROS2_METAPACKAGE} \
        launch_xml \
        launch_yaml \
        launch_testing \
        launch_testing_ament_cmake \
        demo_nodes_cpp \
        demo_nodes_py \
        example_interfaces \
        camera_calibration_parsers \
        camera_info_manager \
        cv_bridge \
        v4l2_camera \
        vision_opencv \
        vision_msgs \
        image_geometry \
        image_pipeline \
        image_transport \
        compressed_image_transport \
        compressed_depth_image_transport \
        grid_map \
        pcl_conversions \
        pcl_ros \
        >ros2.${ROS2_DISTRO}.${ROS2_METAPACKAGE}.rosinstall
    cat ros2.${ROS2_DISTRO}.${ROS2_METAPACKAGE}.rosinstall
    vcs import src <ros2.${ROS2_DISTRO}.${ROS2_METAPACKAGE}.rosinstall

    # use latest ament_cmake to support new CMake
    rm -r ${ROS2_ROOT}/src/ament_cmake
    git -C ${ROS2_ROOT}/src/ clone https://github.com/ament/ament_cmake -b ${ROS2_DISTRO}

    # skip installation of some conflicting packages
    echo "--skip-keys $SKIP_KEYS"

    # install dependencies using rosdep
    rosdep init
    rosdep update
    rosdep install -y \
        --ignore-src \
        --from-paths src \
        --rosdistro ${ROS2_DISTRO} \
        --skip-keys "$SKIP_KEYS"

    # build it all
    colcon build \
        --merge-install \
        --cmake-args -DCMAKE_BUILD_TYPE=Release

    # remove build files
    rm -rf ${ROS2_ROOT}/src
    rm -rf ${ROS2_ROOT}/logs
    rm -rf ${ROS2_ROOT}/build
    rm ${ROS2_ROOT}/*.rosinstall
}

# install gcc
install_gcc() {
    # update apt repositories
    apt-get update
    apt-get install software-properties-common
    add-apt-repository -y ppa:ubuntu-toolchain-r/test
    apt-get update

    # install newer gcc toolchain
    apt-get install -q -y --no-install-recommends gcc-${GCC_VERSION} g++-${GCC_VERSION}

    # set newly installed gcc as default
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 700 --slave /usr/bin/g++ g++ /usr/bin/g++-7
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 800 --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION}
}

# install ceres
install_ceres() {
    apt-get update
    apt-get install -q -y libgoogle-glog-dev libgflags-dev libatlas-base-dev libeigen3-dev
    apt-get clean

    # get latest source
    cd /tmp
    git clone https://github.com/ceres-solver/ceres-solver
    cd ceres-solver
    git checkout ${CERES_VERSION}

    # build and install
    mkdir build && cd build
    cmake ..
    make -j${NUM_THREADS}
    make install

    # clean
    cd /tmp
    rm -rf ceres-solver
}

# install doxygen
install_doxygen() {
    apt-get update
    apt-get install -y graphviz bison flex cmake build-essential
    apt-get clean

    # Get latest source code
    cd /tmp
    git clone https://github.com/doxygen/doxygen.git -b ${DOXYGEN_VERSION}
    cd doxygen

    # Build doxygen
    mkdir build
    cd build
    cmake -G "Unix Makefiles" ..
    make -j${NUM_THREADS}
    make install

    # Clean up
    cd /tmp
    rm -rf doxygen
}

# install geographiclib
install_geographiclib() {
    # get latest cmake source
    cd /tmp &&
        git clone https://github.com/geographiclib/geographiclib &&
        cd geographiclib &&
        git checkout ${GEOGRAPHICLIB_VERSION}

    # build cmake
    mkdir build && cd build &&
        cmake .. &&
        make -j${NUM_THREADS} &&
        make install &&
        cd /tmp &&
        rm -rf geographiclib
}

# install gtsam
install_gtsam() {
    # get latest source
    cd /tmp
    git clone https://github.com/borglab/gtsam.git
    cd gtsam
    git checkout ${GTSAM_VERSION}

    # build and install
    mkdir build && cd build
    cmake -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF ..
    make -j${NUM_THREADS}
    make install

    # clean
    cd /tmp
    rm -rf gtsam
}

# install proj
install_proj() {
    apt-get update
    apt-get install -q -y --no-install-recommends sqlite3 libsqlite3-dev curl libcurl4-openssl-dev
    apt-get clean
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

    # Get latest source code
    cd /tmp
    wget https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
    tar -xzf proj-${PROJ_VERSION}.tar.gz

    # Build proj
    cd proj-${PROJ_VERSION}
    cmake -Bbuild -H. -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_TESTING=OFF
    cmake --build build -j${NUM_THREADS}
    cmake --build build --target install

    # Clean up
    cd /tmp && rm -rf proj-${PROJ_VERSION} proj-${PROJ_VERSION}.tar.gz
}

# install sophus
install_sophus() {
    # get latest source
    cd /tmp
    git clone https://github.com/strasdat/Sophus.git
    cd Sophus
    git checkout ${SOPHUS_VERSION}

    # build and install
    mkdir build && cd build
    cmake .. -DBUILD_SOPHUS_TESTS=OFF
    make -j${NUM_THREADS}
    make install

    # clean
    cd /tmp
    rm -rf Sophus
}

# install c-periphery
install_c_periphery() {
    cd /tmp
    git clone https://github.com/vsergeev/c-periphery.git
    cd c-periphery
    git checkout ${C_PERIPHERY_VERSION}
    mkdir build
    cd build
    cmake -DBUILD_SHARED_LIBS=ON ..
    make -j${NUM_THREADS}
    make install

    # clean
    cd /tmp
    rm -rf c-periphery
}

# install libsocketcan
install_socketcan() {
    apt install can-utils libsocketcan-dev libasio-dev
}

# install bluetooth
install_bluetooth() {
    apt-get install libbluetooth-dev
    apt-get install libdbus-1-dev
}

confirm set_apt_mirror "Set apt mirror"
confirm install_base_libs "Install base libs"
confirm install_python3 "Install python3"
confirm install_extra_tools "Install extra tools"
confirm install_zsh "Install zsh [do not sudo]"
confirm install_clang_format "Install clang format tools"
confirm install_nvidia_driver "Install nvidia driver"
confirm install_nvidia_tensorrt "Install nvidia tensorrt"
confirm install_cmake "Install cmake"
confirm install_catch2 "Install catch2"
confirm install_absl "Install absl"
confirm install_opencv_desktop_gpu "Install opencv with gpu"
confirm install_fmt "Install fmt"
confirm install_docker "Install docker"
confirm install_nvidia_docker "Install nvidia-docker"
confirm install_tmux "Install tmux"
confirm install_colcon "Install colcon"
confirm install_gstreamer "Install gstreamer"
confirm install_ecal "Install ecal"
confirm install_ros1 "Install ros1"
confirm install_ros2 "Install ros2"
confirm install_gcc "Install gcc"
confirm install_ceres "Install ceres"
confirm install_doxygen "Install doxygen"
confirm install_geographiclib "Install geographiclib"
confirm install_gtsam "Install gtsam"
confirm install_proj "Install proj"
confirm install_sophus "Install sophus"
confirm install_c_periphery "Install c_periphery"
confirm install_socketcan "Install socketcan"
confirm install_bluetooth "Install bluetooth"
echo "Successfully installed all dependencies."

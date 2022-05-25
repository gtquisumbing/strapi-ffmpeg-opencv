FROM stockpickle/base as strapi-opencv

ARG OPENCV_VERSION=4.5.2
ARG WITH_CONTRIB=1
ARG BUILD_WORLD=1
ARG BUILD_LIST=''

#MAKE ffmpeg
######################################################################################################################
################################################# INSTALLING FFMPEG ##################################################
RUN apt-get update ; apt-get install -y git build-essential gcc make yasm autoconf automake cmake libtool checkinstall libmp3lame-dev pkg-config libunwind-dev zlib1g-dev libssl-dev libswresample-dev

RUN apt-get update \
  && apt-get clean \
  && apt-get install -y --no-install-recommends libc6-dev libgdiplus wget software-properties-common

RUN apt-get install -y libx264-dev

#RUN RUN apt-add-repository ppa:git-core/ppa && apt-get update && apt-get install -y git

RUN wget https://www.ffmpeg.org/releases/ffmpeg-4.3.3.tar.gz --no-check-certificate
RUN tar -xzf ffmpeg-4.3.3.tar.gz; rm -r ffmpeg-4.3.3.tar.gz
RUN cd ./ffmpeg-4.3.3; ./configure --enable-gpl --enable-libmp3lame --enable-decoder=mjpeg,png --enable-encoder=png --enable-openssl --enable-nonfree --enable-shared --enable-libx264


RUN cd ./ffmpeg-4.3.3; make
RUN  cd ./ffmpeg-4.3.3; make install

#MAKE OPENCV
RUN cmake_flags="-D CMAKE_BUILD_TYPE=RELEASE \
  -D BUILD_PERF_TESTS=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_opencv_apps=OFF \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local" && \
  if [ -n "$WITH_CONTRIB" ]; then \
  cmake_flags="$cmake_flags -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules -D OPENCV_ENABLE_NONFREE=ON"; \
  fi && \
  if [ -n "$BUILD_WORLD" ]; then \
  cmake_flags="$cmake_flags -D BUILD_opencv_world=ON"; \
  fi && \
  if [ -n "$BUILD_LIST" ]; then \
  cmake_flags="$cmake_flags -D BUILD_LIST=$BUILD_LIST"; \
  fi && \
  echo "cmake_flags: $cmake_flags" && \
  apt-get update && \
  apt-get install -y --no-install-recommends build-essential curl wget unzip cmake && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir opencv && \
  cd opencv && \
  wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip --no-check-certificate -O opencv-${OPENCV_VERSION}.zip && \
  unzip opencv-${OPENCV_VERSION}.zip && \
  if [ -n "$WITH_CONTRIB" ]; then \
  wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip --no-check-certificate -O opencv_contrib-${OPENCV_VERSION}.zip; \
  unzip opencv_contrib-${OPENCV_VERSION}.zip; \
  fi && \
  mkdir opencv-${OPENCV_VERSION}/build && \
  cd opencv-${OPENCV_VERSION}/build && \
  cmake $cmake_flags .. && \
  make -j $(nproc) && \
  make install && \
  sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf' && \
  ldconfig && \
  cd ../../../ && \
  rm -rf opencv && \
  apt-get purge -y build-essential curl wget unzip cmake && \
  apt-get autoremove -y --purge

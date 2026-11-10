# syntax=docker/dockerfile:1
# The Docker Hub linuxserver/transmission:latest manifest at the time of this build.
FROM linuxserver/transmission:latest@sha256:fb8fe625941cf15eb69aba4e5c0a678e035ddb11605fd85af4516a4e641f2687 AS runtime

RUN apk add --no-cache --upgrade libcurl libssl3 libcrypto3 libpsl libgcc libstdc++

FROM runtime AS build
RUN apk add --no-cache build-base cmake ninja pkgconf curl-dev openssl-dev libpsl-dev linux-headers
WORKDIR /src
COPY . .
ARG SOURCE_REVISION
RUN test -n "${SOURCE_REVISION}" && printf '%s\n' "${SOURCE_REVISION}" > REVISION && \
    cmake -S . -B /build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
      -DENABLE_GTK=OFF -DENABLE_QT=OFF -DENABLE_MAC=OFF \
      -DENABLE_CLI=ON -DENABLE_TESTS=OFF -DINSTALL_DOC=OFF \
      -DREBUILD_WEB=OFF -DUSE_SYSTEM_DEFAULT=OFF -DUSE_SYSTEM_PSL=ON \
      -DWITH_CRYPTO=openssl -DRUN_CLANG_TIDY=OFF && \
    cmake --build /build --parallel 3 && \
    DESTDIR=/install cmake --install /build --strip

FROM runtime
ARG SOURCE_REVISION
LABEL org.opencontainers.image.source="https://github.com/SoiledBrush/transmission" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.description="LinuxServer Transmission with upstream pull request 9103"
COPY --from=build /install/usr/bin/ /usr/bin/
COPY --from=build /install/usr/share/transmission/ /usr/share/transmission/
COPY --from=build /src/COPYING /usr/share/licenses/transmission/COPYING
RUN /usr/bin/transmission-daemon --version && /usr/bin/transmission-remote --version

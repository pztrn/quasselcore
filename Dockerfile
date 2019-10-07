FROM alpine:3.10 as build-stage

# build time arguements
ARG CXXFLAGS="\
	-D_FORTIFY_SOURCE=2 \
	-Wp,-D_GLIBCXX_ASSERTIONS \
	-fstack-protector-strong \
	-fPIE -pie -Wl,-z,noexecstack \
	-Wl,-z,relro -Wl,-z,now"

# install build packages
RUN \
	apk add --no-cache \
	boost \
	boost-dev \
	cmake \
	curl \
	dbus-dev \
	g++ \
	gcc \
	git \
	icu-dev \
	icu-libs \
	jq \
	openssl-dev \
	openldap-dev \
	make \
	paxmark \
	qt5-qtbase-dev \
	qt5-qtscript-dev \
	qt5-qtbase-postgresql \
	qt5-qtbase-sqlite

# fetch source
RUN \
	mkdir -p \
	/tmp/quassel-src && \
	cd /tmp/quassel-src && \
	git clone https://github.com/quassel/quassel .

# build package
RUN \
	mkdir /tmp/quassel-src/build && \
	cd /tmp/quassel-src/build && \
	cmake \
	-DCMAKE_BUILD_TYPE="Release" \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DUSE_QT5=ON \
	-DWANT_CORE=ON \
	-DWANT_MONO=OFF \
	-DWANT_QTCLIENT=OFF \
	-DWITH_KDE=OFF \
	/tmp/quassel-src && \
	make -j4 && \
	make DESTDIR=/build/quassel install && \
	paxmark -m /build/quassel/usr/bin/quasselcore

FROM alpine:3.10

# set environment variables
ENV HOME /config

# install runtime packages
RUN \
	apk add --no-cache \
	icu-libs \
	openssl \
	qt5-qtbase \
	qt5-qtbase-postgresql \
	qt5-qtbase-sqlite \
	qt5-qtscript

# copy artifacts build stage
COPY --from=build-stage /build/quassel/usr/bin/ /usr/bin/
COPY --from=build-stage /build/quassel/usr/lib64/ /usr/lib/

# ports and volumes
VOLUME /config
EXPOSE 4242 10113

ENTRYPOINT ["/usr/bin/quasselcore", "--configdir=/config"]

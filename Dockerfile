FROM alpine:3.8 as berkeleydb

RUN echo start1
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

FROM alpine:3.10 as qt-dev

COPY --from=berkeleydb /opt /opt
RUN apk --no-cache add tree
RUN tree /opt/

RUN apk --no-cache add gcc
RUN apk --no-cache add g++
RUN apk --no-cache add libc-dev
RUN apk --no-cache add boost-dev
RUN apk --no-cache add openssl-dev
RUN apk --no-cache add zlib-dev
RUN apk --no-cache add qt5-qtbase-dev
RUN apk --no-cache add miniupnpc-dev
RUN apk --no-cache add make

RUN cp -avR /opt/db-4.8.30.NC/include/* /usr/include/
RUN cp -avR /opt/db-4.8.30.NC/lib/* /usr/lib/

ADD src /bitbay-seeder

WORKDIR /bitbay-seeder

RUN ls -al

RUN qmake-qt5 -v && \
          ls -al && \
          qmake-qt5 \
            CICD=travis_x64 \
            bitbay-seeder.pro && \
          sed -i 's/\/usr\/lib\/libssl.so/-lssl/' Makefile && \
          sed -i 's/\/usr\/lib\/libcrypto.so/-lcrypto/' Makefile && \
          echo sed -i s:sys/fcntl.h:fcntl.h: src/compat.h && \
          make -j4

RUN ldd bitbay-seeder

FROM alpine:3.10
COPY --from=qt-dev /bitbay-seeder/bitbay-seeder /usr/bin/

RUN apk --no-cache add libstdc++
RUN apk --no-cache add boost-thread
RUN apk --no-cache add boost-chrono
RUN apk --no-cache add boost-system
RUN apk --no-cache add boost-filesystem
RUN apk --no-cache add boost-program_options
RUN apk --no-cache add openssl
RUN apk --no-cache add zlib
RUN apk --no-cache add miniupnpc

RUN ldd /usr/bin/bitbay-seeder
#RUN bitbay-seeder --help || echo end

ENV RPC_USER bitbayrpc
ENV RPC_PASS pegforever

ENTRYPOINT ["/usr/bin/bitbay-seeder"]


# escape=`

#YES I DID COPY FROM GE SOURCE

FROM lacledeslan/steamcmd:linux as tf2classic-builder

ARG ftpServer=content.lacledeslan.net

RUN apt-get update && apt-get install -y dos2unix && apt-get clean

# Copy cached build files (if any)
COPY ./build-cache /output

# Download TF2 CLASSIC server files
RUN echo "Downloading TF2 CLASSIC from LL public ftp server" &&`
        mkdir --parents /tmp/ &&`
		curl -sSL "http://${ftpServer}/fastDownloads/_installers/TF2Classic2.0.0.7z" -o /tmp/TF2Classic2.0.0.7z &&`
    echo "Validating download against known hash" &&`
        echo "ECE5066028BBA3C390474144B2590493 /tmp/TF2Classic2.0.0.7z" | sha256sum -c - &&`
	echo "Extracting TF2 CLASSIC files" &&`
		7z x -o/output/ /tmp/TF2Classic2.0.0.7z &&`
		rm -f /tmp/*.7z

# Download Source 2013 Dedicated Server
RUN /app/steamcmd.sh +login anonymous +force_install_dir /output/srcds2013 +app_update 244310  validate +quit;

COPY ./linuxify.sh /linuxify.sh

RUN chmod +x /linuxify.sh && /linuxify.sh &&`
    /linuxify.sh;

#=======================================================================
FROM debian:stretch-slim

ARG BUILDNODE=unspecified
ARG SOURCE_COMMIT=unspecified

HEALTHCHECK NONE

RUN dpkg --add-architecture i386 &&`
    apt-get update && apt-get install -y `
        ca-certificates lib32gcc1 lib32tinfo5 libcurl4-gnutls-dev:i386 libstdc++6 libstdc++6:i386 libtcmalloc-minimal4:i386 locales locales-all tmux zlib1g:i386 &&`
    apt-get clean &&`
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment &&`
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*;

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

LABEL com.lacledeslan.build-node=$BUILDNODE `
      org.label-schema.schema-version="1.0" `
      org.label-schema.url="https://github.com/LacledesLAN/README.1ST" `
      org.label-schema.vcs-ref=$SOURCE_COMMIT `
      org.label-schema.vendor="Laclede's LAN" `
      org.label-schema.description="TF2 CLASSIC Dedicated Server" `
      org.label-schema.vcs-url="https://github.com/LacledesLAN/gamesvr-TF2CLASSIC"

# Set up Enviornment
RUN useradd --home /app --gid root --system TF2CLASSIC &&`
    mkdir -p /app/TF2CLASSIC/logs &&`
    mkdir -p /app/ll-tests &&`
    chown TF2CLASSIC:root -R /app;

COPY --chown=TF2CLASSIC:root --from=tf2classic-builder /output/srcds2013 /app

COPY --chown=TF2CLASSIC:root --from=tf2classic-builder /output/TF2CLASSIC /app/TF2CLASSIC

COPY --chown=TF2CLASSIC:root ./ll-tests /app/ll-tests

ENV MALLOC_CHECK_=0

RUN chmod +x /app/ll-tests/*.sh &&`
	/app/bin/ln -s scenefilecache_srv.so scenefilecache.so &&`
	/app/bin/ln -s vphysics_srv.so vphysics.so &&`
	/app/bin/ln -s studiorender_srv.so studiorender.so &&`
	/app/bin/ln -s soundemittersystem_srv.so soundemittersystem.so &&`
	/app/bin/ln -s shaderapiempty_srv.so shaderapiempty.so &&`
	/app/bin/ln -s scenefilecache_srv.so scenefilecache.so &&`
	/app/bin/ln -s replay_srv.so replay.so &&`
	/app/bin/ln -s materialsystem_srv.so materialsystem.so &&`

USER TF2CLASSIC

WORKDIR /app

CMD ["/bin/bash"]

ONBUILD USER root

FROM debian:bullseye-slim

LABEL maintainer "Tomas Adomavicius <tomas@adomavicius.com>"

ARG steam_user=anonymous
ARG steam_password=
ARG metamod_version=1.20
ARG amxmod_version=1.8.2

# إصلاح روابط التحديث وتثبيت المكتبات الضرورية (بما في ذلك مكتبات 32 بت اللازمة لـ HLDS)
RUN apt update && apt install -y \
    lib32gcc-s1 \
    curl \
    tar \
    lib32stdc++6 \
    lib32z1 \
    && rm -rf /var/lib/apt/lists/*

# Install SteamCMD
RUN mkdir -p /opt/steam && cd /opt/steam && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Install HLDS
RUN mkdir -p /opt/hlds
# Workaround for "app_update 90" bug
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 90 validate +quit || \ 
    /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 90 validate +quit
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 70 validate +quit || :

RUN mkdir -p ~/.steam && ln -s /opt/hlds ~/.steam/sdk32
RUN ln -s /opt/steam/ /opt/hlds/steamcmd

# إضافة الملفات (تأكد أن هذه الملفات موجودة في المجلد بجانب الـ Dockerfile في Coolify)
ADD files/steam_appid.txt /opt/hlds/steam_appid.txt
ADD hlds_run.sh /bin/hlds_run.sh
RUN chmod +x /bin/hlds_run.sh

# Add maps
ADD maps/* /opt/hlds/valve/maps/

# Install metamod
RUN mkdir -p /opt/hlds/valve/addons/metamod/dlls
RUN curl -sqL "https://freefr.dl.sourceforge.net/project/metamod/Metamod%20Binaries/$metamod_version/metamod-$metamod_version-linux.tar.gz" | tar -C /opt/hlds/valve/addons/metamod/dlls -zxvf -
ADD files/liblist.gam /opt/hlds/valve/liblist.gam
ADD files/plugins.ini /opt/hlds/valve/addons/metamod/plugins.ini

# Install dproto
RUN mkdir -p /opt/hlds/valve/addons/dproto
ADD files/dproto_i386.so /opt/hlds/valve/addons/dproto/dproto_i386.so
ADD files/dproto.cfg /opt/hlds/valve/dproto.cfg

# Install AMX mod X
RUN curl -sqL "https://www.amxmodx.org/release/amxmodx-$amxmod_version-base-linux.tar.gz" | tar -C /opt/hlds/valve/ -zxvf -
ADD files/maps.ini /opt/hlds/valve/addons/amxmodx/configs/maps.ini

WORKDIR /opt/hlds

ENTRYPOINT ["/bin/hlds_run.sh"]

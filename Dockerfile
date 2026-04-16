FROM debian:bullseye-slim

LABEL maintainer="Tomas Adomavicius <tomas@adomavicius.com>"

ARG steam_user=anonymous
ARG steam_password=
ARG metamod_version=1.20
ARG amxmod_version=1.8.2

# أضفنا حزمة sed لتنظيف الملفات
RUN apt update && apt install -y \
    lib32gcc-s1 \
    curl \
    tar \
    lib32stdc++6 \
    lib32z1 \
    ca-certificates \
    sed \
    && rm -rf /var/lib/apt/lists/*

# Install SteamCMD
RUN mkdir -p /opt/steam && cd /opt/steam && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Install HLDS
RUN mkdir -p /opt/hlds
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 90 validate +quit || \
    /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 90 validate +quit
RUN /opt/steam/steamcmd.sh +login $steam_user $steam_password +force_install_dir /opt/hlds +app_update 70 validate +quit || :

RUN mkdir -p ~/.steam && ln -s /opt/hlds ~/.steam/sdk32
RUN ln -s /opt/steam/ /opt/hlds/steamcmd

ADD files/steam_appid.txt /opt/hlds/steam_appid.txt
ADD hlds_run.sh /bin/hlds_run.sh

# --- الإصلاح السحري هنا ---
# هذا الأمر يقوم بحذف أي \r مخفية في ملف التشغيل ليعمل على لينكس
RUN sed -i 's/\r$//' /bin/hlds_run.sh && chmod +x /bin/hlds_run.sh

ADD maps/* /opt/hlds/valve/maps/

# Install metamod
RUN mkdir -p /opt/hlds/valve/addons/metamod/dlls && \
    curl -sqL "https://github.com/theAsmodai/metamod-p/releases/download/v1.21p38/metamod_i386.so" -o /opt/hlds/valve/addons/metamod/dlls/metamod.so

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

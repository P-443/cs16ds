FROM debian:bullseye-slim

LABEL maintainer="Arsenik <developer@coolify.io>"

ARG steam_user=anonymous
ARG steam_password=
ARG metamod_version=1.21p38
ARG amxmod_version=1.8.2

# تنصيب الحزم الأساسية
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
RUN /opt/steam/steamcmd.sh +force_install_dir /opt/hlds +login anonymous +app_update 90 validate +quit || \
    /opt/steam/steamcmd.sh +force_install_dir /opt/hlds +login anonymous +app_update 90 validate +quit
RUN /opt/steam/steamcmd.sh +force_install_dir /opt/hlds +login anonymous +app_update 70 validate +quit || :

RUN mkdir -p ~/.steam && ln -s /opt/hlds ~/.steam/sdk32
RUN ln -s /opt/steam/ /opt/hlds/steamcmd

# إضافة ملفات الإعدادات والتشغيل من GitHub
ADD files/steam_appid.txt /opt/hlds/steam_appid.txt
ADD hlds_run.sh /bin/hlds_run.sh
RUN sed -i 's/\r$//' /bin/hlds_run.sh && chmod +x /bin/hlds_run.sh

# تجهيز مجلد cstrike والملفات المطلوبة
RUN mkdir -p /opt/hlds/cstrike/addons/metamod/dlls && \
    mkdir -p /opt/hlds/cstrike/addons/dproto && \
    mkdir -p /opt/hlds/cstrike/maps

# --- الإصلاح الجذري لمشكلة "file too short" ---
# بدلاً من تحميله، سنقوم بنسخ Metamod من مجلد valve (إذا كان موجوداً) 
# أو تحميله برابط مباشر ومختلف لضمان السلامة
RUN curl -L "https://github.com/theAsmodai/metamod-p/releases/download/v1.21p38/metamod_i386.so" -o /opt/hlds/cstrike/addons/metamod/dlls/metamod.so

# إضافة الإعدادات (تأكد من وجود dproto_i386.so في مجلد files بمستودعك)
ADD files/liblist.gam /opt/hlds/cstrike/liblist.gam
ADD files/plugins.ini /opt/hlds/cstrike/addons/metamod/plugins.ini
ADD files/dproto_i386.so /opt/hlds/cstrike/addons/dproto/dproto_i386.so
ADD files/dproto.cfg /opt/hlds/cstrike/dproto.cfg

# تنصيب AMX Mod X وفكه داخل cstrike
RUN curl -L "https://www.amxmodx.org/release/amxmodx-$amxmod_version-base-linux.tar.gz" | tar -C /opt/hlds/cstrike/ -zxvf -

# التأكد من تفعيل Metamod في liblist.gam
RUN sed -i 's/gamedll_linux "dlls\/cs.so"/gamedll_linux "addons\/metamod\/dlls\/metamod.so"/g' /opt/hlds/cstrike/liblist.gam

WORKDIR /opt/hlds

# صلاحيات التنفيذ للمكتبات (تأكد من الحجم هنا)
RUN ls -lh /opt/hlds/cstrike/addons/metamod/dlls/metamod.so && \
    chmod +x /opt/hlds/cstrike/addons/metamod/dlls/metamod.so && \
    chmod +x /opt/hlds/cstrike/addons/dproto/dproto_i386.so

ENTRYPOINT ["/bin/hlds_run.sh"]

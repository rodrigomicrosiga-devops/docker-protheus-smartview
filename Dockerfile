FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

USER root

# 1. Instala infraestrutura, fontes e o SYSTEMD (obrigatório para o Type=notify da ferramenta)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    fontconfig \
    fontconfig-config \
    xfonts-utils \
    cabextract \
    curl \
    libgdiplus \
    systemd \
    systemd-sysv \
    && echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections \
    && sed -i 's/main/main contrib/g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update && apt-get install -y ttf-mscorefonts-installer \
    && rm -rf /var/lib/apt/lists/*

# Limpa alvos desnecessários do systemd para otimizar o container
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/*

# 2. Download e Instalação de todos os formatos do NotoSans
RUN wget -O /tmp/noto-sans.zip https://github.com/notofonts/latin-greek-cyrillic/releases/download/NotoSans-v2.014/NotoSans-v2.014.zip \
    && unzip /tmp/noto-sans.zip -d /tmp/noto-sans \
    && mkdir -p /usr/share/fonts/noto-sans \
    && find /tmp/noto-sans -type f \( -name "*.ttf" -o -name "*.woff" -o -name "*.woff2" \) -exec cp {} /usr/share/fonts/noto-sans \; \
    && fc-cache -f -v \
    && rm -rf /tmp/noto-sans /tmp/noto-sans.zip

# 3. Preparação e extração do instalador na pasta oficial
RUN mkdir -p /usr/sbin/smart-view
WORKDIR /usr/sbin/smart-view

COPY 3.9.0.4558336-linux-x64.zip /usr/sbin/smart-view/smartview.zip

RUN chmod 777 smartview.zip \
    && unzip -o smartview.zip \
    && rm -f smartview.zip

# 4. Criação do arquivo de serviço apontando para o binário real do pacote (TReports.Agent)
RUN echo "[Unit]\n\
Description=smart-view-agent\n\
\n\
[Service]\n\
Type=notify\n\
WorkingDirectory=/usr/sbin/smart-view\n\
ExecStart=/usr/sbin/smart-view/TReports.Agent --urls http://*:7019\n\
\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/smart-view-agent.service

# Habilita o serviço no Systemd do container
RUN systemctl enable smart-view-agent.service

EXPOSE 7019

# Ponto de entrada gerenciado pelo Systemd como PID 1
ENTRYPOINT ["/lib/systemd/systemd"]
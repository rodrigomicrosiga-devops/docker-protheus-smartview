FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

USER root

# 1. Instala infraestrutura essencial, fontes e o SYSTEMD em camada única limpa
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    && apt-get update && apt-get install -y --no-install-recommends ttf-mscorefonts-installer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Limpa alvos desnecessários do systemd para otimizar o container
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/*

# 2. Download e Instalação otimizada das fontes NotoSans (Extrai apenas os TTFs essenciais)
RUN wget -q -O /tmp/noto-sans.zip https://github.com/notofonts/latin-greek-cyrillic/releases/download/NotoSans-v2.014/NotoSans-v2.014.zip \
    && mkdir -p /usr/share/fonts/noto-sans \
    && unzip -j /tmp/noto-sans.zip "*NotoSans-Regular.ttf" "*NotoSans-Bold.ttf" "*NotoSans-Italic.ttf" "*NotoSans-BoldItalic.ttf" -d /usr/share/fonts/noto-sans \
    && fc-cache -f -v \
    && rm -f /tmp/noto-sans.zip

# 3. Extração Direta do Instalador (Padrão Antipattern de Cópia resolvido)
RUN mkdir -p /usr/sbin/smart-view
WORKDIR /usr/sbin/smart-view

# Copiamos o ZIP para uma pasta temporária do Docker para não sujar a camada final
COPY 3.9.0.4558336-linux-x64.zip /tmp/smartview.zip

# Descompacta diretamente no local final e limpa o zip na MESMA instrução para não gerar histórico de peso
RUN unzip -o /tmp/smartview.zip -d /usr/sbin/smart-view/ \
    && rm -f /tmp/smartview.zip

# 4. Criação do arquivo de serviço do Systemd (TReports.Agent)
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
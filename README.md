Repositório oficial para a criação e publicação da imagem Docker isolada do **TOTVS SmartView**, o motor moderno de relatórios, visões e dashboards do ecossistema TOTVS Protheus. 

Esta imagem foi projetada sob os pilares de robustez e conformidade técnica, tratando o componente como um cidadão de primeira classe em arquiteturas Cloud Native.

## 🚀 Diferenciais da Imagem

* **Runtime Consolidado:** Suporte nativo ao ciclo de vida exigido pelo binário da TOTVS (`Type=notify`), rodando de forma blindada sob o gerenciamento do **Systemd** como PID 1.
* **Renderização Perfeita:** Instalação massiva e automatizada das fontes obrigatórias `NotoSans` (em todos os seus formatos: TTF, WOFF, WOFF2) e do pacote `ttf-mscorefonts-installer` (com aceitação automática da licença Microsoft EULA).
* **Camada Fina de Bordas:** Base de imagem otimizada utilizando `debian:12-slim`.

## 🛠️ Pré-requisitos

Para que o Systemd gerencie o processo interno corretamente, o contêiner precisa interagir com os `cgroups` do Kernel do Host. Portanto, a execução exige privilégios administrativos.

## 📦 Como Clonar e Compilar

1. Clone o repositório dentro da organização:
```bash
git clone https://github.com/rodrigomicrosiga-devops/docker-protheus-smartview.git
cd docker-protheus-smartview
```

Certifique-se de que o instalador oficial (`3.9.0.4558336-linux-x64.zip`) está posicionado na raiz deste diretório.

Execute o build da imagem localmente:

```bash
docker build -t rodrigomicrosiga-devops/protheus-smartview:3.9.0 .
```

### 🏁 Execução Isolada (Modo de Teste)

Para subir o contêiner mapeando as portas e os volumes de kernel necessários, utilize o comando abaixo:

```bash
docker run -d \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 7019:7019 \
  --name test_smartview \
  rodrigomicrosiga-devops/protheus-smartview:3.9.0
  ```

### 🔍 Validação do Ambiente

Para conferir o status do serviço interno gerenciado pelo contêiner, execute:

```bash
docker exec -it test_smartview systemctl status smart-view-agent
```

A interface estará disponível na URL: `http://localhost:7019`


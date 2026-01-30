# 🏭 ScadaLTS - Ambiente de Laboratório Automatizado (Docker)

Este repositório contém a infraestrutura completa para rodar o **ScadaLTS** em ambiente universitário/laboratorial.

O projeto foi modernizado para incluir um **Painel de Controle Automatizado (`scada-manager.sh`)**, sistema de backup integrado e injeção automática de gráficos personalizados via Docker, facilitando a gestão e evitando perda de dados.

---

## ⚡ Início Rápido

Não é necessário memorizar comandos complexos do Docker. Tudo é gerido pelo script principal.

1. **Clone o repositório:**
   ```bash
   git clone https://seu-link-do-git-aqui.git
   cd scadalts-host
   ```

2. **Dê permissão de execução ao gerenciador:**
   ```bash
   chmod +x scada-manager.sh
   ```

3. **Abra o Painel de Controle:**
   ```bash
   ./scada-manager.sh
   ```

4. **Escolha a Opção 5 (Iniciar Containers)** para subir o sistema pela primeira vez.

---

## 🎮 O Gerenciador (scada-manager.sh)

O script interativo é o coração do projeto. Funcionalidades disponíveis:

### 💾 Dados e Segurança
* **1. Fazer Backup:** Cria um arquivo `.sql` completo (dados + configurações) na pasta `backups/`.
* **2. Restaurar Backup:** Permite recuperar o estado anterior do laboratório. **Atenção:** Isso sobrescreve os dados atuais.
* **3. Atualizar Imagens:** Reconstrói o container para incorporar novos gráficos adicionados à pasta `scada_imagens`.

### 🔌 Energia
* **4. Pausar:** Interrompe o processamento sem apagar dados (ideal para fim de expediente).
* **5. Iniciar:** Retoma o funcionamento.
* **6. RESET TOTAL:** Zona de perigo. Apaga containers e **todos os dados** do banco. Exige confirmação por texto.

### 🌐 Acesso
* **7. Pegar Link Público:** Busca automaticamente a URL do Cloudflare Tunnel e adiciona o sufixo `/Scada-LTS` para acesso remoto direto.

---

## 🎨 Como Adicionar Gráficos Personalizados

Este ambiente usa um `Dockerfile` customizado para "fundir" seus gráficos dentro do sistema.

1. Coloque a pasta do seu componente gráfico (ex: `Tanque1`) dentro de:
   `./scada_imagens/`

   > **Estrutura Obrigatória:**
   > ```text
   > scada_imagens/
   > └── Tanque1/
   >     ├── 0.png      (Estado Desligado)
   >     ├── 1.png      (Estado Ligado)
   >     └── info.txt   (Conteúdo: name=Tanque1)
   > ```

2. No gerenciador, escolha a **Opção 3 (Atualizar Imagens/Reconstruir)**.
3. Aguarde o reinício e o novo gráfico aparecerá no menu *Binary Graphic* do ScadaLTS.

---

## 📂 Estrutura de Arquivos

* `scada-manager.sh`: Painel de controle do laboratório.
* `scada_imagens/`: Diretório local para guardar seus pacotes gráficos.
* `backups/`: Local onde os dumps do banco de dados são salvos.
* `docker-compose.yml`: Orquestração dos serviços (App + Banco + Túnel).
* `Dockerfile`: Receita para criar a imagem customizada com seus gráficos.

---

## 🔐 Credenciais Padrão

* **Interface Web ScadaLTS:**
  * Usuário: `admin`
  * Senha: `admin`

* **Banco de Dados (Interno):**
  * Usuário: `root`
  * Senha: `root`

---

## ⚠️ Solução de Problemas Comuns

**1. O link do Cloudflare não abre:**
O túnel pode ter mudado de endereço. Use a **Opção 7** do gerenciador para pegar o link atualizado.

**2. Gráficos novos não aparecem:**
Certifique-se de que rodou a **Opção 3 (Build)** após adicionar os arquivos e limpe o cache do navegador (`Ctrl + Shift + R`).

**3. Erro "Container name conflict":**
Use a **Opção 3** ou **Opção 6** do gerenciador, pois elas limpam containers antigos antes de subir novos.
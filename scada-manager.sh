#!/bin/bash

# CORES PARA FACILITAR A LEITURA
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# CONFIGURAÇÕES
DB_CONTAINER="scada_db"
APP_CONTAINER="scada_app"
TUNNEL_CONTAINER="scada_tunnel"
DB_USER="root"
DB_PASS="root"
DB_NAME="scadalts"
BACKUP_DIR="./backups"

# Garante que a pasta de backups existe
mkdir -p $BACKUP_DIR

# FUNÇÃO: EXIBIR CABEÇALHO
show_header() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}   🏭 SCADA-LTS: GERENCIADOR DO LABORATÓRIO      ${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo ""
}

# 1. FUNÇÃO: FAZER BACKUP
do_backup() {
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    FILENAME="$BACKUP_DIR/backup_scada_$TIMESTAMP.sql"

    echo -e "${YELLOW}⏳ Iniciando backup do banco de dados...${NC}"

    if sudo docker exec $DB_CONTAINER mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > "$FILENAME"; then
        echo -e "${GREEN}✅ Sucesso! Backup salvo em:${NC}"
        echo -e "   $FILENAME"
    else
        echo -e "${RED}❌ Erro ao realizar backup. O container '$DB_CONTAINER' está rodando?${NC}"
    fi
    read -p "Pressione Enter para voltar..."
}

# 2. FUNÇÃO: RESTAURAR BACKUP
do_restore() {
    echo -e "${RED}⚠️  ATENÇÃO: RESTAURAR UM BACKUP APAGARÁ OS DADOS ATUAIS!${NC}"
    echo "Arquivos disponíveis:"
    echo "---------------------"
    ls -1 $BACKUP_DIR/*.sql | xargs -n 1 basename
    echo "---------------------"
    echo ""
    read -p "Digite o NOME COMPLETO do arquivo (ex: backup_scada_2026...sql): " RESTORE_FILE

    FULL_PATH="$BACKUP_DIR/$RESTORE_FILE"

    if [ -f "$FULL_PATH" ]; then
        echo -e "${YELLOW}Isso irá sobrescrever o banco atual com o arquivo $RESTORE_FILE.${NC}"
        read -p "Tem certeza absoluta? (s/n): " CONFIRM

        if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
            echo -e "${YELLOW}⏳ Parando aplicação Scada para evitar conflitos...${NC}"
            sudo docker stop $APP_CONTAINER

            echo -e "${YELLOW}⏳ Restaurando banco de dados...${NC}"
            cat "$FULL_PATH" | sudo docker exec -i $DB_CONTAINER mysql -u $DB_USER -p$DB_PASS $DB_NAME

            echo -e "${YELLOW}⏳ Reiniciando aplicação...${NC}"
            sudo docker start $APP_CONTAINER

            echo -e "${GREEN}✅ Restauração concluída com sucesso!${NC}"
        else
            echo "Operação cancelada."
        fi
    else
        echo -e "${RED}❌ Arquivo não encontrado!${NC}"
    fi
    read -p "Pressione Enter para voltar..."
}

# 3. FUNÇÃO: ATUALIZAR IMAGENS (BUILD)
do_update_images() {
    echo -e "${BLUE}ℹ️  Isso vai reconstruir o container para incluir novas imagens da pasta 'scada_imagens'.${NC}"
    echo -e "${YELLOW}⏳ Isso pode levar alguns minutos.${NC}"

    # Usa down normal (mantém dados)
    sudo docker compose down

    if sudo docker compose up -d --build; then
        echo -e "${GREEN}✅ Containers atualizados e iniciados!${NC}"
    else
        echo -e "${RED}❌ Erro na atualização.${NC}"
    fi
    read -p "Pressione Enter para voltar..."
}

# 4. FUNÇÃO: PARAR CONTAINERS
do_stop() {
    echo -e "${YELLOW}⏳ Parando todos os serviços (os dados serão mantidos)...${NC}"
    sudo docker compose stop
    echo -e "${GREEN}✅ Serviços pausados.${NC}"
    read -p "Pressione Enter para voltar..."
}

# 5. FUNÇÃO: INICIAR CONTAINERS
do_start() {
    echo -e "${YELLOW}⏳ Iniciando serviços...${NC}"
    sudo docker compose start
    echo -e "${GREEN}✅ Serviços iniciados.${NC}"
    read -p "Pressione Enter para voltar..."
}

# 6. FUNÇÃO: DESTRUIR TUDO (RESET)
do_wipe() {
    echo -e "${RED}☢️  PERIGO: ZONA DE DESTRUIÇÃO ☢️${NC}"
    echo -e "${RED}Esta opção irá:${NC}"
    echo -e "  1. Parar e remover todos os containers."
    echo -e "  2. ${RED}APAGAR TODOS OS VOLUMES E DADOS DO BANCO DE DADOS!${NC}"
    echo -e "  3. Deixar o sistema como se fosse recém instalado."
    echo ""
    echo -e "${YELLOW}Dica: Faça um backup (Opção 1) antes de fazer isso.${NC}"
    echo ""
    read -p "Para confirmar, digite a palavra 'DELETAR' em maiúsculo: " CONFIRM

    if [ "$CONFIRM" == "DELETAR" ]; then
        echo -e "${RED}⏳ Executando limpeza total (down -v)...${NC}"
        sudo docker compose down -v
        echo -e "${GREEN}✅ Sistema limpo. Todos os dados foram apagados.${NC}"
        echo -e "Para iniciar novamente zerado, use a Opção 3 ou 5."
    else
        echo -e "${GREEN}Operação cancelada. Ufa!${NC}"
    fi
    read -p "Pressione Enter para voltar..."
}

# 7. FUNÇÃO: PEGAR URL DO CLOUDFLARE
get_tunnel_url() {
    echo -e "${YELLOW}🔍 Buscando URL pública mais recente...${NC}"

    # O comando 'grep -o' extrai APENAS a URL (http...com), ignorando o resto do texto do log
    RAW_URL=$(sudo docker logs $TUNNEL_CONTAINER 2>&1 | grep -o 'https://[^ ]*\.trycloudflare\.com' | tail -n 1)

    if [ -z "$RAW_URL" ]; then
        echo -e "${RED}❌ URL ainda não gerada ou container parado.${NC}"
        echo -e "Tente aguardar alguns segundos e tente novamente."
    else
        # Monta a URL final com o sufixo desejado
        FINAL_URL="${RAW_URL}/Scada-LTS"

        echo -e "${GREEN}✅ Link Direto Encontrado:${NC}"
        echo ""
        echo -e "   ${CYAN}$FINAL_URL${NC}"
        echo ""
        echo -e "Copie e cole no navegador para abrir direto na tela de login."
    fi
    read -p "Pressione Enter para voltar..."
}

# FUNÇÃO DE AJUDA
show_help() {
    show_header
    echo -e "${YELLOW}--- AJUDA: O QUE CADA OPÇÃO FAZ ---${NC}"
    echo ""
    echo -e "${GREEN}1. Fazer Backup:${NC} Cria uma cópia de segurança completa do banco de dados na pasta 'backups'."
    echo ""
    echo -e "${GREEN}2. Restaurar Backup:${NC} Substitui os dados atuais por um backup. ${RED}ATENÇÃO: os dados atuais serão perdidos!${NC}"
    echo ""
    echo -e "${GREEN}3. Atualizar Imagens:${NC} Reconstrói o sistema para incluir novas imagens da pasta 'scada_imagens'."
    echo ""
    echo -e "${GREEN}4. Pausar Containers:${NC} Para todos os serviços (Scada, banco, etc.) sem apagar dados. Ideal para economizar recursos."
    echo ""
    echo -e "${GREEN}5. Iniciar Containers:${NC} Inicia os serviços que foram pausados anteriormente."
    echo ""
    echo -e "${GREEN}6. RESET TOTAL:${NC} ${RED}AÇÃO DESTRUTIVA!${NC} Apaga todos os containers e todos os dados, restaurando o sistema para o estado inicial."
    echo ""
    echo -e "${GREEN}7. Pegar Link Público:${NC} Mostra a URL do Cloudflare para acessar o Scada-LTS pela internet."
    echo ""
    echo -e "${GREEN}8. Ver Status:${NC} Exibe o status atual de todos os containers (rodando, parado, etc.)."
    echo ""
    echo -e "${GREEN}9. Sair:${NC} Fecha este script de gerenciamento."
    echo ""
    read -p "Pressione Enter para voltar ao menu..."
}


# MENU PRINCIPAL
while true; do
    show_header
    echo -e "${CYAN}--- DADOS E MANUTENÇÃO ---${NC}"
    echo "1. 💾 Fazer Backup Completo"
    echo "2. ♻️  Restaurar Backup (Perigoso)"
    echo "3. 🖼️  Atualizar Imagens/Reconstruir (Build)"
    echo ""
    echo -e "${CYAN}--- CONTROLE DE ENERGIA ---${NC}"
    echo "4. ⏸️  Pausar Containers (Stop)"
    echo "5. ▶️  Iniciar Containers (Start)"
    echo "6. ☢️  RESET TOTAL (Apagar Dados/Volumes)"
    echo ""
    echo -e "${CYAN}--- INFORMAÇÕES E ACESSO ---${NC}"
    echo "7. 🌐 Pegar Link Público (Cloudflare)"
    echo "8. 🔍 Ver Status dos Containers"
    echo ""
    echo -e "${CYAN}--- SISTEMA ---${NC}"
    echo "9. 📖 Ajuda"
    echo "10. 🚪 Sair"
    echo ""
    read -p "Escolha uma opção: " OPTION

    case $OPTION in
        1) do_backup ;;
        2) do_restore ;;
        3) do_update_images ;;
        4) do_stop ;;
        5) do_start ;;
        6) do_wipe ;;
        7) get_tunnel_url ;;
        8)
           echo ""
           sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
           echo ""
           read -p "Pressione Enter..."
           ;;
        9) show_help ;;
        10) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida." ;;
    esac
done

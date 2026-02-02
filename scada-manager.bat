@echo off
setlocal enabledelayedexpansion

:: CONFIGURACOES
set "DB_CONTAINER=scada_db"
set "APP_CONTAINER=scada_app"
set "TUNNEL_CONTAINER=scada_tunnel"
set "DB_USER=root"
set "DB_PASS=root"
set "DB_NAME=scadalts"
set "BACKUP_DIR=.\backups"

:: Garante que a pasta de backups existe
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)

:: =================================
:: MENU PRINCIPAL
:: =================================
:main_menu
call :show_header
echo --- DADOS E MANUTENCAO ---
echo 1. Fazer Backup Completo
echo 2. Restaurar Backup (Perigoso)
echo 3. Atualizar Imagens/Reconstruir (Build)
echo.
echo --- CONTROLE DE ENERGIA ---
echo 4. Pausar Containers (Stop)
echo 5. Iniciar Containers (Start)
echo 6. RESET TOTAL (Apagar Dados/Volumes)
echo.
echo --- INFORMACOES E ACESSO ---
echo 7. Pegar Link Publico (Cloudflare)
echo 8. Ver Status dos Containers
echo.
echo --- SISTEMA ---
echo 9. Ajuda
echo 10. Sair
echo.
set /p "OPTION=Escolha uma opcao: "

if "%OPTION%"=="1" goto do_backup
if "%OPTION%"=="2" goto do_restore
if "%OPTION%"=="3" goto do_update_images
if "%OPTION%"=="4" goto do_stop
if "%OPTION%"=="5" goto do_start
if "%OPTION%"=="6" goto do_wipe
if "%OPTION%"=="7" goto get_tunnel_url
if "%OPTION%"=="8" (
    echo.
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo.
    pause
    goto main_menu
)
if "%OPTION%"=="9" goto show_help
if "%OPTION%"=="10" (
    echo Saindo...
    goto :eof
)

echo Opcao invalida.
pause
goto main_menu

:: =================================
:: FUNCOES (SUB-ROTINAS)
:: =================================

:show_header
cls
echo =================================================
echo    SCADA-LTS: GERENCIADOR DO LABORATORIO
echo =================================================
echo.
goto :eof

:: FUNCAO DE AJUDA
:show_help
call :show_header
echo --- AJUDA: O QUE CADA OPCAO FAZ ---
echo.
echo 1. Fazer Backup: Cria uma copia de seguranca completa do banco de dados na pasta 'backups'.
echo.
echo 2. Restaurar Backup: Substitui os dados atuais por um backup. ATENCAO: os dados atuais serao perdidos!
echo.
echo 3. Atualizar Imagens: Reconstroi o sistema para incluir novas imagens da pasta 'scada_imagens'.
echo.
echo 4. Pausar Containers: Para todos os servicos (Scada, banco, etc.) sem apagar dados. Ideal para economizar recursos.
echo.
echo 5. Iniciar Containers: Inicia os servicos que foram pausados anteriormente.
echo.
echo 6. RESET TOTAL: ACAO DESTRUTIVA! Apaga todos os containers e todos os dados, restaurando o sistema para o estado inicial.
echo.
echo 7. Pegar Link Publico: Mostra a URL do Cloudflare para acessar o Scada-LTS pela internet.
echo.
echo 8. Ver Status: Exibe o status atual de todos os containers (rodando, parado, etc.).
echo.
echo 9. Ajuda: Mostra esta tela de ajuda.
echo.
echo 10. Sair: Fecha este script de gerenciamento.
echo.
pause
goto main_menu

:: 1. FUNCAO: FAZER BACKUP
:do_backup
echo Iniciando backup do banco de dados...

:: Gera um timestamp no formato YYYY-MM-DD_HH-MM-SS usando PowerShell para maior compatibilidade
for /f "delims=" %%I in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set "TIMESTAMP=%%I"
set "FILENAME=%BACKUP_DIR%\backup_scada_%TIMESTAMP%.sql"

docker exec %DB_CONTAINER% mysqldump -u %DB_USER% -p%DB_PASS% %DB_NAME% > "%FILENAME%"

if %errorlevel% equ 0 (
    echo Sucesso! Backup salvo em:
    echo    %FILENAME%
) else (
    echo Erro ao realizar backup. O container '%DB_CONTAINER%' esta rodando?
)
pause
goto main_menu

:: 2. FUNCAO: RESTAURAR BACKUP
:do_restore
echo ATENCAO: RESTAURAR UM BACKUP APAGARA OS DADOS ATUAIS!
echo Arquivos disponiveis:
echo ---------------------
dir /b "%BACKUP_DIR%\*.sql"
echo ---------------------
echo.
set /p "RESTORE_FILE=Digite o NOME COMPLETO do arquivo (ex: backup_scada_2026...sql): "

set "FULL_PATH=%BACKUP_DIR%\%RESTORE_FILE%"

if exist "%FULL_PATH%" (
    echo Isso ira sobrescrever o banco atual com o arquivo %RESTORE_FILE%.
    set /p "CONFIRM=Tem certeza absoluta? (s/n): "

    if /i "%CONFIRM%"=="s" (
        echo Parando aplicacao Scada para evitar conflitos...
        docker stop %APP_CONTAINER%

        echo Restaurando banco de dados...
        type "%FULL_PATH%" | docker exec -i %DB_CONTAINER% mysql -u %DB_USER% -p%DB_PASS% %DB_NAME%

        echo Reiniciando aplicacao...
        docker start %APP_CONTAINER%

        echo Restauracao concluida com sucesso!
    ) else (
        echo Operacao cancelada.
    )
) else (
    echo Arquivo nao encontrado!
)
pause
goto main_menu

:: 3. FUNCAO: ATUALIZAR IMAGENS (BUILD)
:do_update_images
echo.
echo Info: Isso vai reconstruir o container para incluir novas imagens da pasta 'scada_imagens'.
echo Isso pode levar alguns minutos.
echo.

:: Usa down normal (mantem dados)
docker compose down

docker compose up -d --build
if %errorlevel% equ 0 (
    echo Containers atualizados e iniciados!
) else (
    echo Erro na atualizacao.
)
pause
goto main_menu

:: 4. FUNCAO: PARAR CONTAINERS
:do_stop
echo Parando todos os servicos (os dados serao mantidos)...
docker compose stop
echo Servicos pausados.
pause
goto main_menu

:: 5. FUNCAO: INICIAR CONTAINERS
:do_start
echo Iniciando servicos...
docker compose start
echo Servicos iniciados.
pause
goto main_menu

:: 6. FUNCAO: DESTRUIR TUDO (RESET)
:do_wipe
echo PERIGO: ZONA DE DESTRUICAO
echo Esta opcao ira:
   1. Parar e remover todos os containers.
   2. APAGAR TODOS OS VOLUMES E DADOS DO BANCO DE DADOS!
   3. Deixar o sistema como se fosse recem instalado.
echo.
echo Dica: Faca um backup (Opcao 1) antes de fazer isso.
echo.
set /p "CONFIRM=Para confirmar, digite a palavra 'DELETAR' em maiusculo: "

if "%CONFIRM%"=="DELETAR" (
    echo Executando limpeza total (down -v)...
    docker compose down -v
    echo Sistema limpo. Todos os dados foram apagados.
    echo Para iniciar novamente zerado, use a Opcao 3 ou 5.
) else (
    echo Operacao cancelada. Ufa!
)
pause
goto main_menu

:: 7. FUNCAO: PEGAR URL DO CLOUDFLARE
:get_tunnel_url
echo Buscando URL publica mais recente...

set "RAW_URL="
:: Itera sobre as linhas do log que contem a string do cloudflare
for /f "delims=" %%i in ('docker logs %TUNNEL_CONTAINER% 2^>^&1 ^| findstr "trycloudflare.com"') do (
    :: Dentro de cada linha, itera sobre as palavras (separadas por espaco)
    for %%a in (%%i) do (
        :: Verifica se a palavra comeca com https
        set "word=%%a"
        if "!word:~0,8!"=="https://" (
            set "RAW_URL=!word!"
        )
    )
)

if defined RAW_URL (
    set "FINAL_URL=%RAW_URL%/Scada-LTS"
    echo.
    echo Link Direto Encontrado:
    echo.
    echo    %FINAL_URL%
    echo.
    echo Copie e cole no navegador para abrir direto na tela de login.
) else (
    echo.
    echo URL ainda nao gerada ou container parado.
    echo Tente aguardar alguns segundos e tente novamente.
)
pause
goto main_menu

@echo off
echo --- Iniciando o Tunel Cloudflare para ScadaLTS ---

docker-compose up -d

echo Aguardando o Cloudflare gerar a URL...
timeout /t 8 /nobreak >nul

echo --- AQUI ESTA SUA URL DE ACESSO ---
docker-compose logs | findstr "trycloudflare.com"

echo -----------------------------------
echo Pressione qualquer tecla para sair (o tunel continuara rodando no fundo)
pause

#!/bin/bash

echo "--- Iniciando o Túnel Cloudflare para ScadaLTS ---"

# Sobe o container em modo 'detached' (fundo)
docker-compose up -d

echo "Aguardando o Cloudflare gerar a URL (5 segundos)..."
sleep 5

echo "--- AQUI ESTÁ SUA URL DE ACESSO ---"
# Busca nos logs a linha que contém o link .trycloudflare.com
docker-compose logs | grep "trycloudflare.com"

echo "-----------------------------------"
echo "Para parar o túnel, digite: docker-compose down"

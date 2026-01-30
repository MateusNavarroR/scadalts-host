FROM scadalts/scadalts:latest

# COPIA CORRETA:
# Pega o conteúdo de scada_imagens e joga na raiz de /graphics/
# É aqui que o ScadaLTS procura pastas como "Cano1", "Motor", etc.
COPY ./scada_imagens/ /usr/local/tomcat/webapps/Scada-LTS/graphics/

# Ajusta permissões para garantir que o Tomcat consiga ler
RUN chmod -R 755 /usr/local/tomcat/webapps/Scada-LTS/graphics/

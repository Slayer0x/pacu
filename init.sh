#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "Ejecuta como root"
   exit 1
fi

# Instalación (versión simple usando paquetes de Ubuntu)
apt-get update
apt-get -y dist-upgrade
apt-get install -y docker.io docker-compose git
systemctl enable --now docker

# Esperar a que docker esté listo (opcional)
sleep 2

# Pull/tags de imágenes (solo si docker está disponible)
for image in evilginx nginx-proxy gophish; do
    docker pull ghcr.io/thirdbyte/pacu:"$image"
    docker tag ghcr.io/thirdbyte/pacu:"$image" "$image"
    docker rmi ghcr.io/thirdbyte/pacu:"$image"
done

# Clonar o actualizar repo pacu en /opt/pacu
if [ -d /opt/pacu/.git ]; then
    echo "Repositorio ya existe, actualizando..."
    git -C /opt/pacu pull
else
    echo "Clonando pacu..."
    git clone https://github.com/thirdbyte/pacu /opt/pacu
fi

# Instalar script
if [ -f /opt/pacu/setup.sh ]; then
    cp /opt/pacu/setup.sh /usr/local/bin/pacu
    chmod +x /usr/local/bin/pacu
else
    echo "/opt/pacu/setup.sh no existe, verifica el repositorio."
fi

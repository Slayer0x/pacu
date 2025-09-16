#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Ejecuta como root"
   exit 1
fi

REPO_URL="https://github.com/thirdbyte/pacu"
DEST_DIR="/opt/pacu"
PACKAGES="git docker.io docker-compose"

echo "[*] Actualizando e instalando dependencias..."
apt-get update
apt-get -y dist-upgrade
apt-get install -y $PACKAGES
systemctl enable --now docker || true

# Esperar a que docker esté listo (opcional)
sleep 2

# Clonar o actualizar repo pacu en /opt/pacu
if [[ -d "${DEST_DIR}/.git" ]]; then
    echo "[*] El repositorio ya existe en ${DEST_DIR}, haciendo pull..."
    git -C "${DEST_DIR}" pull --ff-only || {
        echo "[!] git pull falló. Intentando fetch + reset del principal..."
        git -C "${DEST_DIR}" fetch --all
        git -C "${DEST_DIR}" reset --hard origin/HEAD
    }
else
    if [[ -d "${DEST_DIR}" && ! -z "$(ls -A "${DEST_DIR}")" ]]; then
        echo "[*] ${DEST_DIR} existe y no está vacío. Haciendo backup y clonando fresco..."
        mv "${DEST_DIR}" "${DEST_DIR}.bak.$(date +%s)"
    fi
    echo "[*] Clonando ${REPO_URL} en ${DEST_DIR}..."
    git clone "${REPO_URL}" "${DEST_DIR}"
fi

# Entrar en el repo
cd "${DEST_DIR}"

# Hacer ejecutables los scripts
echo "[*] Ajustando permisos de los scripts..."
chmod +x ./*.sh || true

# Ejecutar build.sh si existe
if [[ -f "./build.sh" ]]; then
    echo "[*] Ejecutando ./build.sh..."
    ./build.sh
else
    echo "[*] build.sh no encontrado en ${DEST_DIR}, saltando build."
fi

# Ejecutar setup.sh si existe
if [[ -f "./setup.sh" ]]; then
    echo "[*] Ejecutando ./setup.sh..."
    ./setup.sh
    # Además copiar a /usr/local/bin/pacu para acceso global si el setup.sh no lo hace
    if [[ -f "./setup.sh" ]]; then
        cp ./setup.sh /usr/local/bin/pacu || true
        chmod +x /usr/local/bin/pacu || true
    fi
else
    echo "[!] setup.sh no existe en ${DEST_DIR}. Revisa el repositorio."
fi

echo "[*] Hecho."

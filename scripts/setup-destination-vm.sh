#!/usr/bin/env bash
# ==============================================================================
# Script de configuración para la Máquina Destino (Ubuntu / Debian)
# Taller DevOps UTEC - Despliegue de Contenedor vía SSH desde Jenkins
# ==============================================================================
set -e

echo "=== [1/5] Actualizando paquetes del sistema ==="
sudo apt update -y

echo "=== [2/5] Instalando Docker y OpenSSH Server ==="
sudo apt install -y docker.io openssh-server

echo "=== [3/5] Habilitando e iniciando servicios de Docker y SSH ==="
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable ssh
sudo systemctl start ssh

echo "=== [4/5] Configurando usuario para despliegues (jenkins) ==="
TARGET_USER="jenkins"
if id "$TARGET_USER" &>/dev/null; then
    echo "El usuario '$TARGET_USER' ya existe."
else
    echo "Creando usuario '$TARGET_USER'..."
    sudo useradd -m -s /bin/bash "$TARGET_USER"
    echo "Asigna una contraseña para el usuario '$TARGET_USER':"
    sudo passwd "$TARGET_USER"
fi

# Agregar usuario al grupo docker
sudo usermod -aG docker "$TARGET_USER"
echo "Usuario '$TARGET_USER' añadido al grupo docker."

# Crear directorio .ssh con permisos adecuados
USER_HOME=$(eval echo "~$TARGET_USER")
sudo mkdir -p "$USER_HOME/.ssh"
sudo chmod 700 "$USER_HOME/.ssh"
sudo touch "$USER_HOME/.ssh/authorized_keys"
sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"
sudo chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh"

echo "=== [5/5] Verificación final ==="
echo "Versión de Docker:"
docker --version
echo "Estado de SSH:"
systemctl is-active ssh
echo "Direcciones IP de este equipo:"
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' || true

echo "=============================================================================="
echo "¡Configuración completada con éxito en la máquina destino!"
echo "Ahora, desde el servidor Jenkins ejecuta:"
echo "  ssh-copy-id $TARGET_USER@<IP_DE_ESTA_MAQUINA>"
echo "=============================================================================="

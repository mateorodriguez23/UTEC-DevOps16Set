#!/usr/bin/env bash
# ==============================================================================
# Script de configuración para el Servidor Jenkins (Ubuntu / Debian)
# Taller DevOps UTEC - Configuración de Git, Docker y permisos SSH
# ==============================================================================
set -e

echo "=== [1/5] Actualizando paquetes e instalando Git y Docker ==="
sudo apt update -y
sudo apt install -y git docker.io openssh-client

echo "=== [2/5] Iniciando y habilitando servicio Docker ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== [3/5] Otorgando permisos de Docker al usuario 'jenkins' ==="
if id "jenkins" &>/dev/null; then
    sudo usermod -aG docker jenkins
    echo "Usuario 'jenkins' añadido al grupo docker."
    
    # Generar clave SSH para el usuario jenkins si no existe
    JENKINS_HOME="/var/lib/jenkins"
    if [ -d "$JENKINS_HOME" ]; then
        sudo mkdir -p "$JENKINS_HOME/.ssh"
        if [ ! -f "$JENKINS_HOME/.ssh/id_rsa" ]; then
            echo "Generando par de claves SSH (RSA 4096) para el usuario jenkins..."
            sudo -u jenkins ssh-keygen -t rsa -b 4096 -f "$JENKINS_HOME/.ssh/id_rsa" -N ""
        else
            echo "La clave SSH ya existe en $JENKINS_HOME/.ssh/id_rsa"
        fi
        sudo chmod 700 "$JENKINS_HOME/.ssh"
        sudo chmod 600 "$JENKINS_HOME/.ssh/id_rsa"
        sudo chmod 644 "$JENKINS_HOME/.ssh/id_rsa.pub"
        sudo chown -R jenkins:jenkins "$JENKINS_HOME/.ssh"
    fi
    
    echo "Reiniciando el servicio de Jenkins..."
    sudo systemctl restart jenkins || true
else
    echo "Aviso: No se encontró el usuario del sistema 'jenkins'. Si Jenkins corre en contenedor o con otro usuario, ajusta los permisos correspondientes."
fi

# Generar par de claves para el usuario actual también (útil si se usa SSH interactivo)
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "Generando par de claves SSH para el usuario actual ($USER)..."
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
fi

echo "=== [4/5] Verificaciones ==="
echo "Ubicación del ejecutable Git:"
which git
echo "Versión de Git:"
git --version
echo "Versión de Docker:"
docker --version

if id "jenkins" &>/dev/null; then
    echo "Comprobando acceso de 'jenkins' a Docker:"
    sudo -u jenkins docker ps || echo "Nota: Si falla, reinicia la sesión o el servicio jenkins con 'sudo systemctl restart jenkins'."
fi

echo "=== [5/5] Clave Pública para copiar a la Máquina Destino ==="
if [ -f "/var/lib/jenkins/.ssh/id_rsa.pub" ]; then
    echo "Clave pública del usuario jenkins (/var/lib/jenkins/.ssh/id_rsa.pub):"
    sudo cat /var/lib/jenkins/.ssh/id_rsa.pub
elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo "Clave pública de $USER (~/.ssh/id_rsa.pub):"
    cat "$HOME/.ssh/id_rsa.pub"
fi

echo ""
echo "=============================================================================="
echo "Siguiente paso para autorizar la conexión sin contraseña:"
echo "  sudo -u jenkins ssh-copy-id jenkins@<IP_MAQUINA_DESTINO>"
echo "  (o ejecuta: ssh-copy-id jenkins@<IP_MAQUINA_DESTINO>)"
echo ""
echo "Para ver la clave privada que debes pegar en Jenkins Credentials (Paso 3):"
echo "  sudo cat /var/lib/jenkins/.ssh/id_rsa"
echo "=============================================================================="

#!/bin/bash
# setup.sh - Aprovisionamiento del entorno del proyecto
set -e # Detiene el script si algun comando falla

echo ">>> Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

echo ">>> Instalando utilidades base..."
sudo apt install -y curl git ca-certificates nano python3-venv python3-pip

echo ">>> Instalando Docker Engine..."
if ! command -v docker &> /dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker $USER
else
  echo "Docker ya estaba instalado."
fi

echo ">>> Instalando Ollama..."
if ! command -v ollama &> /dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "Ollama ya estaba instalado."
fi

echo ">>> Entorno listo. Cierre y reabra la terminal para usar docker sin sudo."

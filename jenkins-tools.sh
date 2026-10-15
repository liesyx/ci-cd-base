#!/usr/bin/env bash
# Run INSIDE the Jenkins container (docker exec -u root -it <jenkins> bash, then paste/run).
# Installs docker CLI + kubectl + helm into the persistent volume /var/jenkins_home/bin,
# so they survive container recreation by Coolify.
set -euo pipefail
BIN=/var/jenkins_home/bin
mkdir -p $BIN
case "$(uname -m)" in
  x86_64)  DARCH=x86_64;  KARCH=amd64 ;;
  aarch64) DARCH=aarch64; KARCH=arm64 ;;
  *) echo "unsupported arch"; exit 1 ;;
esac
DOCKER_VER=28.5.1
curl -fsSL https://download.docker.com/linux/static/stable/${DARCH}/docker-${DOCKER_VER}.tgz \
  | tar -xz -C /tmp docker/docker
mv /tmp/docker/docker $BIN/docker
KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL -o $BIN/kubectl https://dl.k8s.io/release/${KVER}/bin/linux/${KARCH}/kubectl
HELM_VER=v3.19.0
curl -fsSL https://get.helm.sh/helm-${HELM_VER}-linux-${KARCH}.tar.gz | tar -xz -C /tmp linux-${KARCH}/helm
mv /tmp/linux-${KARCH}/helm $BIN/helm
chmod +x $BIN/docker $BIN/kubectl $BIN/helm
chown -R 1000:1000 $BIN
$BIN/docker --version
$BIN/kubectl version --client
$BIN/helm version --short

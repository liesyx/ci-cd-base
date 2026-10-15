#!/usr/bin/env bash
# Run ONCE on the server as root. Prepares k3s for the Jenkins pipeline.
# Usage: HARBOR=harbor.oci.lexsy.pro.vn ROBOT_USER='robot$cicd+k3s' ROBOT_PASS='xxx' bash setup-once.sh
set -euo pipefail
: "${HARBOR:?set HARBOR}" "${ROBOT_USER:?set ROBOT_USER}" "${ROBOT_PASS:?set ROBOT_PASS}"
NS=demo

# 1. Namespace + pull secret for Harbor
kubectl get ns $NS >/dev/null 2>&1 || kubectl create ns $NS
kubectl -n $NS create secret docker-registry harbor-cred \
  --docker-server="$HARBOR" --docker-username="$ROBOT_USER" --docker-password="$ROBOT_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. ServiceAccount for Jenkins, allowed to deploy ONLY in namespace demo
kubectl -n $NS create serviceaccount jenkins-deployer --dry-run=client -o yaml | kubectl apply -f -
kubectl -n $NS create rolebinding jenkins-deployer --clusterrole=edit \
  --serviceaccount=$NS:jenkins-deployer --dry-run=client -o yaml | kubectl apply -f -
kubectl -n $NS apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-deployer-token
  annotations:
    kubernetes.io/service-account.name: jenkins-deployer
type: kubernetes.io/service-account-token
YAML
sleep 3

# 3. Build a kubeconfig for Jenkins (points at node IP, limited to namespace demo)
TOKEN=$(kubectl -n $NS get secret jenkins-deployer-token -o jsonpath='{.data.token}' | base64 -d)
CA=$(kubectl -n $NS get secret jenkins-deployer-token -o jsonpath='{.data.ca\.crt}')
NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
cat > jenkins-kubeconfig.yaml <<KCFG
apiVersion: v1
kind: Config
clusters:
- name: k3s
  cluster:
    server: https://${NODE_IP}:6443
    certificate-authority-data: ${CA}
users:
- name: jenkins-deployer
  user:
    token: ${TOKEN}
contexts:
- name: jenkins@k3s
  context:
    cluster: k3s
    user: jenkins-deployer
    namespace: ${NS}
current-context: jenkins@k3s
KCFG
chmod 600 jenkins-kubeconfig.yaml
echo "OK -> upload ./jenkins-kubeconfig.yaml to Jenkins as Secret file, ID: kubeconfig-k3s"

{{- define "cicd-demo.name" -}}{{ .Chart.Name }}{{- end -}}
{{- define "cicd-demo.labels" -}}
app.kubernetes.io/name: {{ include "cicd-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
{{- define "cicd-demo.selector" -}}
app.kubernetes.io/name: {{ include "cicd-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

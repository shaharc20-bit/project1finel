{{- define "flask-aws-monitor.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "flask-aws-monitor.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "flask-aws-monitor.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{ include "flask-aws-monitor.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "flask-aws-monitor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-aws-monitor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "flask-aws-monitor.awsSecretName" -}}
{{- if .Values.aws.existingSecret }}
{{- .Values.aws.existingSecret }}
{{- else if .Values.aws.accessKeyId }}
{{- printf "%s-aws" (include "flask-aws-monitor.fullname" .) }}
{{- end }}
{{- end }}

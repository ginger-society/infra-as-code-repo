{{- define "rabbitmq.name" -}}
rabbitmq
{{- end }}

{{- define "rabbitmq.fullname" -}}
{{ .Release.Name }}-rabbitmq
{{- end }}
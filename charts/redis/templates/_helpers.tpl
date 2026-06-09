{{- define "redis.name" -}}
redis
{{- end }}

{{- define "redis.fullname" -}}
{{ .Release.Name }}-redis
{{- end }}

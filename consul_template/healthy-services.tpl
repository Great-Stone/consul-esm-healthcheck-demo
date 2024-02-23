{{- range services -}}
{{- range service .Name -}}
{{ .Name }} [{{ .Address }}:{{ .Port }}]
{{ end -}}
{{- end -}}
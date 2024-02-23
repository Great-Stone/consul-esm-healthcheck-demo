[
{{- range services }}
  {{- if ne .Name (index services 0).Name }},{{ end }}
  {
    "Name": "{{ .Name }}",
    "Instances": [
      {{- range service .Name }}
        {{- if ne .Name (index (service .Name) 0).Name }},{{ end }}
        {
          "Name": "{{ .Name }}",
          "Address": "{{ .Address }}",
          "Port": {{ .Port }}
        }
      {{- end }}
    ]
  }
{{- end }}
]

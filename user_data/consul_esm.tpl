#!/bin/bash
export HOSTNAME=$(hostname)
export PUBLIC_IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
export LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type)
echo ========== Consul Install ==========
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install consul consul-esm consul-template -y
consul-esm --version

echo ========== NodeJS 18 Install ==========
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo ========== Consul ESM Config ==========
cat <<EOT > /etc/consul.d/consul-esm.hcl
log_level = "INFO"
enable_syslog = false
syslog_facility = ""
log_json = false

instance_id = ""
consul_service = "consul-esm"
consul_service_tag = ""

consul_kv_path = "consul-esm/"

external_node_meta {
  "external-node" = "true"
}

node_reconnect_timeout = "72h"
node_probe_interval = "10s"

disable_coordinate_updates = false

http_addr = "${consul_addr}"

token = ""
datacenter = "dc1"

ca_file = ""
ca_path = ""
cert_file = ""
key_file = ""
tls_server_name = ""

https_ca_file = ""
https_ca_path = ""
https_cert_file = ""
https_key_file = ""

client_address = "$LOCAL_IPV4"
ping_type = "socket"

telemetry {
	circonus_api_app = ""
 	circonus_api_token = ""
 	circonus_api_url = ""
 	circonus_broker_id = ""
 	circonus_broker_select_tag = ""
 	circonus_check_display_name = ""
 	circonus_check_force_metric_activation = ""
 	circonus_check_id = ""
 	circonus_check_instance_id = ""
 	circonus_check_search_tag = ""
 	circonus_check_tags = ""
 	circonus_submission_interval = ""
 	circonus_submission_url = ""
 	disable_hostname = false
 	dogstatsd_addr = ""
 	dogstatsd_tags = []
 	filter_default = false
 	prefix_filter = []
 	metrics_prefix = ""
 	prometheus_retention_time = "0"
 	statsd_address = ""
 	statsite_address = ""
}

passing_threshold = 0
critical_threshold = 0
EOT

echo ========== Consul ESM Run ==========
consul-esm -config-file=/etc/consul.d/consul-esm.hcl &

echo ========== Consul Template - template ==========
cat <<EOT > /etc/consul.d/template.ctmpl
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
EOT

echo ========== Consul Template Config ==========
cat <<EOT > /etc/consul.d/consul-template.hcl
consul {
  address = "${consul_addr}"
  namespace = "default"

  auth {
    enabled = false
  }
}

log_level = "info"

template {
  source = "/etc/consul.d/template.ctmpl"
  create_dest_dirs = true
  destination = "/tmp/consul_template/out.json"
  exec {
    command = "curl ${lambda_url} -H 'Content-Type: application/json' -d @/tmp/consul_template/out.json"
  }
}
EOT

echo ========== Consul ESM Run ==========
consul-template -config /etc/consul.d/consul-template.hcl &
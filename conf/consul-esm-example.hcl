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

http_addr = "127.0.0.1:8500"

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

client_address = ""
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
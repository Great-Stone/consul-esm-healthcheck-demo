{
  "Datacenter": "dc1",
  "ID": "${uuid}",
  "Node": "external-node-${service}",
  "Address": "${ip}",
  "NodeMeta": {
    "external-node": "true",
    "external-probe": "true"
  },
  "Service": {
    "ID": "${id}",
    "Service": "${service}",
    "Port": ${port}
  },
  "Checks": [
    {
      "Name": "Tcp check",
      "CheckID": "service:${service}1",
      "Status": "critical",
      "Definition": {
        "TCP": "${ip}:${port}",
        "Interval": "10s",
        "timeout": "2s"
      }
    },
    {
      "Name": "Http check",
      "CheckID": "service:${service}2",
      "Status": "critical",
      "Definition": {
        "http": "http://${ip}:${port}/",
        "method" : "GET",
        "header": { "Content-Type": ["application/json"] },
        "interval": "10s",
        "timeout": "2s"
      }
    }
  ]
}


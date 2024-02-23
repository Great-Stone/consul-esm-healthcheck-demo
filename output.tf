output "consul_addr" {
  value = {
    http = "http://${aws_instance.consul_server.public_ip}:8500"
    ssh  = "ssh -i /Users/gs/workspaces/hashicorp_example/vagrant-examples/hashistack/sample/consul/service_monitoring/ssh_private ubuntu@${aws_instance.consul_server.public_ip}"
  }
}

output "consul_esm" {
  value = {
    ssh = "ssh -i /Users/gs/workspaces/hashicorp_example/vagrant-examples/hashistack/sample/consul/service_monitoring/ssh_private ubuntu@${aws_instance.consul_esm.public_ip}"
  }
}

output "instance_info" {
  value = { for instance in aws_instance.target : instance.tags.Name => instance.public_ip }
}
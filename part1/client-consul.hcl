datacenter = "dc-vm"
data_dir = "/opt/consul"
ca_file = "/etc/consul.d/consul-agent-ca.pem"
verify_incoming = false
verify_outgoing = true
verify_server_hostname = true
retry_join = ["<server-ip>"]
ports {
  grpc = 8502
}
auto_encrypt {
  tls = true
}
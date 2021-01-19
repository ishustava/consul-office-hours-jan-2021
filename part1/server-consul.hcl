datacenter = "dc-vm"
data_dir = "/opt/consul"
ca_file = "/etc/consul.d/consul-agent-ca.pem"
cert_file = "/etc/consul.d/dc-vm-server-consul-0.pem"
key_file = "/etc/consul.d/dc-vm-server-consul-0-key.pem"
verify_incoming_rpc = true
verify_outgoing = true
verify_server_hostname = true
connect {
  enabled = true
  enable_mesh_gateway_wan_federation = true
}
ports {
  https = 8501
}
auto_encrypt {
  allow_tls = true
}
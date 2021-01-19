#!/usr/bin/env bash

# SCP files to the VM:
# gcloud beta compute scp --zone "us-east1-b" --project "ashwin-279921" ./bin/ monolith2:.

echo "Installing Consul"
curl --silent --remote-name https://releases.hashicorp.com/consul/1.9.1/consul_1.9.1_linux_amd64.zip

sudo apt install -y unzip
unzip consul_1.9.1_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/bin/

echo "Verifying Consul installation"
consul --version

echo "Configuring Consul"
consul -autocomplete-install
complete -C /usr/bin/consul consul
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul
sudo touch /usr/lib/systemd/system/consul.service

cat > consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sudo mv consul.service /usr/lib/systemd/system/consul.service

sudo mkdir --parents /etc/consul.d
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl
cat > consul-agent-ca.pem <<EOF
-----BEGIN CERTIFICATE-----
MIIC6zCCApGgAwIBAgIQCyaiqSlP2pPshfG+JiWWgzAKBggqhkjOPQQDAjCBuDEL
MAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1TYW4gRnJhbmNpc2Nv
MRowGAYDVQQJExExMDEgU2Vjb25kIFN0cmVldDEOMAwGA1UEERMFOTQxMDUxFzAV
BgNVBAoTDkhhc2hpQ29ycCBJbmMuMT8wPQYDVQQDEzZDb25zdWwgQWdlbnQgQ0Eg
MTQ4MjIxMTQzODY5NTkwNzcyODAxNDA0MTEzOTE1NDgxNjc4MTEwHhcNMjEwMTE1
MTUzNTAzWhcNMjYwMTE0MTUzNTAzWjCBuDELMAkGA1UEBhMCVVMxCzAJBgNVBAgT
AkNBMRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMRowGAYDVQQJExExMDEgU2Vjb25k
IFN0cmVldDEOMAwGA1UEERMFOTQxMDUxFzAVBgNVBAoTDkhhc2hpQ29ycCBJbmMu
MT8wPQYDVQQDEzZDb25zdWwgQWdlbnQgQ0EgMTQ4MjIxMTQzODY5NTkwNzcyODAx
NDA0MTEzOTE1NDgxNjc4MTEwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARZiIuE
jDlqtEA2N2GLYegP6rnebacRC1PT4LWq3AadELY6TpNYYDu3MqpRT46SZyYyGsEx
3yv9lzy4yoMZyVMto3sweTAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB
/zApBgNVHQ4EIgQgTJ/aqtePdBhHZY2OEdKrJs3Lph1yMdW4AhWGz+9rns0wKwYD
VR0jBCQwIoAgTJ/aqtePdBhHZY2OEdKrJs3Lph1yMdW4AhWGz+9rns0wCgYIKoZI
zj0EAwIDSAAwRQIgbZAFi54EZwcykHzAy9YkBeyVdS+nnMfhKfIVrRt4NHcCIQCd
otZk/mE7mfSMDIuT01SM+dt1HZIx/R3OKXVbvo0KXw==
-----END CERTIFICATE-----
EOF
sudo mv consul-agent-ca.pem /etc/consul.d/consul-agent-ca.pem
cat > consul.hcl <<EOF
datacenter = "dc-vm"
data_dir = "/opt/consul"
ca_file = "/etc/consul.d/consul-agent-ca.pem"
verify_incoming = false
verify_outgoing = true
verify_server_hostname = true
auto_encrypt {
  tls = true
}
retry_join = ["10.128.15.193"]
ports {
  grpc = 8502
}
EOF
sudo mv consul.hcl /etc/consul.d/consul.hcl

echo "Starting Consul"
sudo systemctl enable consul
sudo systemctl start consul

echo "Installing Envoy"
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -sL 'https://getenvoy.io/gpg' | sudo apt-key add -
apt-key fingerprint 6FF974DB | grep "5270 CEAC"
sudo add-apt-repository "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y getenvoy-envoy=1.16.0.p0.g8fb3cb8-1p69.ga5345f6
envoy --version

echo "Creating configuration for the monolith service"
cat > monolith.hcl <<EOF
service {
  name = "monolith"
  id = "monolith-1"
  port = 8080

  connect {
    sidecar_service {}
  }

  check {
    id       = "monolith-check"
    http     = "http://localhost:8080/health"
    method   = "GET"
    interval = "1s"
    timeout  = "1s"
  }
}
EOF




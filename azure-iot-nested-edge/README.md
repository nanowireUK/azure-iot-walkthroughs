# Building a Nested Edge with multiple Gateways

In this guide we show how to implement the new Nested Edge functionality within Azure IoT Edge. This is particularly relevant for industrial IoT scenarios where networks layers and heavy connectivity restrictions are common place.

Based on guide here: https://docs.microsoft.com/en-us/azure/iot-edge/tutorial-nested-iot-edge?view=iotedge-2020-11&tabs=azure-portal
http://aka.ms/iotedge-nested-sample
http://aka.ms/iotedge-nested-tutorial

## The network environment

In order to make the deployment more realistic, it is helpful to recreate a networking lab environment such as the one described below. This is however not mandatory if not available.

The specific implementation used for creating this guide was set up using the open source OpenWRT on a typical home router (TP-Link Archer C7). The key requirements are:

* Configurable VLANs with individual DHCP services
* Configurable firewall

The following networks were set up:
* lan - Supervisory Network
    * VLAN ID `1`
    * Untagged on switch `WAN` port
    * 192.168.100.1/24
    * DHCP
    * Unrestricted internet and network access
    * Firewall Zone `lan`
    * **This is purely a convenience mechanism to allow us to easily `ssh` into each device from a single client and wouldn't typically be present in a real environment`
* wan/wwan - Internet connection
    * DHCP Client
    * Connects to host network as client to provide internet connectivity and isolates from host network
    * Firewall Zone `wan`
* L5NET - Layer 5 IT Network
    * VLAN ID `50`
    * Untagged on switch port `1`
    * 10.50.0.1/16
    * DHCP with some static addresses
    * Unrestricted internet access, otherwise isolated
    * Firewall Zone `L5FW`
* L4NET - Layer 4 OT Network
    * VLAN ID `40`
    * Untagged on switch port `2`
    * 10.40.0.1/16
    * DHCP with some static addresses
    * Completely Isolated
    * Firewall Zone `L4FW`
* L3NET - Layer 3 OT Network
    * VLAN ID `30`
    * Untagged on switch ports `3` and `4`
    * 10.30.0.1/16
    * DHCP with some static addresses
    * Completely Isolated
    * Firewall Zone `L3FW`

Firewall rules
  * lan -> wan, L5FW, L4FW and L3FW
  * wan -> *REJECT*
  * L5FW -> wan
  * L4FW -> *REJECT*
  * L3FW -> *REJECT*


### Key Infos
ssh pi@10.10.0.33 - TopEdge/Pi
ssh moxa@10.10.0.40 - BottomEdge

### Common Gateway Setup

* Clean both gateways
  * SSH in and run `sudo mx-set-def`
  * Connect to 192.168.3.127 with fixed network settings (192.168.3.100/24)
  * Update network settings
    * `sudo nano /etc/network/interfaces`
    ```s
    # interfaces(5) file used by ifup(8) and ifdown(8)
    # Include files from /etc/network/interfaces.d:
    source-directory /etc/network/interfaces.d
    auto eth0 eth1 lo
    iface lo inet loopback  
    iface eth0 inet dhcp
    iface eth1 inet dhcp
    ```
  * Delete docker folder in `/overlayfs`
  * Get them updated to latest OS

* Set hostnames 
  * `sudo nano /etc/hostname`
  * `sudo nano /etc/hosts`

* Get clock syncronised
  * `sudo apt install ntp`
  * `sudo systemctl restart ntp`
  * `sudo ntpd -q -g`
  * `sudo hwclock -w`

* Install IoT Edge
  * `sudo apt install curl`
  * `curl https://packages.microsoft.com/config/debian/stretch/multiarch/prod.list > ./microsoft-prod.list`
  * `sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/`
  * `curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/`
  * `sudo apt install apt-transport-https`  
  * `sudo apt update`
  * `sudo apt install moby-engine`
  * Install the preview of IoT Edge
    ```bash
    curl -L https://github.com/Azure/azure-iotedge/releases/download/1.2.0-rc1/libiothsm-std_1.2.0_rc1-1-1_debian9_armhf.deb -o libiothsm-std.deb
    curl -L https://github.com/Azure/azure-iotedge/releases/download/1.2.0-rc1/iotedge_1.2.0_rc1-1_debian9_armhf.deb -o iotedge.deb
    sudo dpkg -i ./libiothsm-std.deb
    sudo dpkg -i ./iotedge.deb
    ```

* Prepare certificates
  * Create device identity cert `./certGen.sh create_edge_device_identity_certificate "l5edge"`
  * Get thumbprint of cert `openssl x509 -in certs/iot-edge-device-identity-l5edge.cert.pem -text -fingerprint | grep "SHA1 Fingerprint" | sed 's/://g'`
  * Create Edge CA cert `./certGen.sh create_edge_device_ca_certificate "l5edge"`
  * Use WinSCP to copy following over to the edge
  * Configure IoT Edge in `sudo nano /etc/iotedge/config.yaml`
    ```yaml
provisioning:
  source: "manual"
  authentication:
    method: "x509"
    iothub_hostname: "demo-nested-edge-iothub.azure-devices.net"
    device_id: "l5edge"
    identity_cert: "file:///home/moxa/certs/iot-edge-device-identity-l4edge.cert.pem"
    identity_pk: "file:///home/moxa/certs/iot-edge-device-identity-l4edge.key.pem"
  dynamic_reprovisioning: false

certificates:
  device_ca_cert: "file:///home/moxa/certs/iot-edge-device-ca-l4edge-full-chain.cert.pem"
  device_ca_pk: "file:///home/moxa/certs/iot-edge-device-ca-l4edge.key.pem"
  trusted_ca_certs: "file:///home/moxa/certs/azure-iot-test-only.root.ca.cert.pem"
    ```

* Create device in IoT Hub

Layered deployment commands
```bash
az iot edge deployment create -d sqledgelayered --subscription <subscription id> -n <iothub name --content sqledge.layered.deployment.manifest.json --target-condition "tags.sqledge=true" --layered --priority 200
az iot edge deployment create -d tempsensorlayered --subscription <subscription id> -n <iothub name --content tempsensor.layered.deployment.manifest.json --target-condition "tags.tempsensor=true" --layered --priority 200
az iot edge deployment create -d nested-edge-baseline-v2 --subscription <subscription id> -n <iothub name --content ./manifests/nestedbaseline.deployment.manifest.json --target-condition "tags.nestedEdge=true" --layered --priority 101
az iot edge deployment create -d nestedgatewayedgelayered --subscription <subscription id> -n <iothub name --content ./manifests/nestedgateway.layered.deployment.manifest.json --target-condition "tags.nestedgateway=true" --layered --priority 200
az iot edge deployment create -d topbaselinelayered --subscription <subscription id> -n <iothub name --content ./manifests/nestedbaseline.deployment.manifest.json --target-condition "tags.topnestededge=true" --priority 20
```
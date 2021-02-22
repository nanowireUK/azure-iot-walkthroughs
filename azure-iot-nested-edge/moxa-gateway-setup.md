# Setup Moxa gateway for nested edge

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
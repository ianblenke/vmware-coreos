## ianblenke/vmware-coreos

This is a _very_ simple Makefile based harness for managing a coreos guest under VMWare Fusion, without the abstractions of Vagrant.

When run, this will auto-download the latest CoreOS alpha image and run it so that it appears bridged on your LAN.

The hostname of this guest will be `$(hostname -s)-$(whoami)-vmware-coreos.local`, which should include the hostname of the host running VMWare as well as your username.

A key reason for this harness is to allow me to run windows guests using [ianblenke/docker-kvm](https://github.com/ianblenke/docker-kvm).
For this, VMX emulation is `vhv.enabled`, enabling full kvm hardware virtualization in the CoreOS guest.

The [config-drive/openstack/latest/user_data](config-drive/openstack/latest/user_data) cloud-config cloud-init yaml file:

1. Starts vmware-tools as a systemd service
2. Creates an avahi fleet unit that announces this guest mdns/zeroconf on the local LAN so that your mac can resolve it.

By doing this, you can use the docker mac client much as you would with boot2docker:

    brew install docker
    export DOCKER_HOST=icbimac-iblenke-vmware-coreos.local:2375
    docker ps -a

An additional goal here is to use rawdns and an http caching layer to prevent re-downloading these huge windows images while iterating.


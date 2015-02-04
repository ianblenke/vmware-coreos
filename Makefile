VMRUN:="/Applications/VMware Fusion.app/Contents/Library/vmrun"
VDISKMANAGER:="/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager"
COREOS:=coreos_production_vmware_insecure
NAME:=$(shell hostname -s)-$(shell whoami)-vmware-coreos
MEMSIZE:=4096
DISKSIZE:=40G
PLATFORM:=fusion

usage:
	@echo 'make {list|start|stop|reboot|snapshot|revert|clean|upgradevm|...}'

$(COREOS)/$(COREOS).vmx: $(COREOS) Makefile $(COREOS)/configdrive.iso prepare
	perl -pi -e 's/^memsize.*$$/memsize = "$(MEMSIZE)"/' $@
	if ! grep ide1:0 $@ ; then \
	  echo 'ide1:0.present = "TRUE"' >> $@ ; \
	  echo 'ide1:0.deviceType = "cdrom-image"' >> $@ ; \
	  echo 'ide1:0.filename = "configdrive.iso"' >> $@ ; \
	fi > /dev/null 2>&1
	if ! grep vmci0.present $@ ; then \
	  echo 'vmci0.present = "TRUE"' >> $@ ; \
	fi > /dev/null 2>&1
	if ! grep vmx.allowNested $@ ; then \
	  echo 'vmx.allowNested = "TRUE"' >> $@ ; \
	fi > /dev/null 2>&1
	if ! grep vhv.enable $@ ; then \
	  echo 'vhv.enable = "TRUE"' >> $@ ; \
	fi > /dev/null 2>&1
	# Other things to try
	#vhv.allow="TRUE"
	#vhv.enable="TRUE"
	#monitor.virtual_mmu="hardware"
	#monitor.virtual_exec="hardware"
	#monitor.virtual_mmu="software"
	#monitor.virtual_exec="software"
	#cpuid.1.ecx="----:----:----:----:----:----:--h-:----"
	#hypervisor.cpuid.v0=FALSE
	#signal.suspendOnHUP="TRUE"
	#signal.powerOffOnTERM="TRUE"
	#bios.bootDelay="3000"
	#debugStub.listen.guest32=1
	## gdb target remote localhost:8832
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig memsize "$(MEMSIZE)" 2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig ide1:0.present "TRUE"  2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig ide1:0.filename "configdrive.iso" 2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig ide1:0.deviceType "cdrom-image" 2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig vmci0.present "TRUE" 2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig vmx.allowNested "TRUE" 2>&1 >/dev/null || true

prepare:
	$(VDISKMANAGER) -x $(DISKSIZE) $(COREOS)/$(COREOS)_image.vmdk
	touch $@

$(COREOS): $(COREOS).zip
	unzip $< -d $@

$(COREOS).zip:
	curl -LO http://alpha.release.core-os.net/amd64-usr/current/$(COREOS).zip

config-drive/openstack/latest/user_data:
	mkdir -p `dirname $@`
	touch $@

$(COREOS)/configdrive.iso: config-drive/openstack/latest/user_data
	perl -pi -e 's/^hostname:.*$$/hostname: $(NAME)/' config-drive/openstack/latest/user_data
	which mkisofs || brew install dvdrtool
	mkisofs -R -V config-2 -o $(COREOS)/configdrive.iso config-drive

upgradevm: $(COREOS)/$(COREOS).vmx
	$(VMRUN) -T $(PLATFORM) $@ $< || true

list stop register unregister start: upgradevm
	$(VMRUN) -T $(PLATFORM) $@ $(COREOS)/$(COREOS).vmx

reboot: $(COREOS)/$(COREOS).vmx
	$(VMRUN) -T $(PLATFORM) reset $(COREOS)/$(COREOS).vmx soft

snapshot: $(COREOS)/$(COREOS).vmx
	$(VMRUN) -T $(PLATFORM) snapshot $(COREOS)/$(COREOS).vmx Before
	touch snapshot

revert rollback: $(COREOS)/$(COREOS).vmx
	[ -f snapshot ] && $(VMRUN) -T fusion revertToSnapshot $(COREOS)/$(COREOS).vmx Before
	rm -f snapshot

clean:
	make stop > /dev/null 2>&1 || true
	rm -fr $(COREOS) prepare

distclean: clean
	rm -fr $(COREOS).zip

ps:
	which docker || brew install docker 

myrawdns:
	docker build -t myrawdns rawdns/
	docker run --rm --name myrawdns -p 172.17.42.1:53:53/tcp -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock myrawdns rawdns /etc/rawdns.json

virtio-win-0.1-100.iso:
	wget http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/virtio-win-0.1-100.iso

VMRUN:="/Applications/VMware Fusion.app/Contents/Library/vmrun"
COREOS:=coreos_production_vmware_insecure
PLATFORM:=fusion

usage:
	@echo 'make {list:start|stop|reboot|snapshot|revert|clean}'

$(COREOS)/$(COREOS).vmx: $(COREOS) Makefile $(COREOS)/configdrive.iso
	perl -pi -e 's/^memsize.*$$/memsize = "4096"/' $@
	if ! grep ide1:0 $@ ; then \
	  echo 'ide1:0.present = "TRUE"' >> $@ ; \
	  echo 'ide1:0.deviceType = "cdrom-image"' >> $@ ; \
	  echo 'ide1:0.filename = "configdrive.iso"' >> $@ ; \
	fi > /dev/null 2>&1
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig memsize "4096" 2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig ide1:0.present "TRUE"  2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig ide1:0.filename "configdrive.iso" 2>&1 >/dev/null || true
	$(VMRUN) -T $(PLATFORM) writeVariable $@ runtimeConfig ide1:0.deviceType "cdrom-image" 2>&1 >/dev/null || true

$(COREOS): $(COREOS).zip
	unzip $< -d $@

$(COREOS).zip:
	curl -LO http://alpha.release.core-os.net/amd64-usr/current/$(COREOS).zip

config-drive/openstack/latest/user_data:
	mkdir -p `dirname $@`
	touch $@

$(COREOS)/configdrive.iso: config-drive/openstack/latest/user_data
	which mkisofs || brew install dvdrtool
	mkisofs -R -V config-2 -o $(COREOS)/configdrive.iso config-drive

list stop upgrade register unregister start: $(COREOS)/$(COREOS).vmx
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
	rm -fr $(COREOS)

distclean: clean
	rm -fr $(COREOS).zip


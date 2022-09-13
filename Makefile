SHELL := $(shell which bash)
SUDO  := $(shell which sudo) -E
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ONE_LOCATION := $(abspath $(SELF)/../asd/)

_S_ ?= $(realpath $(SELF)/../one-ee/)
_O_ ?= ubuntu
_G_ ?= $(shell id -ng $(_O_))
_H_ ?= $(realpath $(shell echo ~$(_O_)))
_P_ ?= $(ONE_LOCATION)/sbin:$(ONE_LOCATION)/bin:$$PATH

define SSH_CONFIG
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
ForwardAgent yes
endef

define AWK_ENABLE_MAD_DEBUG
BEGIN { update = "ONE_MAD_DEBUG=1" }
/^#*ONE_MAD_DEBUG=/ { $$0 = update; found = 1 }
{ print }
END { if (!found) print update >>FILENAME }
endef

define AWK_SET_ONEGATE_ENDPOINT
BEGIN { update = "ONEGATE_ENDPOINT = \"http://one:5030\"" }
/^#*ONEGATE_ENDPOINT[^=]*=/ { $$0 = update; found = 1 }
{ print }
END { if (!found) print update >>FILENAME }
endef

define AWK_SET_ONEGATE_PROXY_ENDPOINT
BEGIN { update = "ONEGATE_PROXY_ENDPOINT = \"http://169.254.169.254:5030\"" }
/^#*ONEGATE_PROXY_ENDPOINT[^=]*=/ { $$0 = update; found = 1 }
{ print }
END { if (!found) print update >>FILENAME }
endef

export

.PHONY: all

all:
	@echo ONE_LOCATION = $(ONE_LOCATION)

.PHONY: setup packages rubygems services authorized_keys

setup: packages rubygems services \
       $(_H_)/.ssh/config $(_H_)/.ssh/id_rsa $(_H_)/.ssh/id_rsa.pub authorized_keys \
       $(_H_)/.one/one_auth

packages: PKG := DEBIAN_FRONTEND=noninteractive $(SUDO) apt-get install -y
packages:
	@$(PKG) \
		bash-completion bison \
		debhelper default-jdk \
		flex \
		javahelper \
		libcurl4 libcurl4-openssl-dev libmysql++-dev \
		libsqlite3-dev libssl-dev libsystemd-dev libws-commons-util-java \
		libvncserver-dev libxml2-dev libxmlrpc-c++8-dev libxslt1-dev \
		postgresql-server-dev-all python3-setuptools \
		ruby \
		scons
	@$(PKG) \
		libczmq-dev \
		pciutils \
		rsync
	@$(PKG) \
		bridge-utils \
		dnsmasq \
		libvirt-clients \
		libvirt-daemon-system \
		qemu-kvm qemu-utils

rubygems: $(_S_)
	cd $< && $(SUDO) ./share/install_gems/install_gems

services: SVC := $(SUDO) systemctl
services:
	@$(SVC) disable dnsmasq
	@$(SVC) start libvirtd

authorized_keys: $(_H_)/.ssh/id_rsa.pub
	grep -m1 -f $< $(_H_)/.ssh/authorized_keys || cat $< >> $(_H_)/.ssh/authorized_keys

$(_H_)/.ssh/config:
	install -o $(_O_) -g $(_G_) -m u=rwx,go= -d $(dir $@)
	cat > $@ <<< "$$SSH_CONFIG"

$(_H_)/.ssh/id_rsa $(_H_)/.ssh/id_rsa.pub:
	install -o $(_O_) -g $(_G_) -m u=rwx,go= -d $(dir $@)
	ssh-keygen -t rsa -b 3072 -m PEM -f $(dir $@)/id_rsa -N ''

$(_H_)/.one/one_auth:
	install -o $(_O_) -g $(_G_) -m u=rwx,go= -d $(dir $@)
	install -o $(_O_) -g $(_G_) -m u=rw,go= -D /dev/fd/0 $@ <<< '$(_O_):asd'

.PHONY: b build \
        i install \
        u uninstall

b build: $(_S_)
	cd $< && scons -j4 new_xmlrpc=yes systemd=yes

i install: $(_S_)
	cd $< && ./install.sh -u $(_O_) -g $(_G_) -d $(ONE_LOCATION)
	gawk -i inplace "$$AWK_ENABLE_MAD_DEBUG" $(ONE_LOCATION)/etc/defaultrc
	gawk -i inplace "$$AWK_SET_ONEGATE_ENDPOINT" $(ONE_LOCATION)/etc/oned.conf
	gawk -i inplace "$$AWK_SET_ONEGATE_PROXY_ENDPOINT" $(ONE_LOCATION)/etc/oned.conf

u uninstall: $(ONE_LOCATION) kill
	$(SUDO) rm -rf $<

.PHONY: E Enter \
        e enter \
        s start \
        k kill \
        p ps

E Enter:
	$(SUDO) -u root env PATH=$(_P_) PS1='(\u) \w \$$ ' $(SHELL) --norc -i ||:

e enter:
	env PATH=$(_P_) PS1='(\u) \w \$$ ' $(SHELL) --norc -i ||:

s start:
	export PATH=$(_P_) && oned
	export PATH=$(_P_) && onegate-server start
	export PATH=$(_P_) && ( \
		onehost show localhost || for RETRY in 9 8 7 6 5 4 3 2 1 0; do \
			sleep 4 && if onehost create localhost -i kvm -v kvm; then break; fi; \
		done && [ "$$RETRY" -gt 0 ]; \
	)
	#export PATH=$(_P_) && ( \
	#	for RETRY in 9 8 7 6 5 4 3 2 1 0; do \
	#		sleep 4 && if onehost sync -f; then break; fi; \
	#	done && [ "$$RETRY" -gt 0 ]; \
	#)

k kill:
	for PATTERN in oned onemonitord ruby; do \
		pkill -KILL --uid $(_O_) "$$PATTERN" ||:; \
	done

p ps:
	for PATTERN in oned onemonitord ruby; do \
		pgrep --uid $(_O_) "$$PATTERN" ||:; \
	done

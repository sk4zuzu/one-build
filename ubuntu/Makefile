SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ONE_EE   ?= $(realpath $(SELF)/../../one-ee/)
PACKAGES ?= $(realpath $(SELF)/../../packages/)

DISTRO           ?= ubuntu2004
BUILD_COMPONENTS := fireedge rubygems

ONE_VERSION ?= 6.99.80
PKG_VERSION ?= 1

APACHE_XMLRPC_VERSION ?= 3.1.2

DESTDIR ?= $(abspath /_shared/repo/ubuntu2004/)

export

.PHONY: all build clean requirements

all: build extract

build: $(HOME)/tar/opennebula-$(ONE_VERSION)-$(PKG_VERSION)-amd64.tar.gz

extract: BN = $(notdir $(basename $(basename $<)))
extract: $(HOME)/tar/opennebula-$(ONE_VERSION)-$(PKG_VERSION)-amd64.tar.gz
	rm -rf $(DESTDIR) && install -d $(DESTDIR)
	tar -xzf $< -C $(DESTDIR)
	cd $(DESTDIR)/$(BN) && dpkg-scanpackages ./ | gzip -9c > ./Packages.gz

$(HOME)/tar/opennebula-$(ONE_VERSION)-$(PKG_VERSION)-amd64.tar.gz: \
	$(PACKAGES)/$(DISTRO).sh $(SELF)/.cache/opennebula-$(ONE_VERSION).tar.gz \
                             $(SELF)/.cache/java-oca-$(ONE_VERSION).tar.gz \
                             $(SELF)/.cache/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz
	cd $(dir $<) && $(wordlist 1,2,$^) $(PKG_VERSION) $(wordlist 3,$(words $^),$^)

clean:
	rm -rf $(SELF)/.cache/

$(SELF)/.cache/opennebula-$(ONE_VERSION).tar.gz: CT = $(wildcard $</share/context/*.deb) $(wildcard $</share/context/*.rpm)
$(SELF)/.cache/opennebula-$(ONE_VERSION).tar.gz: DN = $(dir $(realpath $<))
$(SELF)/.cache/opennebula-$(ONE_VERSION).tar.gz: BN = $(notdir $(realpath $<))
$(SELF)/.cache/opennebula-$(ONE_VERSION).tar.gz: $(ONE_EE)
	@install -d $(SELF)/.cache/
	cd $</share/context/ && $(if $(strip $(CT)),:,./download_context.sh)
	cd $</src/sunstone/public/ && (export PATH=$$PATH:$$PWD/node_modules/.bin && ./build.sh -d && rm -rf ./node_modules/)
	tar -czf $@ --transform 's:^$(BN):opennebula-$(ONE_VERSION):' -C $(DN) $(BN)

$(SELF)/.cache/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz: DN = $(dir $(realpath $<))
$(SELF)/.cache/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz: BN = $(notdir $(realpath $<))
$(SELF)/.cache/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz: $(SELF)/.cache/opennebula-fireedge-modules-$(ONE_VERSION)
	tar -czf $@ -C $(DN) $(BN)

$(SELF)/.cache/opennebula-fireedge-modules-$(ONE_VERSION):
	@install -d $@
	grep resolved $(ONE_EE)/src/fireedge/package-lock.json \
	| cut -d'"' -f4 \
	| sort -u \
	| xargs -P3 -n1 wget -x -P $@ --no-verbose --retry-connrefused

$(SELF)/.cache/java-oca-$(ONE_VERSION).tar.gz: $(ONE_EE) $(SELF)/.cache/apache-xmlrpc-$(APACHE_XMLRPC_VERSION)-bin.tar.gz
	sudo tar -xzf $(word 2,$^) --skip-old-files -C /usr/share/java/ --strip-components=2 apache-xmlrpc-$(APACHE_XMLRPC_VERSION)/lib/
	cd $</src/oca/java/ && (./build.sh -p $(ONE_VERSION) && mv $(notdir $@) $@ && rm -f ./jar/*.jar)

$(SELF)/.cache/apache-xmlrpc-$(APACHE_XMLRPC_VERSION)-bin.tar.gz:
	@install -d $(SELF)/.cache/
	curl -fsSLo $@ https://archive.apache.org/dist/ws/xmlrpc/binaries/$(notdir $@)

requirements: PKG := DEBIAN_FRONTEND=noninteractive apt-get install -y
requirements: GEM := gem install --no-document
requirements:
	@$(PKG) \
		gzip \
		tar
	@$(PKG) \
		debhelper \
		distro-info-data \
		pbuilder \
		m4 \
		rename \
		ruby-bundler \
		qemu-user-static \
		ubuntu-dev-tools \
		wget
	@$(PKG) \
		bash-completion bison \
		default-jdk \
		flex \
		javahelper \
		libxml2-dev \
		ruby \
		scons
	@$(PKG) \
		augeas-lenses augeas-tools \
		build-essential \
		libaugeas-dev \
		npm \
		pkg-config \
		ruby-dev
	@$(GEM) \
		addressable amazon-ec2 augeas aws-sdk \
		builder \
		ffi-rzmq \
		git \
		highline \
		ipaddress \
		nokogiri \
		ox \
		parse-cron public_suffix \
		rbvmomi ronn \
		sequel sqlite3 \
		treetop \
		yard

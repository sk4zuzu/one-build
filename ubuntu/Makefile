SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

ONE_EE   ?= $(realpath $(SELF)/../../one-ee/)
PACKAGES ?= $(realpath $(SELF)/../../packages/)

D                ?= Ubuntu/20.04
DISTRO           ?= $(D)
BUILD_COMPONENTS := fireedge rubygems

ONE_VERSION ?= 6.99.80
PKG_VERSION ?= 1

APACHE_XMLRPC_VERSION ?= 3.1.2

TO_SLUG = $(shell tr '[:upper:]' '[:lower:]' <<< '$(1)' | tr -d '/.')

CACHE = $(abspath $(SELF)/.cache/$(DISTRO)/)

DESTDIR ?= $(abspath /_shared/repo/$(call TO_SLUG,$(DISTRO))/repo/$(DISTRO))

export

.PHONY: all build clean requirements

all: build extract

build: $(CACHE)/opennebula-$(ONE_VERSION)-$(PKG_VERSION)-amd64.tar.gz

extract: $(CACHE)/opennebula-$(ONE_VERSION)-$(PKG_VERSION)-amd64.tar.gz
	@rm -rf $(DESTDIR) && install -d $(DESTDIR)/{,pool/opennebula/,dists/stable/opennebula/binary-amd64/}
	tar -xzf $< --strip-components=1 -C $(DESTDIR)/pool/opennebula/
	cd $(DESTDIR) && apt-ftparchive packages --arch amd64 pool/opennebula > dists/stable/opennebula/binary-amd64/Packages
	cd $(DESTDIR) && apt-ftparchive release dists/stable                  > dists/stable/Release
	cd $(DESTDIR) && gpg -o- -ba --detach-sign dists/stable/Release       > dists/stable/Release.gpg

$(CACHE)/opennebula-$(ONE_VERSION)-$(PKG_VERSION)-amd64.tar.gz: \
	$(PACKAGES)/$(call TO_SLUG,$(DISTRO)).sh $(CACHE)/opennebula-$(ONE_VERSION).tar.gz \
                                             $(CACHE)/java-oca-$(ONE_VERSION).tar.gz \
                                             $(CACHE)/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz
	@rm -f $(HOME)/tar/$(notdir $@) # ideally should have no effect
	cd $(dir $<) && $(wordlist 1,2,$^) $(PKG_VERSION) $(wordlist 3,$(words $^),$^)
	@mv $(HOME)/tar/$(notdir $@) $@

clean:
	rm -rf $(CACHE)/

$(CACHE)/opennebula-$(ONE_VERSION).tar.gz: CT = $(wildcard $</share/context/*.deb) $(wildcard $</share/context/*.rpm)
$(CACHE)/opennebula-$(ONE_VERSION).tar.gz: DN = $(dir $(realpath $<))
$(CACHE)/opennebula-$(ONE_VERSION).tar.gz: BN = $(notdir $(realpath $<))
$(CACHE)/opennebula-$(ONE_VERSION).tar.gz: $(ONE_EE)
	@install -d $(dir $@)
	cd $</share/context/ && $(if $(strip $(CT)),:,./download_context.sh)
	cd $</src/sunstone/public/ && (export PATH=$$PATH:$$PWD/node_modules/.bin && ./build.sh -d && rm -rf ./node_modules/)
	tar -czf $@ --transform 's:^$(BN):opennebula-$(ONE_VERSION):' -C $(DN) $(BN)

$(CACHE)/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz: DN = $(dir $(realpath $<))
$(CACHE)/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz: BN = $(notdir $(realpath $<))
$(CACHE)/opennebula-fireedge-modules-$(ONE_VERSION).tar.gz: $(CACHE)/opennebula-fireedge-modules-$(ONE_VERSION)
	tar -czf $@ -C $(DN) $(BN)

$(CACHE)/opennebula-fireedge-modules-$(ONE_VERSION):
	@install -d $@
	grep resolved $(ONE_EE)/src/fireedge/package-lock.json \
	| cut -d'"' -f4 \
	| sort -u \
	| xargs -P3 -n1 wget -x -P $@ --no-verbose --retry-connrefused

$(CACHE)/java-oca-$(ONE_VERSION).tar.gz: $(ONE_EE) $(CACHE)/apache-xmlrpc-$(APACHE_XMLRPC_VERSION)-bin.tar.gz
	sudo tar -xzf $(word 2,$^) --skip-old-files -C /usr/share/java/ --strip-components=2 apache-xmlrpc-$(APACHE_XMLRPC_VERSION)/lib/
	cd $</src/oca/java/ && (./build.sh -p $(ONE_VERSION) && mv $(notdir $@) $@ && rm -f ./jar/*.jar)

$(CACHE)/apache-xmlrpc-$(APACHE_XMLRPC_VERSION)-bin.tar.gz:
	@install -d $(dir $@)
	curl -fsSLo $@ https://archive.apache.org/dist/ws/xmlrpc/binaries/$(notdir $@)

requirements: PKG := DEBIAN_FRONTEND=noninteractive apt-get install -y
requirements: GEM := gem install --no-document
requirements:
	@$(PKG) \
		apt-utils \
		gnupg2 \
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

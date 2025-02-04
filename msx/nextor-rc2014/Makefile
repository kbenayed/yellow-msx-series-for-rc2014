SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.DELETE_ON_ERROR:

BINDIR := ./bin/

ASM = sjasmplus --msg=war --nologo --fullpath --inc=../nextor/source/kernel/ --raw=$@ --sym=$(basename $@).sym.asm --lst=$@.lst --exp=$(basename $@).exp.asm

all: $(BINDIR)cbios.nextor.rom $(BINDIR)rc2014.nextor.rom

.PHONY: clean
clean:
	@rm -rf bin
	cd ../nextor/source && make clean --no-print-directory -f Makefile-rc2014.mk

$(BINDIR)rcembdrv.bin: rcembdrv.asm embinc.asm rc2014dr.inc.asm
	@mkdir -p $(BINDIR)
	$(ASM) rcembdrv.asm rc2014dr.inc.asm
	filesize=$$(stat -c%s "$(BINDIR)rcembdrv.bin")
	if ((filesize > 16484 )); then
		echo -e "\r\nError: $(BINDIR)rcembdrv.bin exceeded size of 16k"
		exit 1
	fi
	echo "Assembled $@"

$(BINDIR)rc2014dr.bin: rc2014dr.asm cfdrv.asm musicdriver.asm embinc.asm rc2014dr.inc.asm version.asm ch376drv.asm $(BINDIR)usbdrv.bin drvend.asm
	@mkdir -p $(BINDIR)
	$(ASM) rc2014dr.asm ch376drv.asm rc2014dr.inc.asm drvend.asm
	basedrv_filesize=$$(stat -c%s "$(BINDIR)rc2014dr.bin")
	cat $(BINDIR)rc2014dr.bin $(BINDIR)usbdrv.bin > $(BINDIR)tmp.bin
	rm $(BINDIR)rc2014dr.bin
	cp $(BINDIR)tmp.bin $(BINDIR)rc2014dr.bin
	filesize=$$(stat -c%s "$(BINDIR)rc2014dr.bin")
	if ((filesize > 16484 )); then
		echo -e "\r\nError: $(BINDIR)rc2014dr.bin exceeded size of 16k"
		echo -e "Size: $$filesize"
		exit 1
	fi
	usbdrv_filesize=$$(stat -c%s "$(BINDIR)usbdrv.bin")
	echo "Assembled $@ ($$filesize bytes)"
	echo "          basdrv.bin ($$basedrv_filesize bytes)"
	echo "          usbdrv.bin ($$usbdrv_filesize bytes)"

$(BINDIR)unapi-nextor-id.dat: unapi-nextor-id.asm
	@mkdir -p $(BINDIR)
	$(ASM) unapi-nextor-id.asm

$(BINDIR)chgbnk.bin: chgbnk.asm
	@mkdir -p $(BINDIR)
	$(ASM) $^
	sjasmplus --fullpath --inc=../nextor/source/kernel/ --lst=$(BINDIR)chgbnk.lst --exp=$(BINDIR)chgbnk.exp.asm --raw=$(BINDIR)chgbnk.bin --sym=$(BINDIR)chgbnk.sym.asm chgbnk.asm
	echo "Assembled $@"

cbios-nextor-kernel:
	@cd ../nextor/source && BUILD_TYPE=cbios $(MAKE) --no-print-directory -f Makefile-rc2014.mk

rc2014-nextor-kernel:
	@cd ../nextor/source && BUILD_TYPE=rc2014 $(MAKE) --no-print-directory -f Makefile-rc2014.mk


define BUILD_versions =
# Build a FAT12 floppy disk image containing nextor.sys, command2.com and other files
.PHONY: $(BINDIR)$1.fdd.dsk
$(BINDIR)$1.fdd.dsk: $1-nextor-kernel $(BINDIR)rcembdrv.bin
	@mkdir -p $(BINDIR)
	DATSIZ=$$$$(./scripts/getsymb.sh $(BINDIR)rcembdrv.exp.asm DATSIZ)
	rm -f $(BINDIR)$1.fdd.dsk
	dd status=none if=/dev/zero of=$(BINDIR)$1.fdd.dsk bs=$$$$(($$$$DATSIZ*18)) count=1
	mkfs.vfat -F 12 -f 1 -n RC2014 -i 80000000 -a $(BINDIR)$1.fdd.dsk > /dev/null
	mmd -i $(BINDIR)$1.fdd.dsk APPS
	mmd -i $(BINDIR)$1.fdd.dsk SYSTEM
	mcopy -i $(BINDIR)$1.fdd.dsk ../nextor/bin/working/$1/*.com ::/SYSTEM/
	[[ $$$$(ls -A ./extras) ]] && mcopy -i $(BINDIR)$1.fdd.dsk ./extras/* ::/
	mmove -i $(BINDIR)$1.fdd.dsk ::/SYSTEM/COMMAND2.com ::/
	mcopy -i $(BINDIR)$1.fdd.dsk ../nextor/bin/working/$1/nextor.sys ::/
	freespace=$$$$(mdir -i $(BINDIR)$1.fdd.dsk | grep free | sed 's/bytes free//' | sed 's/ //g')
	echo "Built disk image $1.fdd.dsk ($$$$freespace bytes free)"

#Package driver and disk image
$(BINDIR)$1.driver-with-sectors.bin: $(BINDIR)rc2014dr.bin $(BINDIR)rcembdrv.bin $(BINDIR)$1.fdd.dsk
	@cd $(BINDIR)
	SECSTRT=$$$$(../scripts/getsymb.sh rcembdrv.exp.asm SECSTR)
	DATSIZ=$$$$(../scripts/getsymb.sh rcembdrv.exp.asm DATSIZ)
	dd status=none if=/dev/zero of=$1.driver-with-sectors.bin bs=16k count=19 seek=0
	dd status=none conv=notrunc if=rc2014dr.bin of=$1.driver-with-sectors.bin bs=8k count=2 seek=0
	BNK_START_ADDR=$$$$((SECSTRT-16384))
	for i in {1..18}
	do
		BNK_ADDR=$$$$(($$$$BNK_START_ADDR + (16384*($$$$i))))
		SKIP=$$$$(($$$$DATSIZ*($$$$i-1)))
		dd status=none conv=notrunc if=rcembdrv.bin of=$1.driver-with-sectors.bin bs=8k count=1 seek=$$$$((2*$$$$i))
		dd status=none conv=notrunc if=$1.fdd.dsk of=$1.driver-with-sectors.bin bs=1 count=$$$${DATSIZ} seek=$$$$BNK_ADDR skip=$$$$SKIP
	done
	# echo "Built image $(BINDIR)$1.driver-with-sectors.bin"

#Package rom with driver and disk image
$(BINDIR)$1.nextor.rom: $(BINDIR)$1.driver-with-sectors.bin $(BINDIR)chgbnk.bin $(BINDIR)unapi-nextor-id.dat
	@cd $(BINDIR)
	../../nextor/linuxtools/mknexrom ../../nextor/bin/working/$1/dos250ba.dat $1.nextor.rom -q -e:unapi-nextor-id.dat -d:$1.driver-with-sectors.bin -m:chgbnk.bin

endef

$(eval $(call BUILD_versions,cbios))
$(eval $(call BUILD_versions,rc2014))

include ./usbdrv/Makefile
include ./depends.d

ifndef VERSION
override VERSION=$$(date +"%m-%d %H-%M")
endif

.PHONY: $(BINDIR)version.asm
$(BINDIR)version.asm:
	@mkdir -p $(BINDIR)
	echo -e "INFO_S:			DB	10, 13, \"MSX ON RC2014 ($(VERSION))\", 10, 13\r\n" > "$(BINDIR)version.asm"

version.asm: $(BINDIR)version.asm
	@echo "ROM version $(VERSION)"
	cmp --silent "$(BINDIR)version.asm" "./version.asm" || echo -e "INFO_S:			DB	10, 13, \"MSX ON RC2014 ($(VERSION))\", 10, 13\r\n" > "./version.asm"

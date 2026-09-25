FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
KMACHINE:rtl83xx = "rtl83xx"

COMPATIBLE_MACHINE .= "|rtl83xx"


# Base configuration: OpenWrt's generic + rtl838x configs, merged the way
# OpenWrt itself does it. kernel-yocto.bbclass picks "defconfig" out of SRC_URI
# and uses it as the merge_config.sh base.
SRC_URI += "file://defconfig"

# Board/policy deltas, shipped as kernel metadata so scc can resolve the .scc
# and its .cfg fragments as one unit. type=kmeta puts the directory on scc's
# include path (kernel-yocto.bbclass:234-238).
SRC_URI += "file://rtl83xx-kmeta;type=kmeta;destsuffix=rtl83xx-kmeta"
KERNEL_FEATURES:append:rtl83xx = " features/rtl83xx/rtl83xx.scc"

# Boards whose buttons or DIP switches sit behind gpio-keys-polled. The shared
# configuration leaves the input subsystem out (OpenWrt handles buttons with
# its own gpio-button-hotplug module), so it is added only where a board uses
# it, and the other kernels do not grow.
KERNEL_FEATURES:append:albrecht-rtl8382mi-test = " features/rtl83xx/gpio-keys.scc"

# The default of 1 passes --classify to symbol_why.py, which filtered the
# mismatch report away entirely while the whole networking stack was silently
# being dropped. At 2 every requested-but-missing symbol is reported and
# .kernel-meta/cfg/mismatch.txt is written.
KCONF_AUDIT_LEVEL = "2"


# ---------------------------------------------------------------------------
# Additional Openwrt source files
# ---------------------------------------------------------------------------

SRC_URI += " \
    file://0001-realtek-tntegrated-code-from-OpenWrt-git-hash-f0d3e3.patch \
    file://0002-realtek-dts-add-zyxel-gs1900-8-a1-device-tree-copied.patch \
    file://0003-Add-mtd-split-from-OpenWrt-f0d3e332e5f839508f77fba8c.patch \
    file://0004-realtek-dts-replace-rtl838x.dtsi-with-the-OpenWrt-ver.patch \
    file://0006-realtek-dts-gs1900-data-partition-and-flash-root.patch \
    file://0007-mtd-mtdsplit-add-uimage-dt-bindings-header-from-OpenWrt.patch \
    file://0008-realtek-dts-add-albrecht-rtl8382mi-test-device-tree.patch \
    file://0009-realtek-dts-rtl8382mi-test-data-partition-and-flash-root.patch \
"


# ---------------------------------------------------------------------------
# OpenWrt generic patches
# ---------------------------------------------------------------------------

# SRC_URI += "file://openwrt-generic-patches/backport-6.18/010-v6.19-nvmem-layouts-u-boot-env-add-optional-env-size-property.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/211-01-v6.19-bitfield-Add-less-checking-__FIELD_-GET-PREP.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/211-02-v6.19-bitfield-Add-non-constant-field_-prep-get-helpers.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/434-v6.19-mtd-spinand-esmt-add-support-for-F50L1G41LC.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/435-v6.19-mtd-spinand-add-support-for-FudanMicro-FM25S01BI3.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/436-v7.3-mtd-spinand-add-support-for-HeYangTek-HYF1GQ4UDACAE.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/436-v7.3-mtd-spinand-fmsh-add-support-for-FM25G01B-FM25G02B.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/437-v7.3-mtd-spinand-fmsh-fix-FM25G01B-FM25G02B-Quad-IO-read-dummy-cycles.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/440-v7.0-mtd-physmap-core-Prioritize-ofparts-for-OF-probe.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/500-v6.19-ksmbd-server-avoid-busy-polling-in-accept-loop.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/501-v7.1-ksmbd-harden-file-lifetime-during-session-teardown.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/502-v7.3-smb-server-fix-signing-multi-iov-response.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/503-01-v7.3-ksmbd-enable-tcp-keepalive-for-accepted-connections.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/503-02-v7.3-ksmbd-keep-tcp-timers-alive-for-kernel-sockets.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/504-v7.3-ksmbd-fix-listener-task-lifetime-on-netdev-events.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/601-v7.1-net-add-netdev_from_priv-helper.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/613-07-v6.19-net-dsa-b53-allow-VID-0-for-BCM5325-65.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/626-25-v6.19-net-pse-pd-pd692x0-Replace-__free-macro.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/626-26-v6.19-net-pse-pd-pd692x0-Separate-configuration-parsing.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/626-27-v6.19-net-pse-pd-pd692x0-Preserve-PSE-configuration.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/626-28-v6.19-net-pse-pd-tps23881-Add-support-for-TPS23881B.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/650-v7.2-net-pppoe-implement-GRO-GSO-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-01-v7.0-net-sched-Export-mq-functions-for-reuse.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-02-v7.0-net-sched-sch_cake-Factor-out-config-variables-into-.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-03-v7.0-net-sched-sch_cake-Add-cake_mq-qdisc-for-using-cake-.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-04-v7.0-net-sched-sch_cake-Share-config-across-cake_mq-sub-q.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-05-v7.0-net-sched-sch_cake-share-shaper-state-across-sub-ins.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-06-v7.0-selftests-tc-testing-add-selftests-for-cake_mq-qdisc.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/700-07-v7.0-net-sched-cake-avoid-separate-allocation-of-struct-c.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/701-01-v7.0-net-sched-sch_cake-avoid-sync-overhead-when-unlimite.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/701-02-v7.0-net-sched-sch_cake-fixup-cake_mq-rate-adjustment-for.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/702-v7.0-net-phylink-fix-NULL-pointer-deref-in-phylink_major_.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/703-01-v7.0-net-phylink-simplify-phylink_resolve-phylink_major_c.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/703-02-v7.0-net-phylink-introduce-helpers-for-replaying-link-cal.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/704-v7.3-net-phylink-treat-PSGMII-as-an-inband-capable-interface.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/705-01-v7.0-net-phy-motorcomm-Support-YT8531S-PHY-in-YT6801-Ethernet.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/705-02-v7.0-net-stmmac-Add-glue-driver-for-Motorcomm-YT6801-ethernet.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/706-v7.2-bus-mhi-host-pci_generic-round-up-nr_irqs-to-a-power-of-two.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/710-01-v7.1-net-sfp-add-quirk-for-ZOERAX-SFP-2.5G-T.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/711-v7.2-net-phy-sfp-detect-presence-via-I2C-when-no-MOD_DEF0-GPIO.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/730-10-v6.19-net-phy-mxl-gpy-add-support-for-MxL86211C.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/730-11-v7.0-net-phy-mxl-gpy-implement-SGMII-in-band-configuratio.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/737-01-v7.3-net-phylink-allow-PHYs-to-be-attached-in-802.3z-inba.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/737-03-v7.3-net-phylink-correctly-validate-returned-PCS-in-phyli.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/740-v6.19-r8152-Advertise-software-timestamp-information.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/741-v7.1-r8152-Add-2500baseT-EEE-status-configuration-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/743-v7.1-r8152-add-helper-functions-for-PLA-USB-OCP-registers.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/744-v7.1-r8152-add-helper-functions-for-PHY-OCP-registers.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/745-v7.1-r8152-Add-helper-functions-for-SRAM2.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/746-v7.1-r8152-Add-support-for-5Gbit-Link-Speeds-and-EEE.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/747-v7.1-r8152-Add-support-for-the-RTL8157-hardware.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/750-v7.0-net-phy-move-mmd_phy_read-and-mmd_phy_write-to-phyli.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/751-v7.2-net-dsa-qca8k-add-support-for-force-mode-for-fixed-l.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/755-v7.3-net-sfp-add-quirk-for-HORACO-copper-SFP-module.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/761-v6.19-net-phy-mxl-gpy-add-support-for-mxl86252-and-mxl86282.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/762-v7.0-net-dsa-add-tag-format-for-MxL862xx-switches.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/763-v7.0-net-mdio-add-unlocked-mdiodev-C45-bus-accessors.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/764-v7.0-net-dsa-add-basic-initial-driver-for-MxL862xx-switch.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/765-v7.0-net-dsa-mxl862xx-rename-MDIO-op-arguments.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/766-v7.0-net-dsa-mxl862xx-don-t-set-user_mii_bus.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/767-v7.0-net-dsa-mxl862xx-don-t-read-out-of-bounds.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/768-v7.1-net-dsa-MxL862xx-don-t-force-enable-MAXLINEAR_GPHY.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/769-v7.1-net-dsa-mxl862xx-add-CRC-for-MDIO-communication.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/770-v7.1-net-dsa-mxl862xx-use-RST_DATA-to-skip-writing-zero-w.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/771-v7.1-net-dsa-mxl862xx-cancel-pending-work-on-probe-error.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/772-v7.1-net-dsa-move-dsa_bridge_ports-helper-to-dsa.h.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/773-v7.1-net-dsa-add-bridge-member-iteration-macro.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/774-v7.1-dsa-tag_mxl862xx-set-dsa_default_offload_fwd_mark.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/775-v7.1-net-dsa-mxl862xx-implement-bridge-offloading.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/776-v7.1-net-dsa-mxl862xx-reject-DSA_PORT_TYPE_DSA.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/777-v7.1-net-dsa-mxl862xx-don-t-skip-early-bridge-port-config.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/778-v7.1-net-dsa-mxl862xx-implement-VLAN-functionality.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/779-v7.1-net-dsa-mxl862xx-add-ethtool-statistics-support.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/780-v7.1-net-dsa-mxl862xx-implement-.get_stats64.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-01-v7.2-net-dsa-mxl862xx-store-firmware-version-for-feature-.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-02-v7.2-net-dsa-mxl862xx-move-phylink-stubs-to-mxl862xx-phyl.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-03-v7.2-net-dsa-mxl862xx-move-API-macros-to-mxl862xx-host.h.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-04-v7.2-net-dsa-mxl862xx-add-support-for-SerDes-ports.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-05-v7.2-net-dsa-mxl862xx-avoid-unaligned-16-bit-access-in-ap.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-06-v7.2-net-dsa-mxl862xx-fix-use-after-free-of-DSA-ports-in-.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/781-v7.1-net-mvneta-support-EPROBE_DEFER-when-reading-MAC-add.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/784-06-v6.19-net-phy-realtek-Add-RTL8224-cable-testing-support.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/784-07-v6.19-net-phy-realtek-add-interrupt-support-for-RTL8221B.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-01-dt-bindings-phy-rename-transmit-amplitude.yaml-to-ph.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-02-dt-bindings-phy-common-props-create-a-reusable-proto.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-03-dt-bindings-phy-common-props-ensure-protocol-names-a.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-04-dt-bindings-phy-common-props-RX-and-TX-lane-polarity.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-05-phy-add-phy_get_rx_polarity-and-phy_get_tx_polarity.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-06-dt-bindings-net-airoha-en8811h-deprecate-airoha-pnsw.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-07-net-phy-air_en8811h-deprecate-airoha-pnswap-rx-and-a.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-08-dt-bindings-net-pcs-mediatek-sgmiisys-deprecate-medi.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-09-net-pcs-pcs-mtk-lynxi-pass-SGMIISYS-OF-node-to-PCS.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-10-net-pcs-pcs-mtk-lynxi-deprecate-mediatek-pnswap.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/785-v7.0-11-phy-enter-drivers-phy-Makefile-even-without-CONFIG_G.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/786-01-v7.4-net-phy-add-phy_detach_internal-helper.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/786-02-v7.4-net-phy-add-notify_phy_attach_detach-hooks-to-struct-mii_bus.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/786-v7.3-net-phy-air_en8811h-move-LED-GPIO-configuration-to-config_init.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/788-v7.0-net-phy-realtek-fix-whitespace-in-struct-phy_driver-.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/789-v7.0-net-phy-realtek-implement-configuring-in-band-an.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/790-v7.0-net-phy-realtek-use-paged-access-for-MDIO_MMD_VEND2-.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/791-v7.0-net-phy-realtek-get-rid-of-magic-number-in-rtlgen_re.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/792-v7.0-net-phy-realtek-add-dummy-PHY-driver-for-RTL8127ATF.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/793-v7.0-net-phy-realtek-fix-in-band-capabilities-for-2.5G-PH.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/794-v7.0-net-phy-realtek-support-interrupt-also-for-C22-varia.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/795-v7.0-net-phy-realtek-simplify-C22-reg-access-via-MDIO_MMD.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/796-v7.0-net-phy-realtek-reunify-C22-and-C45-drivers.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/797-v7.0-net-phy-realtek-demystify-PHYSR-register-location.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/798-v7.0-net-phy-realtek-simplify-bogus-paged-operations.patch"
SRC_URI += "file://openwrt-generic-patches/backport-6.18/799-v7.2-net-phy-realtek-Add-support-for-PHY-LEDs-on-RTL8221B.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/821-01-v7.0-dt-bindings-gpio-add-gpio-line-mux-controller.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/821-02-v7.0-gpio-add-gpio-line-mux-driver.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/821-03-v7.0-gpio-line-mux-remove-bits-already-handled-by-GPIO-co.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/822-v6.19-ALSA-usb-audio-Convert-to-common-field_-get-prep-hel.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/823-v6.19-clk-at91-Convert-to-common-field_-get-prep-helpers.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/824-v6.19-iio-mlx90614-Convert-to-common-field_-get-prep-helpe.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/825-v6.19-pinctrl-ma35-Convert-to-common-field_-get-prep-helpe.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/830-v7.0-hwmon-emc2305-Simplify-with-scoped-for-each-OF-child.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/842-v7.2-hwmon-lm63-make-pwm1_freq-and-lut-hyst-writable.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/851-01-v7.3-dt-bindings-hwmon-add-adi-adt7470.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/851-02-v7.3-hwmon-adt7470-Add-ADT7470_PWM_MAX-macro.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/851-03-v7.3-hwmon-adt7470-Expose-fan-control-via-PWM-framework.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/851-04-v7.3-hwmon-adt7470-Add-thermal-zone-sensor-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/894-v7.3-usb-xhci-handle-port-events-when-there-is-one-roothub.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/907-v6.19-genirq-Change-hwirq-parameter-to-irq_hw_number_t.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/908-1-v7.0-genirq-Add-interrupt-redirection-infrastructure.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/908-2-v7.0-PCI-dwc-Code-cleanup.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/908-3-v7.0-PCI-dwc-Enable-MSI-affinity-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/909-v7.0-genirq-Update-effective-affinity-for-redirected-inte.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/910-v6.19-crypto-testmgr-Add-missing-DES-weak-and-semi-weak-ke.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/911-v7.0-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/912-v7.0-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/913-v7.0-crypto-testmgr-Add-test-vectors-for-authenc-hmac-md5.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/914-v7.0-crypto-testmgr-allow-authenc-sha224-rfc3686-variant-.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/915-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-md5.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/916-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/917-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/918-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/919-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/920-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-sha.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/921-v7.1-crypto-tesmgr-allow-authenc-hmac-sha224-sha384-cbc-a.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/922-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-md5.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/923-v7.1-crypto-testmgr-Add-test-vectors-for-authenc-hmac-md5.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/930-v7.1-crypto-safexcel-Group-authenc-ciphersuites.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/931-v7.1-crypto-safexcel-Add-support-for-authenc-hmac-md5-sui.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/932-v7.1-crypto-tcrypt-clamp-num_mb-to-avoid-divide-by-zero.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/933-v7.1-crypto-tcrypt-stop-ahash-speed-tests-when-setkey-fai.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/940-01-v7.1-net-dsa-tag_rtl8_4-update-format-description.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/940-02-v7.1-net-dsa-tag_rtl8_4-set-KEEP-flag.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/941-v7.2-net-dsa-realtek-rtl8365mb-add-support-for-rtl8367sb.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-01-v7.2-net-dsa-realtek-rtl8365mb-use-ERR_PTR.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-02-v7.2-net-dsa-realtek-rtl8365mb-reject-unsupported-topolog.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-03-v7.2-net-dsa-realtek-rtl8365mb-use-dsa-helpers-for-port-i.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-04-v7.2-net-dsa-realtek-rtl8365mb-prepare-for-multiple-sourc.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-05-v7.2-net-dsa-realtek-rtl8365mb-add-table-lookup-interface.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-06-v7.2-net-dsa-realtek-rtl8365mb-add-VLAN-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-07-v7.2-net-dsa-realtek-rtl8365mb-add-FDB-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-08-v7.2-net-dsa-realtek-rtl8365mb-add-port_bridge_-join-leav.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/942-09-v7.2-net-dsa-realtek-rtl8365mb-add-bridge-port-flags.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/943-01-v7.3-net-dsa-realtek-rtl8365mb-add-SGMII-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/943-02-v7.3-net-dsa-realtek-rtl8365mb-add-HSGMII-support.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/944-01-v7.2-net-dsa-realtek-rtl8365mb-use-devm_mutex_init-for-mib_lock.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/944-02-v7.2-net-dsa-realtek-use-devm_mutex_init-for-regmap-lock.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/944-03-v7.2-net-dsa-realtek-use-devm_mutex_init-for-vlan_lock.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/944-04-v7.2-net-dsa-realtek-use-devm_mutex_init-for-l2_lock.patch"
# SRC_URI += "file://openwrt-generic-patches/backport-6.18/945-v7.2-net-dsa-mxl862xx-enable-assisted-learning-on-cpu-port.patch"



# SRC_URI += "file://openwrt-generic-patches/pending-6.18/100-compiler.h-only-include-asm-rwonce.h-for-kernel-code.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/102-MIPS-only-process-negative-stack-offsets-on-stack-tr.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/103-kbuild-export-SUBARCH.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/111-watchdog-max63xx_wdt-Add-support-for-specifying-WDI-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/140-jffs2-use-.rename2-and-add-RENAME_WHITEOUT-support.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/141-jffs2-add-RENAME_EXCHANGE-support.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/142-jffs2-add-splice-ops.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/150-bridge_allow_receiption_on_disabled_port.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/151-net-bridge-do-not-send-arp-replies-if-src-and-target.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/190-rtc-rs5c372-support_alarms_up_to_1_week.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/191-rtc-rs5c372-let_the_alarm_to_be_used_as_wakeup_source.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/200-ARM-9404-1-arm32-fix-boot-hang-with-HAVE_LD_DEAD_COD.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/203-kallsyms_uncompressed.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/205-backtrace_module_info.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/240-remove-unsane-filenames-from-deps_initramfs-list.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/250-kernel-fork-Increase-minimum-number-of-allowed-threa.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/270-platform-mikrotik-build-bits.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/300-mips_expose_boot_raw.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/301-MIPS-Add-barriers-between-dcache-icache-flushes.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/302-mips_no_branch_likely.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/308-mips32r2_tune.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/310-arm_module_unresolved_weak_sym.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/330-MIPS-kexec-Accept-command-line-parameters-from-users.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/342-powerpc-Enable-kernel-XZ-compression-option-on-PPC_8.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/350-mips-kernel-fix-detect_memory_region-function.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/400-mtd-mtdsplit-support.patch"
# Not part of the copied pending/backport series: 400 only declares
# MTD_ROOTFS_ROOT_DEV, this hack is what sets ROOT_DEV to the mtd named
# "rootfs" that mtdsplit_uimage carves out of "firmware".
SRC_URI += "file://openwrt-generic-patches/hack-6.18/420-mtd-support-OpenWrt-s-MTD_ROOTFS_ROOT_DEV.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/402-mtd-spi-nor-write-support-for-minor-aligned-partitions.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/417-mtd-spi-nand-macronix-disable-continuous-read-for-MX.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/420-mtd-redboot_space.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/430-mtd-add-myloader-partition-parser.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/431-mtd-bcm47xxpart-check-for-bad-blocks-when-calculatin.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/432-mtd-bcm47xxpart-detect-T_Meter-partition.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/435-mtd-add-routerbootpart-parser-config.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/450-block-allow-setting-partition-of_node.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/451-block-partitions-of-assign-Device-Tree-node-to-parti.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/452-partitions-efi-apply-Linux-code-style.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/453-partitions-efi-allow-assigning-partition-Device-Tree.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/454-block-add-support-for-notifications.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/455-block-add-new-genhd-flag-GENHD_FL_NVMEM.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/456-nvmem-implement-block-NVMEM-provider.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/457-mmc-block-set-GENHD_FL_NVMEM.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/460-mtd-cfi_cmdset_0002-no-erase_suspend.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/461-mtd-cfi_cmdset_0002-add-buffer-write-cmd-timeout.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/476-mtd-spi-nor-add-eon-en25q128.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/477-mtd-spi-nor-add-eon-en25qx128a.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/479-mtd-spi-nor-add-xtx-xt25f128b.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/481-mtd-spi-nor-add-support-for-Gigadevice-GD25D05.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/482-mtd-spi-nor-add-gd25q512.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/484-mtd-spi-nor-add-esmt-f25l16pa.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/485-mtd-spi-nor-add-xmc-xm25qh128c.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/487-mtd-spinand-Add-support-for-Etron-EM73D044VCx.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/488-mtd-spi-nor-add-xmc-xm25qh64c.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/490-ubi-auto-attach-mtd-device-named-ubi-or-data-on-boot.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/491-ubi-auto-create-ubiblock-device-for-rootfs.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/492-try-auto-mounting-ubi0-rootfs-in-init-do_mounts.c.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/493-ubi-set-ROOT_DEV-to-ubiblock-rootfs-if-unset.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/494-mtd-ubi-add-EOF-marker-support.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/496-dt-bindings-add-bindings-for-mtd-concat-devices.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/497-mtd-mtdconcat-add-dt-driver-for-concat-devices.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/500-fs_cdrom_dependencies.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/510-block-add-uImage.FIT-subimage-block-driver.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/511-init-bypass-device-lookup-for-dev-fit-rootfs.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/530-jffs2_make_lzma_available.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/532-jffs2_eofdetect.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/600-netfilter_conntrack_flush.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/630-packet_socket_type.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/640-net-bridge-fix-switchdev-host-mdb-entry-updates.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/641-net-bridge-switchdev-Don-t-drop-packets-between-port.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/655-increase_skb_pad.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/666-Add-support-for-MAP-E-FMRs-mesh-mode.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/670-ipv6-allow-rejecting-with-source-address-failed-policy.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/671-net-provide-defines-for-_POLICY_FAILED-until-all-cod.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/681-net-remove-NETIF_F_GSO_FRAGLIST-from-NETIF_F_GSO_SOF.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/683-of_net-add-mac-address-to-of-tree.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/700-netfilter-nft_flow_offload-handle-netdevice-events-f.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/701-netfilter-nf_tables-ignore-EOPNOTSUPP-on-flowtable-d.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/702-net-ethernet-mtk_eth_soc-enable-threaded-NAPI.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/703-phy-add-detach-callback-to-struct-phy_driver.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/704-net-dsa-support-EPROBE_DEFER-when-reading-the-port-M.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/705-net-dsa-tag_mtk-add-padding-for-tx-packets.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/706-net-phy-populate-host_interfaces-when-attaching-PHY.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/707-net-pcs-pcs-mtk-lynxi-fix-bpi-r3-serdes-configuratio.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/710-bridge-add-knob-for-filtering-rx-tx-BPDU-pack.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-01-net-dsa-qca8k-implement-lag_fdb_add-del-ops.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-02-net-dsa-qca8k-enable-flooding-to-both-CPU-port.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-03-net-dsa-qca8k-add-support-for-port_change_master.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-04-net-dsa-qca8k-no-program-unicast-host-FDB-entries.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-05-net-dsa-qca8k-fall-back-to-ethernet-ports-node-name-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-06-net-dsa-qca8k-support-PHY-to-PHY-CPU-link.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-07-net-dsa-qca8k-use-correct-CPU-port-when-having-multi.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/711-08-net-dsa-qca8k-implement-ds-ops-preferred_default_loc.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/712-net-dsa-qca8k-enable-assisted-learning-on-CPU-port.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/713-net-phy-c45-check-validity-of-10GbE-link-partner.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/715-net-phy-aquantia-add-support-for-CUX3410.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-01-net-phy-realtek-use-genphy_soft_reset-for-2.5G-PHYs.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-03-net-phy-realtek-make-sure-paged-read-is-protected-by.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-04-net-phy-realtek-setup-aldps.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-05-net-phy-realtek-detect-early-version-of-RTL8221B.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-06-net-phy-realtek-mark-existing-MMDs-as-present.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-07-net-phy-realtek-disable-MDIO-broadcast.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/720-08-net-phy-realtek-rate-adapter-in-C22-mode.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/731-net-permit-ieee80211_ptr-even-with-no-CFG82111-suppo.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/732-00-net-ethernet-mtk_eth_soc-compile-out-netsys-v2-code-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/732-01-net-ethernet-mtk_eth_soc-work-around-issue-with-send.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/732-03-net-ethernet-mtk_eth_soc-optimize-dma-ring-address-i.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/732-04-net-ethernet-mtk_eth_soc-shrink-struct-mtk_tx_buf.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/732-05-net-ethernet-mtk_eth_soc-add-support-for-sending-fra.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/733-01-net-ethernet-mtk_eth_soc-use-napi_build_skb.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/734-net-ethernet-mediatek-enlarge-DMA-reserve-buffer.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/736-03-net-ethernet-mtk_eth_soc-improve-keeping-track-of-of.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/736-04-net-ethernet-mediatek-fix-ppe-flow-accounting-for-L2.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/736-05-net-ethernet-mtk_eth_soc-zero-initialize-PPE-flow-ta.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-01-net-phylink-keep-and-use-MAC-supported_interfaces-in.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-02-net-phylink-introduce-internal-phylink-PCS-handling.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-03-net-pcs-implement-Firmware-node-support-for-PCS-driv.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-04-net-phylink-save-phylink-instance-fwnode-on-phylink_.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-05-net-phylink-support-PCS-provider-release.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-06-net-phylink-support-late-PCS-provider-attach.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-07-net-phylink-add-.pcs_link_down-PCS-OP.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-08-dt-bindings-net-ethernet-controller-permit-to-define.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-09-net-ethernet-mtk_eth_soc-improve-probe-deferal.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/737-10-net-ethernet-mtk_eth_soc-add-paths-and-SerDes-modes-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/738-01-net-ethernet-mtk_eth_soc-reduce-rx-ring-size-for-older.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/738-02-net-ethernet-mtk_eth_soc-do-not-enable-page-pool-sta.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/739-03-net-pcs-pcs-mtk-lynxi-add-platform-driver-for-MT7988.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/739-04-dt-bindings-net-pcs-add-bindings-for-MediaTek-USXGMI.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/739-05-net-pcs-add-driver-for-MediaTek-USXGMII-PCS.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/740-net-phy-motorcomm-Add-missing-include.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/741-net-phy-broadcom-update-dependency-condition.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/742-net-phy-realtek-add-5G-and-10G-PHY-support.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/743-net-phy-realtek-reset-RTL8261N-USXGMII-SerDes-on-lin.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/750-net-sfp-add-quirk-for-QINIYEK-BJ-SFP-10G-T-copper-SF.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/751-net-sfp-add-quirk-for-TP-LINK-SM410U.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-00-net-dsa-mxl862xx-wait-for-firmware-boot-time-configu.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-01-net-dsa-mxl862xx-add-SerDes-ethtool-statistics.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-02-dsa-add-devlink-flash_update-callback-to-dsa.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-03-dsa-mxl862xx-add-SMDIO-clause-22-register-ac.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-04-dsa-mxl862xx-add-devlink-flash_update-and-in.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-05-dsa-mxl862xx-recover-switch-stuck-in-MCUboot.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-06-net-dsa-tag_mxl862xx-leave-offload_fwd_mark-unset-on.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-07-net-dsa-mxl862xx-trap-link-local-and-multicast-snoop.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-08-net-dsa-mxl862xx-warn-about-old-firmware-default-PCE.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-09-net-dsa-add-802.1Q-VLAN-based-tag-driver-for-MxL862x.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-10-net-dsa-mxl862xx-add-link-aggregation-support.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-11-net-dsa-mxl862xx-add-support-for-mirror-port.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-12-net-dsa-mxl862xx-implement-port-MTU-configuration.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-13-net-dsa-mxl862xx-support-BR_HAIRPIN_MODE-bridge-flag.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-14-net-dsa-mxl862xx-support-BR_ISOLATED-bridge-flag.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-15-DO-NOT-SUBMIT-net-dsa-mxl862xx-re-introduce-PCE-work.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-16-DO-NOT-SUBMIT-net-dsa-mxl862xx-legacy-SFP-API-fallba.patch"
SRC_URI += "file://openwrt-generic-patches/pending-6.18/760-17-DO-NOT-SUBMIT-net-dsa-mxl862xx-increase-CMD-timeout.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/780-ARM-kirkwood-add-missing-linux-if_ether.h-for-ETH_AL.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/790-bus-mhi-core-add-SBL-state-callback.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/791-tg3-Fix-DMA-allocations-on-57766-devices.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-01-net-ethernet-mtk_ppe_offload-use-rhashtable_lookup_f.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-02-net-ethernet-mtk_ppe-set-tport_idx-on-netsys_v3-for-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-03-net-ethernet-mtk_ppe_offload-set-output-device-befor.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-04-net-ethernet-mtk_eth_soc-per-SoC-QDMA-TX-queue-count.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-05-net-ethernet-mtk_eth_soc-add-per-conduit-DSA-user-po.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-06-net-ethernet-mtk_eth_soc-use-DSA-queue-map-in-TX-pat.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-07-net-ethernet-mtk_ppe_offload-use-DSA-queue-map-in-fl.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-08-net-dsa-tag_mxl862xx_8021q-set-skb-queue_mapping-to-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/795-09-net-ethernet-mtk_ppe-offload-flows-to-MxL862xx-switc.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/796-dt-bindings-wireless-ath12k-drop-qcom-ath12k-cali.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/800-bcma-get-SoC-device-struct-copy-its-DMA-params-to-th.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/801-01-net-phy-add-PHY_DETACH_NO_HW_RESET-PHY-flag.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/801-02-net-phy-as21xxx-add-flag-PHY_DETACH_NO_HW_RESET.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/802-01-net-phy-as21xxx-handle-corner-case-with-link-and-aut.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/802-02-net-phy-as21xxx-fix-read_status-speed-handling.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/802-03-net-phy-as21xxx-force-C45-OPs-for-AUTONEG.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/802-OPP-Provide-old-opp-to-config_clks-on-_set_opp.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/804-net-phy-as21xxx-implement-read-workaround-for-C45-re.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/804-nvmem-core-support-mac-base-fixed-layout-cells.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/809-01-nvmem-core-generalize-mac-base-cells-handling.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/809-02-nvmem-layouts-add-support-for-ascii-env-driver.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/809-03-nvmem-layouts-ascii-env-handle-CRLF-while-parsing.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/810-pci_disable_common_quirks.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/811-pci_disable_usb_common_quirks.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/812-PCI-sysfs-enforce-single-creation-of-sysfs-entry-for.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/834-ledtrig-libata.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/840-hwrng-bcm2835-set-quality-to-1000.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/850-0023-PCI-aardvark-Make-main-irq_chip-structure-a-static-d.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/890-usb-serial-add-support-for-CH348.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/895-00-net-pse-pd-fix-out-of-bounds-bitmap-access-in-pse_isr-on-32-bit.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/895-00a-net-pse-pd-disable-IRQ-before-freeing-PI-data-in-unregister.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/895-00b-net-pse-pd-guard-against-freed-PI-data-on-regulator-disable.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/896-01-net-pse-pd-add-notifier-chain-for-controller-lifecyc.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/896-02-net-pse-pd-fire-lifecycle-events-on-controller-regis.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/896-03-net-phy-own-phydev-psec-via-PSE-notifier-and-remove-.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/897-00-dt-bindings-net-pse-pd-add-poll-interval-ms.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/897-01-net-pse-pd-add-devm_pse_poll_helper.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/897-02-net-pse-pd-add-LED-trigger-support.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/900-net-ag71xx-fix-qca9530-and-qca9550-mdio-probe.patch"
# SRC_URI += "file://openwrt-generic-patches/pending-6.18/920-mangle_bootargs.patch"


# ---------------------------------------------------------------------------
# Realtek RTL83xx patches
# ---------------------------------------------------------------------------

SRC_URI += " \
    file://patches-6.18/021-v6.19-gpio-regmap-Bypass-cache-for-shadowed-outputs.patch \
    file://patches-6.18/022-v7.0-mtd-nand-realtek-ecc-relax-OOB-size-check-to-minimum.patch \
    file://patches-6.18/023-01-v7.0-dt-bindings-gpio-realtek-otto-add-rtl9607-compatible.patch \
    file://patches-6.18/023-02-v7.0-gpio-realtek-otto-add-rtl9607-support.patch \
    file://patches-6.18/024-01-v7.1-dt-bindings-net-ethernet-phy-add-property-enet-phy-p.patch \
    file://patches-6.18/024-02-v7.1-net-phy-realtek-add-RTL8224-pair-order-support.patch \
    file://patches-6.18/024-03-v7.1-dt-bindings-net-ethernet-phy-add-property-enet-phy-p.patch \
    file://patches-6.18/024-04-v7.1-net-phy-realtek-add-RTL8224-polarity-support.patch \
    file://patches-6.18/025-01-v7.0-i2c-rtl9300-remove-const-cast.patch \
    file://patches-6.18/025-02-v7.0-i2c-rtl9300-use-of-instead-of-fwnode.patch \
    file://patches-6.18/026-v7.1-i2c-rtl9300-add-support-for-more-bus-speeds.patch \
    file://patches-6.18/027-01-v7.1-i2c-rtl9300-split-data_reg-into-read-and-write-reg.patch \
    file://patches-6.18/027-02-v7.1-i2c-rtl9300-introduce-max-length-property-to-driver-.patch \
    file://patches-6.18/027-03-v7.1-i2c-rtl9300-introduce-F_BUSY-to-the-reg_fields-struc.patch \
    file://patches-6.18/027-04-v7.1-i2c-rtl9300-introduce-a-property-for-8-bit-width-reg.patch \
    file://patches-6.18/027-05-v7.1-dt-bindings-i2c-realtek-rtl9301-i2c-extend-for-clock.patch \
    file://patches-6.18/027-06-v7.1-i2c-rtl9300-introduce-clk-struct-for-upcoming-rtl960.patch \
    file://patches-6.18/027-07-v7.1-i2c-rtl9300-introduce-new-function-properties-to-driv.patch \
    file://patches-6.18/027-08-v7.1-i2c-rtl9300-add-RTL9607C-i2c-controller-support.patch \
    file://patches-6.18/028-v7.1-hwmon-lm75-fix-configuration-register-writes.patch \
    file://patches-6.18/029-v7.2-hwmon-lm75-support-active-high-alert-polarity.patch \
    file://patches-6.18/030-v7.2-net-phy-realtek-support-MDI-swapping-for-RTL8226-CG.patch \
    file://patches-6.18/031-01-v7.2-net-mdio-realtek-rtl9300-enhance-documentation-namin.patch \
    file://patches-6.18/031-02-v7.2-net-mdio-realtek-rtl9300-Add-device-specific-info-st.patch \
    file://patches-6.18/031-03-v7.2-net-mdio-realtek-rtl9300-Add-ports-to-info-structure.patch \
    file://patches-6.18/031-04-v7.2-net-mdio-realtek-rtl9300-Add-pages-to-info-structure.patch \
    file://patches-6.18/031-05-v7.2-net-mdio-realtek-rtl9300-Add-register-structure.patch \
    file://patches-6.18/031-06-v7.2-net-mdio-realtek-rtl9300-Add-command-C22-register.patch \
    file://patches-6.18/031-07-v7.2-net-mdio-realtek-rtl9300-Add-I-O-register.patch \
    file://patches-6.18/031-08-v7.2-net-mdio-realtek-rtl9300-Add-port-mask-register.patch \
    file://patches-6.18/031-09-v7.2-net-mdio-realtek-rtl9300-Link-I-O-functions-in-info-.patch \
    file://patches-6.18/031-10-v7.2-net-mdio-realtek-rtl9300-provide-generic-command-run.patch \
    file://patches-6.18/031-11-v7.2-net-mdio-realtek-rtl9300-use-command-runner-for-writ.patch \
    file://patches-6.18/031-12-v7.2-net-mdio-realtek-rtl9300-use-command-runner-for-read.patch \
    file://patches-6.18/031-13-v7.2-net-mdio-realtek-rtl9300-use-command-runner-for-read.patch \
    file://patches-6.18/031-14-v7.2-net-mdio-realtek-rtl9300-Refactor-otto_emdio_map_por.patch \
    file://patches-6.18/031-15-v7.2-net-mdio-realtek-rtl9300-harden-otto_emdio_map_ports.patch \
    file://patches-6.18/031-16-v7.2-net-mdio-realtek-rtl9300-harden-otto_emdio_probe_one.patch \
    file://patches-6.18/031-17-v7.2-net-mdio-realtek-rtl9300-relocate-topology-setup.patch \
    file://patches-6.18/031-18-v7.2-net-mdio-realtek-rtl9300-relocate-c22-c45-device-tre.patch \
    file://patches-6.18/031-19-v7.2-net-mdio-realtek-rtl9300-reorder-controller-setup.patch \
    file://patches-6.18/031-20-v7.2-net-mdio-realtek-rtl9300-Correctly-handle-ethernet-p.patch \
    file://patches-6.18/031-21-v7.2-net-mdio-realtek-rtl9300-Add-prefix-to-register-fiel.patch \
    file://patches-6.18/031-22-v7.2-net-mdio-realtek-rtl9300-Make-otto_emdio_read_cmd-ge.patch \
    file://patches-6.18/031-23-v7.2-net-mdio-realtek-rtl9300-Add-registers-for-high-port.patch \
    file://patches-6.18/031-24-v7.2-net-mdio-realtek-rtl9300-Add-support-for-RTL931x.patch \
    file://patches-6.18/031-25-v7.4-net-mdio-realtek-rtl9300-Add-polling-doc.patch \
    file://patches-6.18/031-26-v7.4-net-mdio-realtek-rtl9300-deny-C45-over-C22-access.patch \
    file://patches-6.18/031-27-v7.4-net-mdio-realtek-rtl9300-suppress-sysfs-bind-unbind-attributes.patch \
    file://patches-6.18/031-28-v7.4-net-mdio-realtek-rtl9300-Configure-hardware-polling-during-probing.patch \
    file://patches-6.18/031-29-v7.4-net-mdio-realtek-rtl9300-Add-page-tracking.patch \
    file://patches-6.18/031-30-v7.4-net-mdio-realtek-rtl9300-Increase-MDIO-timeout.patch \
    file://patches-6.18/031-31-v7.4-net-mdio-realtek-rtl9300-Open-up-C22-and-C45-space-in-parallel.patch \
    file://patches-6.18/031-32-v7.4-net-mdio-realtek-rtl9300-Add-support-for-RTL838x.patch \
    file://patches-6.18/031-33-v7.4-net-mdio-realtek-rtl9300-Add-support-for-RTL839x.patch \
    file://patches-6.18/031-34-v7.4-net-mdio-realtek-rtl9300-reword-Kconfig-and-module-description.patch \
    file://patches-6.18/032-01-v7.2-irqchip-irq-realtek-rtl-Add-simplify-register-helper.patch \
    file://patches-6.18/032-02-v7.2-irqchip-irq-realtek-rtl-Add-multicore-support.patch \
    file://patches-6.18/032-03-v7.3-irqchip-irq-realtek-rtl-Use-helper-for-parent-setup.patch \
    file://patches-6.18/032-04-v7.3-irqchip-irq-realtek-rtl-Add-interrupt-data-structure.patch \
    file://patches-6.18/032-05-v7.3-irqchip-irq-realtek-rtl-Add-mask-for-interrupt-handl.patch \
    file://patches-6.18/032-06-v7.3-irqchip-irq-realtek-rtl-Add-a-select-function.patch \
    file://patches-6.18/032-07-v7.3-irqchip-irq-realtek-rtl-Allow-shuffled-interrupt-ord.patch \
    file://patches-6.18/032-08-v7.3-irqchip-irq-realtek-rtl-Activate-multiple-parents.patch \
    file://patches-6.18/033-01-v7.3-i2c-algo-bit-Allow-to-skip-bit-test.patch \
    file://patches-6.18/033-02-v7.3-i2c-gpio-Enhance-driver-for-buses-with-shared-SCL.patch \
    file://patches-6.18/034-01-v7.2-watchdog-realtek-otto-prevent-PHASE2-underflows.patch \
    file://patches-6.18/034-02-v7.2-watchdog-realtek-otto-enable-clock-before-using-IO.patch \
    file://patches-6.18/035-v7.3-watchdog-realtek-otto-change-to-use-regmap-API.patch \
    file://patches-6.18/036-v7.3-clocksource-rtl-otto-change-driver-to-use-__raw-reads-and-writes.patch \
    file://patches-6.18/037-v7.3-spi-realtek-rtl-change-to-__raw-reads-and-writes.patch \
    file://patches-6.18/038-v7.3-irqchip-irq-realtek-rtl-change-to-__raw-reads-and-writes.patch \
    file://patches-6.18/039-01-v7.4-gpio-realtek-otto-use-__raw_readl-writel-in-realtek_.patch \
    file://patches-6.18/039-02-v7.4-gpio-realtek-otto-make-bank_read-write-overridable-b.patch \
    file://patches-6.18/300-01-enhance-realtek-platform-config.patch \
    file://patches-6.18/300-02-enhance-realtek-board-setup.patch \
    file://patches-6.18/300-03-realtek-board-increase-fixup_fdt-buffer-to-32-KiB.patch \
    file://patches-6.18/308-tune-switch-4kec.patch \
    file://patches-6.18/309-mips-csum-partial-maddu.patch \
    file://patches-6.18/318-add-rtl83xx-clk-support.patch \
    file://patches-6.18/330-add-realtek-thernal-driver.patch \
    file://patches-6.18/331-add-realtek-otto-table-driver.patch \
    file://patches-6.18/700-dsa-mdio-increase-max-ports-for-rtl839x-rtl931x.patch \
    file://patches-6.18/705-v7.1-net-sfp-initialize-i2c_block_size-at-adapter-configu.patch \
    file://patches-6.18/706-01-v7.2-net-sfp-apply-I2C-adapter-quirks-to-limit-block-size.patch \
    file://patches-6.18/706-02-v7.2-net-sfp-extend-SMBus-support.patch \
    file://patches-6.18/712-net-phy-add-an-MDIO-SMBus-library.patch \
    file://patches-6.18/714-net-phy-sfp-add-support-for-SMBus.patch \
    file://patches-6.18/716-net-ethernet-add-support-for-rtl838x-ethernet.patch \
    file://patches-6.18/717-net-ethernet-add-rtl960x-gmac-probe-driver.patch \
    file://patches-6.18/718-net-dsa-add-support-for-rtl838x-switch.patch \
    file://patches-6.18/720-add-rtl-phy.patch \
    file://patches-6.18/721-net-dsa-add-support-for-tag-rtl-otto.patch \
    file://patches-6.18/723-net-mdio-Add-Realtek-Otto-auxiliary-controller.patch \
    file://patches-6.18/730-add-pcs-rtl-otto.patch \
    file://patches-6.18/743-net-realtek-serdes-configuration.patch \
    file://patches-6.18/802-mfd-Add-RTL8231-core-device.patch \
    file://patches-6.18/803-pinctrl-Add-RTL8231-pin-control-and-GPIO-support.patch \
    file://patches-6.18/804-leds-Add-support-for-RTL8231-LED-scan-matrix.patch \
    file://patches-6.18/806-add-mdio-driver.patch \
    file://patches-6.18/808-add-serdes-mdio-driver.patch \
    file://patches-6.18/809-add-hasivo-stc8-mfd.patch \
    file://patches-6.18/810-add-hasivo-mcu-wdt.patch \
    file://patches-6.18/813-add-hasivo-mcu-sensor.patch \
    file://patches-6.18/816-01-v7.3-net-pse-pd-add-Realtek-PSE-MCU-core.patch \
    file://patches-6.18/816-02-v7.3-net-pse-pd-realtek-pse-mcu-add-I2C-transport.patch \
    file://patches-6.18/816-03-v7.3-net-pse-pd-realtek-pse-mcu-add-UART-transport.patch \
    file://patches-6.18/817-net-pse-pd-realtek-pse-mcu-add-per-por-legacy-detec.patch \
    file://patches-6.18/818-net-pse-pd-add-hasivo-hs104-driver.patch \
    file://patches-6.18/819-net-pse-pd-realtek-pse-mcu-ensure-dynamic-power-mana.patch \
    file://patches-6.18/820-add-rtl960x-mdio-driver.patch \
    file://patches-6.18/821-add-realtek-pcie-phy-driver.patch \
    file://patches-6.18/822-add-realtek-pcie-controller-driver.patch \
"

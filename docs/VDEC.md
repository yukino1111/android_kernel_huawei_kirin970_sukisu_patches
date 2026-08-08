# Kirin 970 VDEC reset: diagnosis and fix

## Symptom

Starting Huawei OMX hardware decoding could instantly black-screen and reboot
the PAR-AL00. The final driver path was consistently `SCD_PROC`; the platform
blackbox recorded reboot reason `0x61` and a NoC access near `0xe8830000`.

## Instrumentation result

Temporary probes covered device open/release, channel create/destroy, IOMMU
map/unmap, `SCD_PROC`, `VDM_PROC`, clock changes and secure-mode requests. The
failure narrowed to:

```text
OMX.hisi.video.decoder.avc
  -> VDEC_IOCTL_SCD_PROC
  -> SMMU_ConfigSMR
  -> SMMU_SMRx_P protected register write
  -> non-secure NoC permission fault
  -> watchdog/blackbox reset
```

The diagnostic probes are not part of this repository's release patch series.

## Fix rationale

The VDEC firmware is shared with a secure-OS build, where `ENV_SOS_KERNEL` is
defined. The protected SMR bank belongs to that environment. In a normal Linux
build, `SMMU_InitGlobalReg()` already initializes the non-secure bank through
`SMMU_SMRx_NS`; writing `SMMU_SMRx_P` is both unnecessary and unsafe.

The patch therefore retains the original loop only for `ENV_SOS_KERNEL` and
leaves `SMMU_ConfigSMR()` empty in the normal-world build.

## Validation

- clean release build contained no `VDECDBG` strings;
- normal-world `SMMU_ConfigSMR()` disassembled to a return-only function;
- repeated AVC playback selected `OMX.hisi.video.decoder.avc`;
- SCD and VDM processing continued without reset;
- the device owner confirmed the clean release kernel remained stable.

Userspace must not carry the earlier `OMX.hisi.video.decoder.*` blacklist when
this fixed kernel is used, otherwise playback silently falls back to software.

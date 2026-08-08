# SukiSU, SuSFS and VDEC fixes for Huawei Kirin 970

This repository reproduces the Android 13 kernel used on Huawei nova 3
(`PAR`, Kirin 970) from the pinned LineageOS 4.9 base. It contains the SukiSU
Ultra/SuSFS 2 integration and the normal-world VDEC SMMU safety fix.

## VDEC fix

Huawei's VDEC firmware called `SMMU_ConfigSMR()` from the normal Linux kernel
and wrote the protected `SMMU_SMRx_P` register bank. On Kirin 970 this causes a
NoC permission fault during `SCD_PROC`, followed by a watchdog/blackbox reset.

`0002-kirin970-vdec-keep-protected-smr-in-secure-world.patch` keeps those writes
only for `ENV_SOS_KERNEL`. Normal Linux already configures its stream mappings
through `SMMU_SMRx_NS` in `SMMU_InitGlobalReg()`, so the non-secure path becomes
a deliberate no-op. This restores Huawei OMX hardware decoding without a
userspace codec blacklist.

The clean kernel was built without diagnostic `VDECDBG` probes and validated
on PAR-AL00 with repeated AVC playback over the stock Huawei OMX decoder.
The verified artifact name and SHA-256 are recorded in
[`docs/RELEASE_20260808.md`](docs/RELEASE_20260808.md).

## Reproduce

Use clean checkouts at the commits recorded in `SOURCE_STATE`:

```bash
scripts/apply.sh /path/to/kernel-4.9-lineage /path/to/SukiSU-Ultra

ANDROID_BUILD_ROOT="$HOME/android-builds" \
TOOLCHAIN_DIR=/path/to/aarch64-linux-android-4.9 \
scripts/build.sh /path/to/kernel-4.9-lineage
```

`scripts/apply.sh` verifies both pinned revisions, patches a disposable SukiSU
tree, copies its kernel integration into `drivers/kernelsu`, and applies the
kernel series. It never creates commits.

## Scope and safety

- Target: Huawei nova 3 / PAR, Kirin 970, Android 13.
- SukiSU Ultra and SuSFS are pinned by commit and patch hashes.
- KPM is intentionally excluded from the release configuration.
- The VDEC change does not alter ioctl ABI, clocks, IOMMU mappings or secure
  decoding policy; it only prevents normal-world access to a protected bank.

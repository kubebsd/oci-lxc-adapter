# oci-lxc-adapter

> Convert OCI container images into LXC-compatible rootfs bundles.  
> Written in [Zig](https://ziglang.org/). Fully CLI-based, dependency-light, OCI-native.

---

## 🔧 Features

- Pulls OCI-compliant images (Docker, Harbor, etc.)
- Extracts & prepares rootfs for LXC runtime
- Fast, portable, minimal
- Optional caching layer
- Shells out to `skopeo`, `umoci`, `tar`, or uses native Zig methods

---

## ⚙️ Architecture (C4 Model Summary)

### System Context (Level 1)
- CLI tool used by DevOps engineers
- Interfaces with:
  - OCI registries
  - Local filesystem
  - LXC runtime

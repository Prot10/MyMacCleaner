# MyMacCleaner Roadmap

## Completed Features

All critical and most medium-priority features from the competitive analysis have been implemented:

| Feature | Status | Notes |
|---------|--------|-------|
| Orphaned Files Scanner | ✅ Done | Scans for leftovers from deleted apps |
| Duplicate File Finder | ✅ Done | Hash-based detection with cancellation support |
| Menu Bar Monitor | ✅ Done | Real-time CPU/RAM/Disk with 4 display modes |
| Browser Privacy Cleaner | ✅ Done | Safari, Chrome, Firefox, Edge, Brave, Arc, Opera |
| Large & Old Files Filter | ✅ Done | Size filters (>100MB, >500MB, >1GB) and age filters (>30d, >90d, >1y) in Space Lens |
| Startup Items Manager | ✅ Done | Login items via BTM framework |
| Homebrew Integration | ✅ Done | List, upgrade, uninstall casks |
| Sparkle Auto-Updates | ✅ Done | EdDSA-signed updates |
| Liquid Glass UI | ✅ Done | Native macOS 26 design with fallback |
| Localization | ✅ Done | EN/IT/ES with runtime switching |

---

## Planned Features

### High Priority

#### Scheduled/Automatic Cleaning
Background agent for automated maintenance.

**Scope:**
- Background agent running periodic scans (weekly/monthly)
- Notification when cleanable space exceeds threshold
- Optional auto-clean for safe categories (caches, logs)
- Respect system sleep/low power mode

**Considerations:**
- Requires Login Item or LaunchAgent
- User opt-in only
- Must not impact system performance

---

### Medium Priority

#### File Shredder (Secure Delete)
Secure deletion with multiple overwrites for sensitive files.

**Scope:**
- Single-pass zero fill (fast)
- DoD 5220.22-M standard (3 passes)
- Gutmann method (35 passes, optional)
- Integration with existing delete confirmations

**Considerations:**
- SSD wear concerns (inform user)
- APFS copy-on-write limitations
- May require elevated permissions

#### Architecture Stripping (Lipo)
Remove unused CPU architectures from universal binaries to save space.

**Scope:**
- Detect universal binaries with unused architectures
- Strip x86_64 from Apple Silicon Macs (or vice versa)
- Show potential space savings before action
- Backup original before modification

**Considerations:**
- Risk of breaking apps (Rosetta compatibility)
- Code signature invalidation
- Should be opt-in with clear warnings

---

### Low Priority / Under Consideration

#### Temperature Monitoring
Display CPU/GPU temperatures in menu bar.

**Considerations:**
- Requires SMC access (IOKit)
- Different sensors per Mac model
- Stats app already does this well

#### Network Speed Monitor
Real-time upload/download speed in menu bar.

**Considerations:**
- Already partially available in menu bar
- Could expand with per-app bandwidth usage

---

## Not Planned

| Feature | Reason |
|---------|--------|
| Malware Scanner | XProtect handles this; would add bloat without real value |
| VPN/Privacy Tools | Out of scope; many dedicated apps exist |
| Cloud Storage Cleanup | Too many providers; complex OAuth requirements |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Feature requests and pull requests are welcome.

When proposing new features, please consider:
1. Does it fit the app's focus on system optimization?
2. Can it be implemented without compromising user privacy?
3. Does it require elevated permissions? If so, is it justified?

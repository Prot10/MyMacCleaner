# Code Review Guidelines

> Comprehensive checklist for reviewing code before merging to main

## Overview

This document outlines the code review process for MyMacCleaner. All code must pass automated checks, meet quality standards, and receive a satisfactory score across key categories before merging to `main`.

### Stack Overview

| Attribute | Value |
|-----------|-------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Target | macOS 14.0+ (Sonoma) |
| Design | Liquid Glass (native on macOS 26+, material fallback on 14-15) |
| Architecture | MVVM with Swift actors for services |
| Testing | Swift Testing framework |
| Dependencies | Sparkle 2.x (auto-updates) |

---

## Pre-Merge Automated Checks

### CI Pipeline Requirements

**All of the following MUST pass before code review begins:**

```bash
# 1. Build Verification
xcodebuild -project MyMacCleaner.xcodeproj -scheme MyMacCleaner build

# 2. Run Tests
xcodebuild test -project MyMacCleaner.xcodeproj -scheme MyMacCleaner

# 3. Check for compiler warnings (should be zero)
xcodebuild -project MyMacCleaner.xcodeproj -scheme MyMacCleaner build 2>&1 | grep -i "warning:"
```

### Additional Automated Checks

- **No compiler warnings** introduced
- **No force unwraps** (`!`) without justification
- **No `print()` or `debugPrint()` statements** left in production code
- **All tests pass**
- **Build completes without errors**

### Breaking Changes Check

Run the following to ensure existing features still work:

```bash
# Full clean build
xcodebuild clean build -project MyMacCleaner.xcodeproj -scheme MyMacCleaner

# Run all tests
xcodebuild test -project MyMacCleaner.xcodeproj -scheme MyMacCleaner
```

**If any tests fail or builds break**: The branch CANNOT be merged. Fix issues first.

---

## Code Review Categories & Scoring

### Scoring System

Each category is scored from **1 to 5 stars**:

| Score | Meaning |
|-------|---------|
| ⭐ | Major issues, needs significant work |
| ⭐⭐ | Multiple issues, substantial improvements needed |
| ⭐⭐⭐ | Acceptable but has room for improvement |
| ⭐⭐⭐⭐ | Good quality, minor improvements suggested |
| ⭐⭐⭐⭐⭐ | Excellent, meets all standards |

**Minimum requirement to merge**: All categories must score **4+ stars**.

---

### Category 1: Architecture & MVVM Patterns

#### File Organization

Files must be in correct locations:

| Type | Location |
|------|----------|
| App entry point | `App/` |
| ViewModels | `Features/[Feature]/` |
| Views | `Features/[Feature]/` |
| Services (actors) | `Core/Services/` |
| Models | `Core/Models/` |
| Design system | `Core/Design/` |
| Extensions | `Core/Extensions/` |

#### ViewModel Pattern

ViewModels must follow this pattern:

```swift
@MainActor
class FeatureViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var items: [Item] = []
    @Published var errorMessage: String?

    // MARK: - Toast Properties
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .info

    // MARK: - Private Properties
    private let service = SomeService.shared

    // MARK: - Initialization
    init() {
        Task {
            await loadData()
        }
    }

    // MARK: - Public Methods
    func performAction() {
        Task {
            // Async work
        }
    }

    // MARK: - Private Methods
    private func loadData() async {
        // Implementation
    }
}
```

**Checklist:**
- [ ] ViewModel is `@MainActor`
- [ ] ViewModel conforms to `ObservableObject`
- [ ] Published properties for view binding
- [ ] Services accessed as singletons (`.shared`)
- [ ] Heavy work in `Task {}` blocks, not init
- [ ] MARK comments for sections
- [ ] No direct view manipulation

#### Service/Actor Pattern

Services must be Swift actors:

```swift
actor MyService {
    static let shared = MyService()

    private init() { }

    func performWork() async throws -> Result {
        // Thread-safe implementation
    }
}
```

**Checklist:**
- [ ] Actor for thread safety
- [ ] Singleton via `static let shared`
- [ ] Private init
- [ ] All public methods are `async`
- [ ] Proper error handling with custom error types

#### View Architecture

```swift
struct FeatureView: View {
    @ObservedObject var viewModel: FeatureViewModel
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    contentSection
                }
            }

            // Overlays
            if viewModel.showModal {
                ModalView(...)
            }

            // Toast
            if viewModel.showToast {
                ToastView(...)
            }
        }
    }

    // MARK: - View Sections
    private var headerSection: some View { ... }
    private var contentSection: some View { ... }
}
```

**Checklist:**
- [ ] `@ObservedObject` for ViewModel (not `@StateObject`)
- [ ] `@State` for local view state
- [ ] ZStack for overlays (modals, toasts)
- [ ] Extracted computed properties for sections
- [ ] Proper spacing using Theme.Spacing

**Scoring Criteria:**
- **5 stars**: Perfect MVVM, all patterns followed
- **4 stars**: Minor deviations (1-2 issues)
- **3 stars**: Some pattern violations (3-5 issues)
- **2 stars**: Poor architecture, needs refactoring
- **1 star**: Does not follow MVVM at all

---

### Category 2: Concurrency & Thread Safety

#### Async/Await Usage

```swift
// ✅ GOOD: Proper async pattern
func startScan() {
    guard !isScanning else { return }
    isScanning = true

    Task {
        do {
            let results = try await scanner.scan { [weak self] progress in
                self?.scanProgress = progress
            }
            scanResults = results
        } catch {
            errorMessage = error.localizedDescription
        }
        isScanning = false
    }
}

// ❌ BAD: Blocking main thread
func startScan() {
    let results = scanner.scanSync() // NEVER do this
}
```

#### Progress Callbacks

```swift
// ✅ GOOD: Weak self in closures
try await service.performWork { [weak self] progress, status in
    self?.progress = progress
    self?.status = status
}

// ❌ BAD: Strong reference cycle
try await service.performWork { progress, status in
    self.progress = progress // Potential retain cycle
}
```

#### Cancellation Support

Long-running operations must support cancellation:

```swift
actor Scanner {
    private var isCancelled = false

    func cancel() {
        isCancelled = true
    }

    func scan() async throws -> [Result] {
        for item in items {
            if isCancelled {
                throw ScannerError.cancelled
            }
            // Process item
        }
    }
}
```

**Checklist:**
- [ ] All I/O operations use `async/await`
- [ ] ViewModels execute async in `Task {}`
- [ ] `[weak self]` in all closures
- [ ] Long operations support cancellation
- [ ] No `DispatchQueue` unless absolutely necessary
- [ ] `Task.sleep(nanoseconds:)` instead of `Thread.sleep`

**Scoring Criteria:**
- **5 stars**: Perfect concurrency patterns
- **4 stars**: Minor issues (1-2 missing weak self)
- **3 stars**: Some blocking code or missing cancellation
- **2 stars**: Multiple concurrency issues
- **1 star**: Blocking main thread or data races

---

### Category 3: Theme & Design System

#### macOS 26 First Design Philosophy

**CRITICAL: Always use macOS 26 (Tahoe) patterns as the PRIMARY implementation, with fallbacks for older versions.**

This project follows Apple's Liquid Glass design language. All new UI code must:

1. **Use macOS 26 APIs first** (native `.glassEffect()`, new SwiftUI features)
2. **Add fallbacks** for macOS 14-15 using `.ultraThinMaterial` or equivalent
3. **Never skip the new APIs** - don't write fallback-only code

```swift
// ✅ CORRECT: macOS 26 first, then fallback
@ViewBuilder
func glassCard() -> some View {
    if #available(macOS 26, *) {
        // PRIMARY: Use native Liquid Glass
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    } else {
        // FALLBACK: Material for older macOS
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// ❌ WRONG: Fallback only (misses macOS 26 improvements)
func glassCard() -> some View {
    self
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}

// ❌ WRONG: macOS 26 only (crashes on older versions)
func glassCard() -> some View {
    self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
}
```

#### Color Usage

**NO hardcoded colors.** All colors must use the Theme system:

```swift
// ✅ GOOD: Theme colors
Text("Title")
    .foregroundStyle(Theme.Colors.textPrimary)

// ❌ BAD: Hardcoded colors
Text("Title")
    .foregroundStyle(.blue)
    .foregroundColor(Color(hex: "#007AFF"))
```

#### Typography

```swift
// ✅ GOOD: Theme typography
Text("Header")
    .font(Theme.Typography.title)

// ❌ BAD: Hardcoded fonts
Text("Header")
    .font(.system(size: 24, weight: .bold))
```

#### Spacing & Layout

```swift
// ✅ GOOD: Theme spacing
VStack(spacing: Theme.Spacing.md) {
    // Content
}
.padding(Theme.Spacing.lg)

// ❌ BAD: Magic numbers
VStack(spacing: 16) {
    // Content
}
.padding(24)
```

#### Corner Radius

```swift
// ✅ GOOD: Theme corner radius
.clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))

// ❌ BAD: Magic numbers
.clipShape(RoundedRectangle(cornerRadius: 16))
```

#### Liquid Glass Components

Use the glass modifiers from LiquidGlass.swift. These modifiers already implement the "macOS 26 first" pattern internally:

```swift
// ✅ GOOD: Glass modifiers (already handle version fallbacks)
VStack { }
    .glassCard()           // Standard card
    .glassCardProminent()  // Highlighted card
    .glassCardSubtle()     // Subtle card
    .glassSearchField()    // Search field style
    .glassActionButton()   // Button style
    .glassPill()           // Pill/tag style

// ✅ GOOD: Interactive effects
Button { }
    .hoverEffect()         // Hover state
    .pressEffect()         // Press state
    .floatingEffect()      // Floating animation
```

#### Creating New Glass Effects

When creating NEW glass effects not covered by existing modifiers, ALWAYS follow the pattern:

```swift
// ✅ CORRECT: New glass modifier with proper fallback
@ViewBuilder
func glassCustomEffect() -> some View {
    if #available(macOS 26, *) {
        self
            .glassEffect(.prominent, in: Capsule())
            .shadow(color: .black.opacity(0.1), radius: 8)
    } else {
        self
            .background(.thickMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 8)
    }
}
```

**Checklist:**
- [ ] All colors from `Theme.Colors`
- [ ] All fonts from `Theme.Typography`
- [ ] All spacing from `Theme.Spacing`
- [ ] All corner radii from `Theme.CornerRadius`
- [ ] Glass modifiers for card-like components
- [ ] No magic numbers for visual properties
- [ ] **New glass effects use macOS 26 first, then fallback**
- [ ] **Existing glass modifiers preferred over custom implementations**

**Scoring Criteria:**
- **5 stars**: Perfect theme usage
- **4 stars**: 1-2 hardcoded values
- **3 stars**: 3-5 hardcoded values
- **2 stars**: Multiple hardcoded values
- **1 star**: No theme usage

---

### Category 4: Localization (i18n)

#### Text Externalization

**NO hardcoded user-facing strings.** Use the `L()` function:

```swift
// ✅ GOOD: Localized strings
Text(L("home.title"))
Text(L("diskCleaner.scanning"))

// ✅ GOOD: Formatted strings
Text(LFormat("diskCleaner.itemsFound %lld", count))
Text(LFormat("performance.memoryUsage %.1f", percentage))

// ❌ BAD: Hardcoded strings
Text("Home")
Text("Scanning...")
Text("\(count) items found")
```

#### Localization Key Hierarchy

Keys must follow the pattern: `section.subsection.element`

| Pattern | Example |
|---------|---------|
| Feature title | `home.title`, `diskCleaner.title` |
| Actions | `home.startScan`, `diskCleaner.clean` |
| Status | `home.scanning`, `performance.loading` |
| Labels | `settings.language.label` |
| Errors | `errors.scanFailed`, `errors.permissionDenied` |

#### All Languages Required

New strings must be added to all locales in `Localizable.xcstrings`:
- English (en)
- Italian (it)
- Spanish (es)

**Checklist:**
- [ ] All user-facing text uses `L()` or `LFormat()`
- [ ] Keys follow hierarchy pattern
- [ ] Translations in all 3 languages
- [ ] No string interpolation with hardcoded text
- [ ] Format strings use proper placeholders (`%lld`, `%@`, `%.1f`)

**Scoring Criteria:**
- **5 stars**: All text externalized, all translations present
- **4 stars**: 1-2 hardcoded strings or missing translations
- **3 stars**: 3-5 hardcoded strings
- **2 stars**: Multiple hardcoded strings (6-10)
- **1 star**: No localization

---

### Category 5: Error Handling

#### Custom Error Types

Each service should define its own error type:

```swift
enum FileScannerError: LocalizedError {
    case pathNotAllowed(URL)
    case deletionFailed(URL, Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .pathNotAllowed(let url):
            return L("errors.pathNotAllowed") + ": \(url.path)"
        case .deletionFailed(let url, let error):
            return L("errors.deletionFailed") + ": \(error.localizedDescription)"
        case .cancelled:
            return L("errors.cancelled")
        }
    }
}
```

#### Error Propagation

```swift
// ✅ GOOD: Proper error handling
func performAction() async {
    do {
        let result = try await service.work()
        handleSuccess(result)
    } catch {
        showToastMessage(error.localizedDescription, type: .error)
    }
}

// ❌ BAD: Swallowing errors
func performAction() async {
    try? await service.work() // Error ignored!
}

// ❌ BAD: Force try
func performAction() async {
    let result = try! await service.work() // Will crash!
}
```

#### Toast Notifications

Use the standard toast pattern for user feedback:

```swift
func showToastMessage(_ message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true

    Task {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        showToast = false
    }
}
```

**Checklist:**
- [ ] Custom error types per service
- [ ] `LocalizedError` conformance
- [ ] No force try (`try!`)
- [ ] No silent error swallowing (`try?` without handling)
- [ ] User-friendly error messages via toast
- [ ] Errors propagate, don't crash

**Scoring Criteria:**
- **5 stars**: Comprehensive error handling
- **4 stars**: Minor gaps (1-2 unhandled cases)
- **3 stars**: Some missing error handling
- **2 stars**: Multiple unhandled errors
- **1 star**: Force unwraps, crashes, no error handling

---

### Category 6: Security & Permissions

#### Path Validation

**CRITICAL: All file operations must validate paths.**

```swift
// ✅ GOOD: Path validation before deletion
func deleteFile(at url: URL) throws {
    guard isPathAllowedForDeletion(url) else {
        throw FileScannerError.pathNotAllowed(url)
    }
    try FileManager.default.removeItem(at: url)
}

// ❌ BAD: No validation
func deleteFile(at url: URL) throws {
    try FileManager.default.removeItem(at: url) // DANGEROUS!
}
```

#### Forbidden Paths

These paths must NEVER be deleted:

```swift
private let forbiddenPaths = [
    "/System",
    "/Library",
    "/Applications",
    "/usr",
    "/bin",
    "/sbin",
    "/private",
    "/var",
    NSHomeDirectory(), // User's home directory root
]
```

#### Allowed Deletion Paths

Only these paths should be allowed for cleanup:

```swift
private let allowedDeletionPaths = [
    "\(home)/Library/Caches",
    "\(home)/Library/Logs",
    "\(home)/Library/Application Support/Code/Cache",
    "\(home)/Library/Developer/Xcode/DerivedData",
    // ... other safe paths
]
```

#### Admin Privileges

```swift
// ✅ GOOD: Single password prompt for batch operations
func performMaintenanceTasks(_ tasks: [MaintenanceTask]) async throws {
    let script = tasks.map { $0.command }.joined(separator: " && ")
    try await AuthorizationService.shared.runWithAdminPrivileges(script)
}

// ❌ BAD: Multiple password prompts
for task in tasks {
    try await runWithAdminPrivileges(task.command) // Prompts each time!
}
```

#### Permission Checks

Check permissions before accessing protected resources:

```swift
// Check Full Disk Access before scanning protected directories
guard PermissionsService.shared.hasFullDiskAccess else {
    showPermissionPrompt = true
    return
}
```

**Checklist:**
- [ ] All file deletions validate paths
- [ ] Forbidden system paths blocked
- [ ] Only whitelisted paths allowed for deletion
- [ ] Single password prompt for batch admin operations
- [ ] Permission checks before accessing TCC-protected directories
- [ ] No hardcoded credentials or secrets
- [ ] Sensitive data not logged

**Scoring Criteria:**
- **5 stars**: Excellent security practices
- **4 stars**: Minor security concerns (1-2)
- **3 stars**: Some validation missing
- **2 stars**: Multiple security issues
- **1 star**: Critical security vulnerabilities

---

### Category 7: Animations & UX

#### Animation Standards

Use Theme animation presets:

```swift
// ✅ GOOD: Theme animations
withAnimation(Theme.Animation.springSmooth) {
    isVisible = true
}

// ✅ GOOD: Staggered animations
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemView(item: item)
        .staggeredAnimation(index: index, isActive: isVisible)
}

// ❌ BAD: Hardcoded animation values
withAnimation(.easeInOut(duration: 0.3)) {
    // ...
}
```

#### Available Animations

| Animation | Usage |
|-----------|-------|
| `Theme.Animation.fast` | Quick UI feedback |
| `Theme.Animation.normal` | Standard transitions |
| `Theme.Animation.slow` | Dramatic effects |
| `Theme.Animation.spring` | Bouncy interactions |
| `Theme.Animation.springBouncy` | Playful elements |
| `Theme.Animation.springSmooth` | Page transitions |

#### View Animations

```swift
struct FeatureView: View {
    @State private var isVisible = false

    var body: some View {
        VStack {
            // Content with staggered animation
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }
}
```

**Checklist:**
- [ ] Use Theme.Animation presets
- [ ] Staggered animations for lists
- [ ] Smooth page transitions
- [ ] Loading states for async operations
- [ ] No jarring or instant state changes
- [ ] Progress indicators for long operations

**Scoring Criteria:**
- **5 stars**: Polished animations, excellent UX
- **4 stars**: Minor animation issues
- **3 stars**: Some missing animations
- **2 stars**: Poor UX, jarring transitions
- **1 star**: No animations, confusing UX

---

### Category 8: Testing

#### Test File Organization

Tests should be in the `MyMacCleanerTests` target:

```swift
// MyMacCleanerTests/FeatureTests.swift
import Testing
@testable import MyMacCleaner

@Suite("Feature Tests")
struct FeatureTests {
    @Test("Test description")
    func testSomething() async throws {
        // Arrange
        let input = ...

        // Act
        let result = ...

        // Assert
        #expect(result == expected)
    }
}
```

#### Test Coverage Areas

| Area | What to Test |
|------|-------------|
| Models | Computed properties, initialization, formatting |
| ViewModels | State changes, async operations (mocked) |
| Services | Business logic, error cases |
| Validation | Path validation, input sanitization |
| Theme | Constants exist and are valid |

#### Test Patterns

```swift
// ✅ GOOD: Descriptive test names
@Test("Scan results calculate total size correctly")
func scanResultsTotalSize() { }

// ✅ GOOD: Test edge cases
@Test("Empty scan results return zero size")
func emptyResults() { }

// ✅ GOOD: Test error cases
@Test("Path validation rejects system directories")
func pathValidationRejectsSystem() { }
```

**Checklist:**
- [ ] Tests use Swift Testing framework (`@Suite`, `@Test`, `#expect`)
- [ ] All new models have tests
- [ ] All new services have tests
- [ ] Edge cases tested (empty, nil, large values)
- [ ] Error cases tested
- [ ] All tests pass

**Scoring Criteria:**
- **5 stars**: Comprehensive test coverage
- **4 stars**: Good coverage, minor gaps
- **3 stars**: Basic coverage
- **2 stars**: Minimal tests
- **1 star**: No tests or failing tests

---

### Category 9: Code Quality & Style

#### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Types | PascalCase | `ScanResult`, `HomeViewModel` |
| Variables | camelCase | `scanProgress`, `isScanning` |
| Booleans | `is/has/should/can` prefix | `isLoading`, `hasPermission` |
| Functions | verb prefix | `startScan()`, `loadData()` |
| Constants | camelCase | `maxRetries`, `defaultTimeout` |
| Enums | PascalCase | `ScanCategory`, `ToastType` |
| Enum cases | camelCase | `.diskCleaner`, `.userCaches` |

#### File Structure

```swift
import SwiftUI

// MARK: - Main Type
struct FeatureView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: FeatureViewModel
    @State private var isVisible = false

    // MARK: - Body
    var body: some View {
        // ...
    }

    // MARK: - View Sections
    private var headerSection: some View { }

    // MARK: - Private Methods
    private func handleAction() { }
}

// MARK: - Preview
#Preview {
    FeatureView(viewModel: FeatureViewModel())
}
```

#### Code Style

```swift
// ✅ GOOD: Clear, readable code
func calculateTotalSize() -> Int64 {
    items
        .filter { $0.isSelected }
        .reduce(0) { $0 + $1.size }
}

// ❌ BAD: Overly compact
func calculateTotalSize() -> Int64 { items.filter{$0.isSelected}.reduce(0){$0+$1.size} }
```

#### Documentation

```swift
// ✅ GOOD: Document complex logic
/// Calculates the health score based on disk usage, memory pressure, and battery health.
/// - Returns: A score from 0-100 where 100 is optimal
func calculateHealthScore() -> Int {
    // Implementation
}

// ✅ GOOD: Document non-obvious behavior
// TCC database access requires Full Disk Access permission
// This is the most reliable method to detect FDA status
```

**Checklist:**
- [ ] Follows naming conventions
- [ ] MARK comments for sections
- [ ] No unused imports
- [ ] No commented-out code
- [ ] No `print()` statements in production
- [ ] Complex logic documented
- [ ] No code duplication

**Scoring Criteria:**
- **5 stars**: Clean, well-organized code
- **4 stars**: Minor style issues
- **3 stars**: Some disorganization
- **2 stars**: Multiple style violations
- **1 star**: Messy, hard to read code

---

### Category 10: Data Models

#### Model Structure

```swift
struct CleanableItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let dateModified: Date
    var isSelected: Bool

    // MARK: - Computed Properties
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateModified, relativeTo: Date())
    }
}
```

#### Formatting

Use system formatters:

```swift
// ✅ GOOD: ByteCountFormatter for file sizes
ByteCountFormatter.string(fromByteCount: size, countStyle: .file)

// ✅ GOOD: RelativeDateTimeFormatter for dates
let formatter = RelativeDateTimeFormatter()
formatter.localizedString(for: date, relativeTo: Date())

// ❌ BAD: Manual formatting
"\(size / 1024 / 1024) MB"
```

**Checklist:**
- [ ] Models conform to `Identifiable`
- [ ] Use UUID for id
- [ ] Computed properties for derived data
- [ ] Use system formatters (ByteCountFormatter, DateFormatter)
- [ ] Clear property names
- [ ] Immutable where possible (`let` vs `var`)

**Scoring Criteria:**
- **5 stars**: Well-designed models
- **4 stars**: Minor model issues
- **3 stars**: Some modeling problems
- **2 stars**: Poor data design
- **1 star**: No proper models

---

### Category 11: Dead Code & Maintenance

#### Prohibited Patterns

| Pattern | Why It's Bad | What To Do |
|---------|--------------|------------|
| `_ = value` (unused) | Hides dead code | Delete the code |
| `// TODO: remove` | Code archaeology | Delete now |
| `#if false ... #endif` | Dead code block | Delete it |
| `@available(*, deprecated)` | Without migration | Remove or migrate |
| Commented-out code | Code hoarding | Delete (use git) |
| Unused private methods | Dead weight | Delete them |

#### Detection

```bash
# Find TODO/FIXME comments
grep -rn "TODO\|FIXME\|HACK\|XXX" MyMacCleaner/

# Find print statements
grep -rn "print(" MyMacCleaner/ --include="*.swift"

# Find force unwraps
grep -rn "!" MyMacCleaner/ --include="*.swift" | grep -v "//"
```

#### File Size Guidelines

| File Type | Suggested Max | Action if Exceeded |
|-----------|--------------|-------------------|
| View | ~500 lines | Extract sections to separate views |
| ViewModel | ~400 lines | Extract logic to services |
| Service | ~600 lines | Split into focused services |
| Model | ~200 lines | Evaluate complexity |

**Checklist:**
- [ ] No commented-out code
- [ ] No unused variables/methods
- [ ] No print statements
- [ ] No TODO comments for completed work
- [ ] Files within size guidelines
- [ ] No deprecated code without migration

**Scoring Criteria:**
- **5 stars**: Zero dead code
- **4 stars**: 1-2 minor instances
- **3 stars**: 3-5 dead code instances
- **2 stars**: Multiple dead code issues
- **1 star**: Significant dead code

---

### Category 12: macOS Compatibility & Modern API Adoption

#### Core Principle: macOS 26 First

**ALWAYS use the latest macOS 26 APIs as your PRIMARY implementation.**

This is a forward-looking project. We want to:
- Take full advantage of Apple's latest features (Liquid Glass, new SwiftUI APIs)
- Provide the best possible experience on macOS 26+
- Maintain compatibility with macOS 14-15 via fallbacks

**The pattern is always:**
```
if #available(macOS 26, *) {
    // PRIMARY: Latest and greatest
} else {
    // FALLBACK: Graceful degradation for older versions
}
```

#### Liquid Glass Implementation

```swift
// ✅ CORRECT: macOS 26 glass effects with fallback
@ViewBuilder
func glassCard() -> some View {
    if #available(macOS 26, *) {
        // Use native Liquid Glass API
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    } else {
        // Fallback to materials
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// ❌ WRONG: Only fallback (misses Liquid Glass on macOS 26)
func glassCard() -> some View {
    self.background(.ultraThinMaterial)
}

// ❌ WRONG: No fallback (crashes on macOS 14-15)
func glassCard() -> some View {
    self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
}

// ❌ WRONG: Fallback first (wrong priority order)
func glassCard() -> some View {
    if #unavailable(macOS 26) {
        self.background(.ultraThinMaterial)
    } else {
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}
```

#### Glass Effect Types (macOS 26)

Use the appropriate glass effect for each context:

| Effect | Usage |
|--------|-------|
| `.glassEffect(.regular, ...)` | Standard cards, containers |
| `.glassEffect(.prominent, ...)` | Highlighted/active elements |
| `.glassEffect(.subtle, ...)` | Background elements, subtle emphasis |

#### Material Fallbacks (macOS 14-15)

Map glass effects to appropriate materials:

| macOS 26 Glass | macOS 14-15 Material |
|----------------|----------------------|
| `.regular` | `.ultraThinMaterial` |
| `.prominent` | `.regularMaterial` or `.thickMaterial` |
| `.subtle` | `.ultraThinMaterial` with lower opacity |

#### New SwiftUI APIs

Also check availability for other new SwiftUI features:

```swift
// ✅ CORRECT: New SwiftUI API with fallback
var body: some View {
    if #available(macOS 26, *) {
        // Use new API
        content
            .someNewModifier()
    } else {
        // Fallback implementation
        content
            .existingWorkaround()
    }
}
```

#### System Features

Check availability for macOS-specific features:

```swift
// ServiceManagement (BTM) - requires macOS 13+
if #available(macOS 13, *) {
    // Use SMAppService
}

// New window APIs
if #available(macOS 26, *) {
    // Use new window management
}
```

#### What to Check in Code Review

1. **Every new glass effect** must have `#available(macOS 26, *)` check
2. **macOS 26 branch must come first** (not the else branch)
3. **Fallback must provide equivalent functionality** (not just empty)
4. **No compilation warnings** about availability
5. **Test on both old and new macOS** if possible

**Checklist:**
- [ ] `#available(macOS 26, *)` for ALL Liquid Glass effects
- [ ] macOS 26 is the PRIMARY branch (not else)
- [ ] Material fallbacks provide equivalent visual hierarchy
- [ ] No `#unavailable` patterns (use `#available` with else)
- [ ] Test on macOS 14/15 (fallback works)
- [ ] Test on macOS 26 (Liquid Glass works)
- [ ] No crashes on any supported version
- [ ] New SwiftUI APIs also have fallbacks where needed

**Scoring Criteria:**
- **5 stars**: All code uses macOS 26 first with proper fallbacks
- **4 stars**: Minor compatibility issues
- **3 stars**: Some features broken on older versions
- **2 stars**: Multiple compatibility issues
- **1 star**: Crashes on supported versions

---

## Suggested Changes Classification

### 🔴 Critical (Must Fix Before Merge)

Non-negotiable blockers:

- Compiler errors
- Failing tests
- Force unwraps without justification (`!`)
- Security vulnerabilities (path traversal, missing validation)
- Hardcoded secrets
- Crashes on supported macOS versions
- Missing localization for user-facing text
- Data races or thread safety issues
- **Missing macOS 26 Liquid Glass implementation** (fallback-only code)
- **Missing fallbacks for macOS 14-15** (macOS 26-only code)
- **Glass effects without `#available(macOS 26, *)` check**

**Action:** Fix all critical issues before re-requesting review.

### 🟡 Important (Should Fix Before Merge)

Significantly improves quality:

- Missing tests for new code
- Hardcoded theme values (colors, spacing)
- Missing error handling
- `print()` statements left in code
- `[weak self]` missing in closures
- Code duplication
- Missing MARK comments
- Poor naming

**Action:** Strongly recommended. If not fixed, create follow-up issue.

### 🟢 Minor (Nice to Have)

Optional improvements:

- Minor style inconsistencies
- Additional test coverage
- Performance micro-optimizations
- Documentation improvements
- Code organization suggestions

**Action:** Optional. Can address in future PR.

---

## Manual Testing Checklist

### Feature Testing

- [ ] Feature works as expected
- [ ] Loading states display correctly
- [ ] Error states handled gracefully
- [ ] Empty states show appropriate UI

### Theme Testing

Test appearance:

- [ ] Light mode (System Preferences → Appearance → Light)
- [ ] Dark mode (System Preferences → Appearance → Dark)
- [ ] Accent colors work correctly

### Language Testing

Test all supported languages:

- [ ] English (en) - Default
- [ ] Italian (it) - Italiano
- [ ] Spanish (es) - Español

Change language via app settings or:
```swift
LocalizationManager.shared.setLanguage(.italian)
```

### macOS Version Testing

If possible, test on:

- [ ] macOS 14 (Sonoma)
- [ ] macOS 15 (Sequoia)
- [ ] macOS 26 (with Liquid Glass)

### Permissions Testing

- [ ] Works without Full Disk Access (limited features)
- [ ] Works with Full Disk Access (all features)
- [ ] Permission prompts appear correctly
- [ ] No TCC database access errors

### Edge Cases

- [ ] Empty data (no files to clean)
- [ ] Large datasets (thousands of files)
- [ ] Long file names
- [ ] Special characters in paths
- [ ] Cancellation during operations

---

## Quick Reference

### Commands to Run Before Review

```bash
# 1. Clean and build
xcodebuild clean build -project MyMacCleaner.xcodeproj -scheme MyMacCleaner

# 2. Run tests
xcodebuild test -project MyMacCleaner.xcodeproj -scheme MyMacCleaner

# 3. Check for warnings
xcodebuild -project MyMacCleaner.xcodeproj -scheme MyMacCleaner build 2>&1 | grep -i "warning:" | wc -l

# 4. Find print statements (should be 0 in production)
grep -rn "print(" MyMacCleaner/ --include="*.swift" | grep -v "// " | wc -l

# 5. Find TODO/FIXME comments
grep -rn "TODO\|FIXME" MyMacCleaner/ --include="*.swift" | wc -l

# 6. Check file sizes (flag files > 500 lines)
find MyMacCleaner -name "*.swift" | xargs wc -l | sort -n | tail -20

# 7. Check macOS 26 availability patterns (should use #available, not #unavailable)
grep -rn "#unavailable" MyMacCleaner/ --include="*.swift" | wc -l

# 8. Find glassEffect without availability check (potential crash)
grep -rn "\.glassEffect" MyMacCleaner/ --include="*.swift" | grep -v "#available" | wc -l

# 9. Verify macOS 26 patterns exist (should be > 0 for glass components)
grep -rn "#available(macOS 26" MyMacCleaner/ --include="*.swift" | wc -l
```

### Minimum Merge Requirements

- ✅ Build succeeds without errors
- ✅ All tests pass
- ✅ Zero compiler warnings
- ✅ All 12 categories: 4+ stars
- ✅ Critical changes: Fixed
- ✅ Manual testing: Completed
- ✅ No print statements in new code
- ✅ All user-facing text localized
- ✅ **macOS 26 Liquid Glass used as primary implementation**
- ✅ **Fallbacks provided for macOS 14-15**
- ✅ **No `#unavailable` patterns** (use `#available` with else)

---

## Review Template

Use this template when reviewing:

```markdown
## Code Review: [PR Title]

### Automated Checks
- [ ] Build: ✅/❌
- [ ] Tests: ✅/❌
- [ ] Warnings: [count]

### macOS 26 Compliance
- [ ] Uses macOS 26 APIs as primary: ✅/❌/N/A
- [ ] Has fallbacks for macOS 14-15: ✅/❌/N/A
- [ ] No #unavailable patterns: ✅/❌

### Category Scores

| Category | Score | Notes |
|----------|-------|-------|
| 1. Architecture & MVVM | ⭐⭐⭐⭐ | |
| 2. Concurrency | ⭐⭐⭐⭐⭐ | |
| 3. Theme & Design | ⭐⭐⭐⭐ | |
| 4. Localization | ⭐⭐⭐⭐⭐ | |
| 5. Error Handling | ⭐⭐⭐⭐ | |
| 6. Security | ⭐⭐⭐⭐⭐ | |
| 7. Animations & UX | ⭐⭐⭐⭐ | |
| 8. Testing | ⭐⭐⭐ | |
| 9. Code Quality | ⭐⭐⭐⭐ | |
| 10. Data Models | ⭐⭐⭐⭐⭐ | |
| 11. Dead Code | ⭐⭐⭐⭐⭐ | |
| 12. macOS Compatibility | ⭐⭐⭐⭐ | |

### Changes Required

#### 🔴 Critical
- [ ] Issue 1
- [ ] Issue 2

#### 🟡 Important
- [ ] Issue 1

#### 🟢 Minor
- Issue 1

### Verdict
- [ ] ✅ Approved
- [ ] 🔄 Request Changes
- [ ] ❌ Rejected
```

---

**Remember: Quality over speed. Clean code over quick delivery. macOS 26 first. Security always.**

import Testing
import Foundation
@testable import MyMacCleaner

// MARK: - Navigation Section Tests

@Suite("Navigation Section Tests")
struct NavigationSectionTests {

    @Test("All navigation sections are defined")
    func allSectionsExist() async throws {
        let sections = NavigationSection.allCases
        #expect(sections.count == 7)
        #expect(sections.contains(.home))
        #expect(sections.contains(.diskCleaner))
        #expect(sections.contains(.performance))
        #expect(sections.contains(.applications))
        #expect(sections.contains(.startupItems))
        #expect(sections.contains(.portManagement))
        #expect(sections.contains(.systemHealth))
    }

    @Test("Each section has a unique raw value")
    func uniqueRawValues() async throws {
        let rawValues = NavigationSection.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }
}

// MARK: - Scan Category Tests

@Suite("Scan Category Tests")
struct ScanCategoryTests {

    @Test("All scan categories have paths defined")
    func allCategoriesHavePaths() async throws {
        for category in ScanCategory.allCases {
            #expect(!category.paths.isEmpty, "Category \(category.rawValue) should have paths")
        }
    }

    @Test("Categories have localized names")
    func categoriesHaveLocalizedNames() async throws {
        for category in ScanCategory.allCases {
            let name = category.localizedName
            #expect(!name.isEmpty, "Category \(category.rawValue) should have a localized name")
        }
    }

    @Test("Categories have icons defined")
    func categoriesHaveIcons() async throws {
        for category in ScanCategory.allCases {
            let icon = category.icon
            #expect(!icon.isEmpty, "Category \(category.rawValue) should have an icon")
        }
    }

    @Test("FDA requirement is properly set")
    func fdaRequirements() async throws {
        // System cache typically requires FDA
        #expect(ScanCategory.systemCache.requiresFullDiskAccess == true)
        // User cache doesn't require FDA
        #expect(ScanCategory.userCache.requiresFullDiskAccess == false)
    }
}

// MARK: - Cleanable Item Tests

@Suite("Cleanable Item Tests")
struct CleanableItemTests {

    @Test("Item is selected by default")
    func itemSelectedByDefault() async throws {
        let item = CleanableItem(
            name: "test.txt",
            path: URL(fileURLWithPath: "/tmp/test.txt"),
            size: 1024,
            modificationDate: Date(),
            category: .userCache
        )
        #expect(item.isSelected == true)
    }

    @Test("Item has unique ID")
    func itemHasUniqueId() async throws {
        let item1 = CleanableItem(
            name: "test1.txt",
            path: URL(fileURLWithPath: "/tmp/test1.txt"),
            size: 1024,
            modificationDate: Date(),
            category: .userCache
        )
        let item2 = CleanableItem(
            name: "test2.txt",
            path: URL(fileURLWithPath: "/tmp/test2.txt"),
            size: 1024,
            modificationDate: Date(),
            category: .userCache
        )
        #expect(item1.id != item2.id)
    }
}

// MARK: - Scan Result Tests

@Suite("Scan Result Tests")
struct ScanResultTests {

    @Test("Total size is calculated correctly")
    func totalSizeCalculation() async throws {
        var items = [
            CleanableItem(
                name: "file1.txt",
                path: URL(fileURLWithPath: "/tmp/file1.txt"),
                size: 1000,
                modificationDate: Date(),
                category: .userCache
            ),
            CleanableItem(
                name: "file2.txt",
                path: URL(fileURLWithPath: "/tmp/file2.txt"),
                size: 2000,
                modificationDate: Date(),
                category: .userCache
            )
        ]

        let result = ScanResult(category: .userCache, items: items)
        #expect(result.totalSize == 3000)
    }

    @Test("Selected size only counts selected items")
    func selectedSizeCalculation() async throws {
        var item1 = CleanableItem(
            name: "file1.txt",
            path: URL(fileURLWithPath: "/tmp/file1.txt"),
            size: 1000,
            modificationDate: Date(),
            category: .userCache
        )
        var item2 = CleanableItem(
            name: "file2.txt",
            path: URL(fileURLWithPath: "/tmp/file2.txt"),
            size: 2000,
            modificationDate: Date(),
            category: .userCache
        )
        item2.isSelected = false

        var result = ScanResult(category: .userCache, items: [item1, item2])
        #expect(result.selectedSize == 1000)
    }

    @Test("Item count is correct")
    func itemCountIsCorrect() async throws {
        let items = (1...5).map { i in
            CleanableItem(
                name: "file\(i).txt",
                path: URL(fileURLWithPath: "/tmp/file\(i).txt"),
                size: Int64(i * 100),
                modificationDate: Date(),
                category: .userCache
            )
        }

        let result = ScanResult(category: .userCache, items: items)
        #expect(result.itemCount == 5)
    }
}

// MARK: - Toast Type Tests

@Suite("Toast Type Tests")
struct ToastTypeTests {

    @Test("Toast types have icons")
    func toastTypesHaveIcons() async throws {
        #expect(!ToastType.success.icon.isEmpty)
        #expect(!ToastType.error.icon.isEmpty)
        #expect(!ToastType.info.icon.isEmpty)
    }

    @Test("Toast types have distinct icons")
    func toastTypesHaveDistinctIcons() async throws {
        let icons = [ToastType.success.icon, ToastType.error.icon, ToastType.info.icon]
        let uniqueIcons = Set(icons)
        #expect(icons.count == uniqueIcons.count)
    }
}

// MARK: - Theme Tests

@Suite("Theme Tests")
struct ThemeTests {

    @Test("Spacing values are positive")
    func spacingValuesPositive() async throws {
        #expect(Theme.Spacing.xxs > 0)
        #expect(Theme.Spacing.xs > 0)
        #expect(Theme.Spacing.sm > 0)
        #expect(Theme.Spacing.md > 0)
        #expect(Theme.Spacing.lg > 0)
        #expect(Theme.Spacing.xl > 0)
        #expect(Theme.Spacing.xxl > 0)
    }

    @Test("Spacing values are in ascending order")
    func spacingValuesAscending() async throws {
        #expect(Theme.Spacing.xxs < Theme.Spacing.xs)
        #expect(Theme.Spacing.xs < Theme.Spacing.sm)
        #expect(Theme.Spacing.sm < Theme.Spacing.md)
        #expect(Theme.Spacing.md < Theme.Spacing.lg)
        #expect(Theme.Spacing.lg < Theme.Spacing.xl)
        #expect(Theme.Spacing.xl < Theme.Spacing.xxl)
    }

    @Test("Corner radius values are positive")
    func cornerRadiusValuesPositive() async throws {
        #expect(Theme.CornerRadius.small > 0)
        #expect(Theme.CornerRadius.medium > 0)
        #expect(Theme.CornerRadius.large > 0)
        #expect(Theme.CornerRadius.xl > 0)
        #expect(Theme.CornerRadius.pill > 0)
    }

    @Test("Thresholds are properly defined")
    func thresholdsAreDefined() async throws {
        #expect(Theme.Thresholds.minimumFileSize > 0)
        #expect(Theme.Thresholds.DiskSpace.warningFreeSpace > Theme.Thresholds.DiskSpace.criticalFreeSpace)
        #expect(Theme.Thresholds.StartupItems.criticalCount > Theme.Thresholds.StartupItems.warningCount)
        #expect(Theme.Thresholds.Memory.criticalUsage > Theme.Thresholds.Memory.warningUsage)
    }

    @Test("Timing values are positive")
    func timingValuesPositive() async throws {
        #expect(Theme.Timing.visualFeedback > 0)
        #expect(Theme.Timing.progressStep > 0)
        #expect(Theme.Timing.shortPause > 0)
        #expect(Theme.Timing.completionDisplay > 0)
        #expect(Theme.Timing.toastDuration > 0)
        #expect(Theme.Timing.clearResultsDelay > 0)
        #expect(Theme.Timing.processRefreshInterval > 0)
    }
}

// MARK: - File Scanner Path Validation Tests

@Suite("File Scanner Path Validation Tests")
struct FileScannerPathValidationTests {

    @Test("Path validation rejects root directories")
    func rejectsRootDirectories() async throws {
        // We can't directly test the private method, but we can verify
        // that DeletionResult errors are returned for invalid paths
        let scanner = FileScanner.shared

        // Create a fake item pointing to a forbidden directory
        let forbiddenItem = CleanableItem(
            name: "forbidden",
            path: URL(fileURLWithPath: "/Applications"),
            size: 1000,
            modificationDate: Date(),
            category: .userCache
        )

        let result = await scanner.trashItems([forbiddenItem])
        #expect(result.failedCount > 0, "Should reject /Applications")
        #expect(!result.errors.isEmpty, "Should have errors for rejected path")
    }
}

// MARK: - App Language Tests

@Suite("App Language Tests")
struct AppLanguageTests {

    @Test("All languages have native names")
    func languagesHaveNativeNames() async throws {
        for language in AppLanguage.allCases {
            #expect(!language.nativeName.isEmpty)
        }
    }

    @Test("All languages have short codes")
    func languagesHaveShortCodes() async throws {
        for language in AppLanguage.allCases {
            #expect(!language.shortCode.isEmpty)
            #expect(language.shortCode.count == 2, "Short code should be 2 characters")
        }
    }

    @Test("Language raw values are valid locale codes")
    func languageRawValuesAreValidLocaleCodes() async throws {
        let validCodes = ["en", "it", "es"]
        for language in AppLanguage.allCases {
            #expect(validCodes.contains(language.rawValue))
        }
    }
}

// MARK: - Localization Manager Tests

@Suite("Localization Manager Tests")
struct LocalizationManagerTests {

    @Test("Default language is valid")
    func defaultLanguageIsValid() async throws {
        let manager = LocalizationManager.shared
        #expect(AppLanguage(rawValue: manager.languageCode) != nil)
    }

    @Test("Locale is created from language code")
    func localeIsCreatedFromLanguageCode() async throws {
        let manager = LocalizationManager.shared
        let locale = manager.locale
        #expect(locale.identifier == manager.languageCode)
    }

    @Test("Current language matches language code")
    func currentLanguageMatchesCode() async throws {
        let manager = LocalizationManager.shared
        #expect(manager.currentLanguage.rawValue == manager.languageCode)
    }
}

// MARK: - Maintenance Task Tests

@Suite("Maintenance Task Tests")
struct MaintenanceTaskTests {

    @Test("All tasks have unique IDs")
    func allTasksHaveUniqueIds() async throws {
        let tasks = MaintenanceTask.allTasks
        let ids = tasks.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "All task IDs should be unique")
    }

    @Test("All tasks have descriptions")
    func allTasksHaveDescriptions() async throws {
        for task in MaintenanceTask.allTasks {
            #expect(!task.description.isEmpty, "Task \(task.id) should have a description")
        }
    }

    @Test("Admin tasks are marked correctly")
    func adminTasksMarkedCorrectly() async throws {
        // These tasks require admin privileges
        let adminTaskIds = ["purge_ram", "kill_dns", "rebuild_spotlight"]

        for task in MaintenanceTask.allTasks {
            if adminTaskIds.contains(task.id) {
                #expect(task.requiresAdmin == true, "Task \(task.id) should require admin")
            }
        }
    }
}

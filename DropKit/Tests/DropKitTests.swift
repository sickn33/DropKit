import XCTest
@testable import DropKit

final class DropKitTests: XCTestCase {
    func testDragMonitorRegistersGlobalMouseMonitorsOnStart() {
        // 摇晃/拖拽依赖鼠标事件监控，无需辅助功能权限，start() 应无条件注册全局监控。
        let eventMonitor = RecordingGlobalEventMonitor()
        let monitor = DragMonitor(eventMonitor: eventMonitor)

        XCTAssertTrue(monitor.start())
        XCTAssertEqual(eventMonitor.addedMasks.count, 2)  // leftMouseDragged + leftMouseUp
    }

    func testShakeDetectorRegistersGlobalMouseMonitorOnStart() {
        let eventMonitor = RecordingGlobalEventMonitor()
        let detector = ShakeDetector(eventMonitor: eventMonitor)

        XCTAssertTrue(detector.start())
        XCTAssertEqual(eventMonitor.addedMasks.count, 1)  // leftMouseDragged
    }

    func testBuiltInSensitiveClipboardAppsAreAlwaysIgnored() throws {
        let defaults = try makeDefaults()
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: StubBookmarkProvider()
            )
        )

        XCTAssertFalse(settings.clipboardBlacklistEnabled)
        XCTAssertTrue(settings.isBlacklisted("com.1password.1password"))
        XCTAssertTrue(settings.isBlacklisted("com.bitwarden.desktop"))
    }

    func testCustomClipboardBlacklistStillRequiresUserToggle() throws {
        let defaults = try makeDefaults()
        defaults.set(["com.example.Notes"], forKey: "clipboardBlacklist")
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: StubBookmarkProvider()
            )
        )

        XCTAssertFalse(settings.isBlacklisted("com.example.Notes"))

        settings.clipboardBlacklistEnabled = true

        XCTAssertTrue(settings.isBlacklisted("com.example.Notes"))
    }

    func testSettingWatchedFolderPersistsBookmarkAndResolvedPath() throws {
        let defaults = try makeDefaults()
        let bookmarkProvider = StubBookmarkProvider()
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: bookmarkProvider
            )
        )
        let folderURL = URL(fileURLWithPath: "/tmp/dropkit-tests/watched-folder", isDirectory: true)

        XCTAssertTrue(settings.setWatchedFolder(folderURL))
        XCTAssertEqual(settings.watchedFolderPath, folderURL.path)
        XCTAssertEqual(settings.watchedFolderURL()?.path, folderURL.path)
        XCTAssertEqual(bookmarkProvider.savedURLs, [folderURL])
    }

    func testClearingWatchedFolderRemovesPersistedState() throws {
        let defaults = try makeDefaults()
        let bookmarkProvider = StubBookmarkProvider()
        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: bookmarkProvider
            )
        )
        let folderURL = URL(fileURLWithPath: "/tmp/dropkit-tests/watched-folder", isDirectory: true)

        XCTAssertTrue(settings.setWatchedFolder(folderURL))

        settings.clearWatchedFolder()

        XCTAssertNil(settings.watchedFolderPath)
        XCTAssertNil(settings.watchedFolderURL())
        XCTAssertNil(defaults.data(forKey: "watchedFolderBookmark"))
    }

    func testInvalidPersistedBookmarkIsIgnoredOnInitialization() throws {
        let defaults = try makeDefaults()
        defaults.set(Data("invalid".utf8), forKey: "watchedFolderBookmark")
        defaults.set("/tmp/legacy-path", forKey: "watchedFolderPath")

        let settings = AppSettings(
            defaults: defaults,
            launchAtLoginManager: StubLaunchAtLoginManager(),
            bookmarkStore: FolderBookmarkStore(
                defaults: defaults,
                key: "watchedFolderBookmark",
                bookmarkProvider: FailingBookmarkProvider()
            )
        )

        XCTAssertNil(settings.watchedFolderPath)
        XCTAssertNil(settings.watchedFolderURL())
        XCTAssertNil(defaults.data(forKey: "watchedFolderBookmark"))
    }

    func testAddItemReturnsWhetherAFileWasInserted() throws {
        let viewModel = ShelfViewModel()
        let fileURL = try makeTemporaryFile()

        XCTAssertTrue(viewModel.addItem(url: fileURL))
        XCTAssertFalse(viewModel.addItem(url: fileURL))
        XCTAssertEqual(viewModel.items.count, 1)

        viewModel.clearAll()
    }

    @MainActor
    func testThumbnailGenerationWorksForNewItemsByDefault() async throws {
        let viewModel = ShelfViewModel()
        let fileURL = try makeTemporaryPNG()

        XCTAssertTrue(viewModel.addItem(url: fileURL))
        guard let itemId = viewModel.items.first?.id else {
            return XCTFail("Expected inserted item")
        }

        viewModel.ensureThumbnail(for: itemId, kind: .large)
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertNotNil(viewModel.items.first?.thumbnail)
    }

    func testClearAllDeletesStoredClipboardImagesAndOrphans() throws {
        let directory = try makeTemporaryDirectory()
        let imagesDirectory = directory.appendingPathComponent("ClipboardImages", isDirectory: true)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let storedImage = imagesDirectory.appendingPathComponent("stored.png")
        let orphanedImage = imagesDirectory.appendingPathComponent("orphaned.png")
        let externalImage = directory.appendingPathComponent("external.png")

        try Data("stored".utf8).write(to: storedImage)
        try Data("orphaned".utf8).write(to: orphanedImage)
        try Data("external".utf8).write(to: externalImage)

        let storageURL = directory.appendingPathComponent("clipboard_history.json")
        let items = [
            ClipboardItem(type: .image, content: storedImage.path),
            ClipboardItem(type: .image, content: externalImage.path)
        ]
        try JSONEncoder().encode(items).write(to: storageURL)

        let monitor = ClipboardMonitor(storageURL: storageURL, imagesDirectory: imagesDirectory)
        XCTAssertEqual(monitor.items.count, 2)

        monitor.clearAll()

        XCTAssertTrue(monitor.items.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storedImage.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: orphanedImage.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: externalImage.path))
    }

    func testRemovingDuplicateImageReferenceKeepsFileUntilLastReferenceIsRemoved() throws {
        let directory = try makeTemporaryDirectory()
        let imagesDirectory = directory.appendingPathComponent("ClipboardImages", isDirectory: true)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let storedImage = imagesDirectory.appendingPathComponent("stored.png")
        try Data("stored".utf8).write(to: storedImage)

        let storageURL = directory.appendingPathComponent("clipboard_history.json")
        let items = [
            ClipboardItem(type: .image, content: storedImage.path),
            ClipboardItem(type: .image, content: storedImage.path)
        ]
        try JSONEncoder().encode(items).write(to: storageURL)

        let monitor = ClipboardMonitor(storageURL: storageURL, imagesDirectory: imagesDirectory)
        XCTAssertEqual(monitor.items.count, 2)

        monitor.removeItem(monitor.items[0])

        XCTAssertEqual(monitor.items.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storedImage.path))

        monitor.clearAll()

        XCTAssertFalse(FileManager.default.fileExists(atPath: storedImage.path))
    }

    func testLatestWorkDebouncerRunsOnlyMostRecentScheduledWork() {
        let debouncer = LatestWorkDebouncer()
        let queue = DispatchQueue(label: "DropKitTests.LatestWorkDebouncer")
        let expectation = expectation(description: "latest work runs")
        let lock = NSLock()
        var values: [Int] = []

        expectation.expectedFulfillmentCount = 1

        debouncer.schedule(after: .milliseconds(20), on: queue) {
            lock.lock()
            values.append(1)
            lock.unlock()
            expectation.fulfill()
        }
        debouncer.schedule(after: .milliseconds(20), on: queue) {
            lock.lock()
            values.append(2)
            lock.unlock()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        lock.lock()
        let capturedValues = values
        lock.unlock()
        XCTAssertEqual(capturedValues, [2])
    }

    @MainActor
    func testMainRunLoopCoalescerRunsMultipleRequestsOncePerTurn() async {
        let coalescer = MainRunLoopCoalescer()
        var runCount = 0

        coalescer.schedule {
            runCount += 1
        }
        coalescer.schedule {
            runCount += 1
        }

        XCTAssertEqual(runCount, 0)

        await waitForMainQueueTurn()

        XCTAssertEqual(runCount, 1)

        coalescer.schedule {
            runCount += 1
        }

        await waitForMainQueueTurn()

        XCTAssertEqual(runCount, 2)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "DropKitTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw XCTSkip("Failed to create isolated defaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeTemporaryFile() throws -> URL {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("screenshot.png")
        try Data("dropkit".utf8).write(to: fileURL)
        return fileURL
    }

    private func makeTemporaryPNG() throws -> URL {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("image.png")

        let image = NSImage(size: NSSize(width: 8, height: 8))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: 8, height: 8).fill()
        image.unlockFocus()

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw XCTSkip("Failed to create test PNG")
        }

        try pngData.write(to: fileURL)
        return fileURL
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DropKitTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }

    private func waitForMainQueueTurn() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }
}

private final class StubBookmarkProvider: FolderBookmarking {
    private(set) var savedURLs: [URL] = []

    func makeBookmark(for url: URL) throws -> Data {
        savedURLs.append(url)
        return Data(url.path.utf8)
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        guard let path = String(data: data, encoding: .utf8) else {
            throw BookmarkProviderError.invalidData
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}

private struct FailingBookmarkProvider: FolderBookmarking {
    func makeBookmark(for url: URL) throws -> Data {
        Data()
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        throw BookmarkProviderError.invalidData
    }
}

private struct StubLaunchAtLoginManager: LaunchAtLoginManaging {
    func currentStatus() -> Bool { false }
    func setEnabled(_ enabled: Bool) throws {}
}

private final class RecordingGlobalEventMonitor: GlobalEventMonitoring {
    private(set) var addedMasks: [NSEvent.EventTypeMask] = []
    private(set) var removedCount = 0

    func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Any? {
        addedMasks.append(mask)
        return NSObject()
    }

    func removeMonitor(_ monitor: Any) {
        removedCount += 1
    }
}

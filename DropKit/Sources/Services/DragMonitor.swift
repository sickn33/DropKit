import AppKit

protocol GlobalEventMonitoring {
    func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Any?
    func removeMonitor(_ monitor: Any)
}

struct AppKitGlobalEventMonitor: GlobalEventMonitoring {
    func addGlobalMonitor(matching mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Any? {
        NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func removeMonitor(_ monitor: Any) {
        NSEvent.removeMonitor(monitor)
    }
}

@Observable
class DragMonitor {
    private(set) var isDragging = false

    private var dragMonitor: Any?
    private var upMonitor: Any?
    private let eventMonitor: any GlobalEventMonitoring

    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?

    init(eventMonitor: any GlobalEventMonitoring = AppKitGlobalEventMonitor()) {
        self.eventMonitor = eventMonitor
    }

    // 监控的是鼠标事件（leftMouseDragged / leftMouseUp）。按 Apple 文档，
    // 全局监控鼠标事件无需辅助功能权限（只有键盘事件才需要），故此处不做任何权限门控。
    @discardableResult
    func start() -> Bool {
        guard dragMonitor == nil, upMonitor == nil else { return true }

        guard let dragMonitor = eventMonitor.addGlobalMonitor(matching: .leftMouseDragged, handler: { [weak self] _ in
            guard let self = self, !self.isDragging else { return }
            self.isDragging = true
            self.onDragStart?()
        }) else { return false }

        guard let upMonitor = eventMonitor.addGlobalMonitor(matching: .leftMouseUp, handler: { [weak self] _ in
            guard let self = self, self.isDragging else { return }
            self.isDragging = false
            self.onDragEnd?()
        }) else {
            eventMonitor.removeMonitor(dragMonitor)
            return false
        }

        self.dragMonitor = dragMonitor
        self.upMonitor = upMonitor
        return true
    }

    func stop() {
        if let monitor = dragMonitor {
            eventMonitor.removeMonitor(monitor)
            dragMonitor = nil
        }
        if let monitor = upMonitor {
            eventMonitor.removeMonitor(monitor)
            upMonitor = nil
        }
        isDragging = false
    }

    deinit {
        stop()
    }
}

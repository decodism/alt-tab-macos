import Foundation

class Dock {
    static var element: AXUIElement?
    static var observer: AXObserver?
    static var lastHovered: DockApp?
    
    static func observe(_ app: NSRunningApplication) {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        Dock.element = try? appElement.children()?.first
        guard Dock.element != nil else { return }
        AXObserverCreate(app.processIdentifier, axObserverCallback, &Dock.observer)
        guard Dock.observer != nil else { return }
        try? Dock.element!.subscribeToNotification(Dock.observer!, kAXSelectedChildrenChangedNotification)
        CFRunLoopAddSource(BackgroundWork.accessibilityEventsThread.runLoop, AXObserverGetRunLoopSource(Dock.observer!), .defaultMode)
    }
}

struct DockApp {
    let pid: pid_t
    let centerPosition: CGPoint
}

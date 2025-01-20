import Cocoa
import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var clipboardManager: ClipboardManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 상태바 아이템 생성
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
        }
        
        // 클립보드 매니저 초기화
        clipboardManager = ClipboardManager()
        
        // 메뉴 설정
        setupMenu()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        // 클립보드 항목들을 보여주는 메뉴
        menu.delegate = self
        
        // 구분선
        menu.addItem(NSMenuItem.separator())
        
        // 종료 버튼
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// NSMenu delegate를 확장하여 동적 메뉴 아이템 생성
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // 기존 클립보드 항목들 제거 (구분선과 종료 버튼 제외)
        while menu.items.count > 2 {
            menu.removeItem(at: 0)
        }
        
        // 클립보드 항목들을 메뉴에 추가
        for (index, entry) in clipboardManager.getEntries().enumerated().reversed() {
            let item = NSMenuItem(title: entry.text.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines),
                                action: #selector(menuItemClicked(_:)),
                                keyEquivalent: "")
            item.tag = index
            menu.insertItem(item, at: 0)
        }
    }
}

extension AppDelegate {
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        let entries = clipboardManager.getEntries()
        guard sender.tag < entries.count else { return }
        
        let selectedEntry = entries[sender.tag]
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedEntry.text, forType: .string)
    }
}

// 클립보드 관리 클래스
class ClipboardManager {
    private var entries: [ClipboardEntry] = []
    private let maxEntries: Int
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    struct ClipboardEntry: Identifiable {
        let id = UUID()
        let text: String
        let timestamp: Date
    }
    
    init(maxEntries: Int = 10) {
        self.maxEntries = maxEntries
        self.lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    private func checkClipboardChanges() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        
        if let newString = pasteboard.string(forType: .string) {
            addEntry(newString)
        }
    }
    
    private func addEntry(_ text: String) {
        let entry = ClipboardEntry(text: text, timestamp: Date())
        entries.insert(entry, at: 0)
        
        // 최대 개수 유지
        if entries.count > maxEntries {
            entries.removeLast()
        }
    }
    
    func getEntries() -> [ClipboardEntry] {
        return entries
    }
}

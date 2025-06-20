import Foundation
import AppKit

@MainActor
class ClipboardManager: ObservableObject {
    @Published var history: [ClipboardItem] = []

    private let userDefaultsKey = "clipboardHistory"
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    init() {
        loadFromDisk()
        startMonitoring()
    }
    
    func delete(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        saveToDisk()
    }

    func clearHistory() {
        history.removeAll()
        saveToDisk()
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let data):
            if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        }
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount

            if let types = pasteboard.types {
                if types.contains(.string), let string = pasteboard.string(forType: .string) {
                    self.addToHistory(.text(string))
                } else if types.contains(.tiff), let data = pasteboard.data(forType: .tiff) {
                    self.addToHistory(.image(data))
                }
            }
        }
    }

    private func addToHistory(_ content: ClipboardContent) {
        let newItem = ClipboardItem(content: content)

        // Não duplica texto consecutivo igual
        if let last = history.first, last.content == newItem.content { return }

        history.insert(newItem, at: 0)
        saveToDisk()
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ Falha ao salvar histórico: \(error)")
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("❌ Falha ao carregar histórico: \(error)")
        }
    }
}

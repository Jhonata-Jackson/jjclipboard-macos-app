import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ClipboardManager()
    @State private var selectedItem: ClipboardItem?
    @State private var searchText: String = ""

    var filteredHistory: [ClipboardItem] {
        if searchText.isEmpty {
            return manager.history
        } else {
            return manager.history.filter { item in
                switch item.content {
                case .text(let text):
                    return text.localizedCaseInsensitiveContains(searchText)
                case .image:
                    return false
                }
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                TextField("Buscar...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.all, 8)

                List(selection: $selectedItem) {
                    ForEach(filteredHistory) { item in
                        HStack(spacing: 8) {
                            icon(for: item)
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title(for: item))
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text(item.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                delete(item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                        }
                    }
                }
                .listStyle(SidebarListStyle())

                Divider()

                // Botão Apagar tudo
                HStack {
                    Spacer()
                    Button(action: deleteAll) {
                        Label("Apagar tudo", systemImage: "trash")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(8)
                    .cornerRadius(6)
                }
            }
            .frame(width: 300)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Painel principal
            VStack(alignment: .leading, spacing: 6) {
                if let item = selectedItem {
                    // Preview com texto alinhado no topo
                    preview(for: item)
                        .frame(maxHeight: 340)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    Divider()

                    // Info compactada
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📄 Tipo: \(metadataType(for: item))")
                        if case let .text(text) = item.content {
                            Text("📏 \(text.count) caracteres")
                        } else if case let .image(data) = item.content,
                                  let image = NSImage(data: data) {
                            Text("📐 \(Int(image.size.width))x\(Int(image.size.height))")
                            Text("💾 \(formatBytes(data.count))")
                        }
                        Text("🕒 \(formattedDate(item.timestamp))")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                    HStack {
                        Spacer()
                        Button(action: {
                            copyToClipboard(item)
                        }) {
                            Label("Copiar", systemImage: "doc.on.doc")
                        }
                        .keyboardShortcut("c", modifiers: [.command])
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }

                } else {
                    Spacer()
                    Text("Selecione um item")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    // MARK: - Helpers

    func icon(for item: ClipboardItem) -> Image {
        switch item.content {
        case .text(let value):
            if value.starts(with: "http") {
                return Image(systemName: "link")
            } else if value.starts(with: "#") {
                return Image(systemName: "eyedropper")
            }
            return Image(systemName: "doc.text")
        case .image:
            return Image(systemName: "photo")
        }
    }

    func title(for item: ClipboardItem) -> String {
        switch item.content {
        case .text(let text):
            return text
        case .image(let data):
            if let image = NSImage(data: data) {
                return "Imagem (\(Int(image.size.width))x\(Int(image.size.height)))"
            }
            return "Imagem"
        }
    }

    func preview(for item: ClipboardItem) -> some View {
        switch item.content {
        case .text(let text):
            return AnyView(
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(text)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding()
                        Spacer()
                    }
                }
            )
        case .image(let data):
            if let image = NSImage(data: data) {
                return AnyView(
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                )
            } else {
                return AnyView(Text("Erro ao carregar imagem."))
            }
        }
    }

    func metadataType(for item: ClipboardItem) -> String {
        switch item.content {
        case .text:
            return "Texto"
        case .image:
            return "Imagem"
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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

    func delete(_ item: ClipboardItem) {
        if let index = manager.history.firstIndex(of: item) {
            manager.history.remove(at: index)
            if selectedItem == item {
                selectedItem = nil
            }
        }
    }

    func deleteAll() {
        manager.history.removeAll()
        selectedItem = nil
    }
}

#Preview {
    ContentView()
}

import Foundation
import AppKit

enum ClipboardContent: Codable, Equatable, Hashable {
    case text(String)
    case image(Data)

    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    enum ContentType: String, Codable {
        case text, image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .text:
            let value = try container.decode(String.self, forKey: .value)
            self = .text(value)
        case .image:
            let data = try container.decode(Data.self, forKey: .value)
            self = .image(data)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let value):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(value, forKey: .value)
        case .image(let data):
            try container.encode(ContentType.image, forKey: .type)
            try container.encode(data, forKey: .value)
        }
    }
}

struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date

    init(content: ClipboardContent) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
    }
}

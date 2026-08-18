import SwiftUI

func clean(_ value: Any?, fallback: String = "") -> String {
    guard let value else { return fallback }
    let text = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
    return text.isEmpty || text.lowercased() == "null" ? fallback : text
}

func optionalClean(_ value: Any?) -> String? {
    let text = clean(value)
    return text.isEmpty ? nil : text
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

func doubleValue(_ value: Any?) -> Double? {
    if let value = value as? Double { return value }
    if let value = value as? Int { return Double(value) }
    if let value = value as? NSNumber { return value.doubleValue }
    return Double(clean(value))
}

func intValue(_ value: Any?) -> Int? {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    return Int(clean(value))
}

func boolValue(_ value: Any?) -> Bool {
    if let value = value as? Bool { return value }
    if let value = value as? NSNumber { return value.boolValue }
    let text = clean(value).lowercased()
    return text == "true" || text == "1" || text == "yes"
}

func mapValue(_ value: Any?) -> [String: Any]? {
    value as? [String: Any]
}

func money(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
}

func colorValue(_ value: Any?) -> Color? {
    let raw = clean(value).replacingOccurrences(of: "#", with: "")
    guard raw.count == 6, let hex = Int(raw, radix: 16) else { return nil }
    return Color(
        red: Double((hex >> 16) & 0xff) / 255,
        green: Double((hex >> 8) & 0xff) / 255,
        blue: Double(hex & 0xff) / 255
    )
}

extension View {
    func frescoField() -> some View {
        self
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FrescoColors.border, lineWidth: 1)
            )
    }
}

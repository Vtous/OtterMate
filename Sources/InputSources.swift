import AppKit
import Carbon

struct InputSource: Identifiable, Equatable {
    var id: String
    var name: String
}

@MainActor
enum InputSources {
    private static func string(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private static func selectable() -> [TISInputSource] {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return sources.filter { source in
            guard let enabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled),
                  let capable = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else { return false }
            return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(enabled).takeUnretainedValue()) &&
                CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(capable).takeUnretainedValue()) &&
                string(source, kTISPropertyInputSourceCategory) == (kTISCategoryKeyboardInputSource as String)
        }
    }

    static func list() -> [InputSource] {
        var seen = Set<String>()
        return selectable().compactMap { source in
            guard let id = string(source, kTISPropertyInputSourceID), seen.insert(id).inserted else { return nil }
            return InputSource(id: id, name: string(source, kTISPropertyLocalizedName) ?? id)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func currentID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return string(source, kTISPropertyInputSourceID)
    }

    @discardableResult
    static func select(_ id: String) -> Bool {
        guard let source = selectable().first(where: { string($0, kTISPropertyInputSourceID) == id }) else {
            return false
        }
        return TISSelectInputSource(source) == noErr
    }
}

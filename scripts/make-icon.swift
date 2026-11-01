import Foundation

// Apple encodes both legacy small icons and Retina representations.
guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift make-icon.swift master-1024.png output.icns\n", stderr)
    exit(64)
}
let source = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let temp = FileManager.default.temporaryDirectory.appendingPathComponent("inputotter-icon-\(UUID().uuidString)")
try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temp) }

func run(_ executable: String, _ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    let errors = Pipe()
    process.standardError = errors
    try process.run()
    let message = errors.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "OtterMate.IconBuild", code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: String(data: message, encoding: .utf8) ?? executable])
    }
}

let iconset = temp.appendingPathComponent("OtterMate.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
var expected: [String] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        expected.append(name)
        try run("/usr/bin/sips", ["-z", "\(size*scale)", "\(size*scale)",
            "-s", "dpiWidth", "72", "-s", "dpiHeight", "72", source.path,
            "--out", iconset.appendingPathComponent(name).path])
    }
}
let encoded = temp.appendingPathComponent("OtterMate.icns")
try run("/usr/bin/iconutil", ["-c", "icns", iconset.path, "-o", encoded.path])
let decoded = temp.appendingPathComponent("verified.iconset")
try run("/usr/bin/iconutil", ["-c", "iconset", encoded.path, "-o", decoded.path])
for name in expected {
    guard FileManager.default.fileExists(atPath: decoded.appendingPathComponent(name).path) else {
        throw NSError(domain: "OtterMate.IconBuild", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Missing icon representation: \(name)"])
    }
}
try Data(contentsOf: encoded).write(to: output, options: .atomic)
print("Created and round-trip verified all 10 standard/Retina representations: \(output.path)")

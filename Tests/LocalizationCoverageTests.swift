import XCTest

final class LocalizationCoverageTests: XCTestCase {
    private var sourceDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("XGlassShot")
    }

    func testEveryLanguageContainsAllEnglishKeys() throws {
        let data = try Data(contentsOf: sourceDirectory.appendingPathComponent("Localizable.json"))
        let translations = try JSONDecoder().decode([String: [String: String]].self, from: data)
        let english = try XCTUnwrap(translations["en"])
        XCTAssertEqual(translations.count, 10)
        for (language, strings) in translations {
            let missing = Set(english.keys).subtracting(strings.keys).sorted()
            XCTAssertTrue(missing.isEmpty, "\(language) is missing: \(missing.joined(separator: ", "))")
            XCTAssertTrue(strings.values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
    }

    func testSwiftUILocalizationKeysExistInEnglish() throws {
        let data = try Data(contentsOf: sourceDirectory.appendingPathComponent("Localizable.json"))
        let translations = try JSONDecoder().decode([String: [String: String]].self, from: data)
        let english = try XCTUnwrap(translations["en"])
        let pattern = try NSRegularExpression(pattern: #""([^"\n]+)"\.localized"#)
        let files = try FileManager.default.contentsOfDirectory(at: sourceDirectory, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for match in pattern.matches(in: source, range: range) {
                let keyRange = try XCTUnwrap(Range(match.range(at: 1), in: source))
                let key = String(source[keyRange])
                XCTAssertNotNil(english[key], "\(file.lastPathComponent): missing \(key)")
            }
        }
    }
}

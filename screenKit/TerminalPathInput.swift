import SwiftUI
import AppKit

struct TerminalPathInput: View {
    @Binding var currentPath: String
    var onDismiss: (() -> Void)?
    
    @Environment(\.dismiss) var environmentDismiss
    
    @State private var inputText: String = ""
    @State private var suggestions: [String] = []
    @State private var selectedSuggestionIndex: Int = 0
    @State private var showSuggestions: Bool = false
    @FocusState private var isFocused: Bool
    
    private let prompt = "store_at: ~/"
    private let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Input bar
            HStack(spacing: 8) {
                Text(prompt)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.green)
                
                TextField("", text: $inputText)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.green)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onChange(of: inputText) { _, newValue in
                        updateSuggestions(for: newValue)
                    }
                    .onKeyPress(.tab) {
                        if !suggestions.isEmpty {
                            autocompleteBestMatch()
                        }
                        return .handled
                    }
                    .onKeyPress(.return) {
                        confirmPath()
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        onDismiss?() ?? environmentDismiss()
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        if showSuggestions && !suggestions.isEmpty {
                            selectedSuggestionIndex = max(0, selectedSuggestionIndex - 1)
                        }
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        if showSuggestions && !suggestions.isEmpty {
                            selectedSuggestionIndex = min(suggestions.count - 1, selectedSuggestionIndex + 1)
                        }
                        return .handled
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "1a1a1a"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Suggestions dropdown
            if showSuggestions && !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            SuggestionRow(
                                text: suggestion,
                                isSelected: index == selectedSuggestionIndex
                            )
                            .onTapGesture {
                                selectedSuggestionIndex = index
                                applySuggestion(suggestions[index])
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(hex: "1a1a1a"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .frame(width: 500)
        .onAppear {
            isFocused = true
            inputText = currentPath.replacingOccurrences(of: homeDirectory, with: "~")
                .replacingOccurrences(of: "~/", with: "")
        }
    }
    
    private func updateSuggestions(for input: String) {
        let expandedPath = expandTilde(input)
        let directory: String
        let searchTerm: String
        
        if expandedPath.isEmpty || expandedPath == homeDirectory {
            directory = homeDirectory
            searchTerm = ""
        } else {
            directory = (expandedPath as NSString).deletingLastPathComponent
            searchTerm = (expandedPath as NSString).lastPathComponent
        }
        
        guard FileManager.default.fileExists(atPath: directory) else {
            suggestions = []
            showSuggestions = false
            return
        }
        
        let url = URL(fileURLWithPath: directory)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            let directories = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }
            
            let folderNames = directories.map { $0.lastPathComponent }
            
            if searchTerm.isEmpty {
                suggestions = Array(folderNames.prefix(10))
            } else {
                suggestions = folderNames
                    .filter { $0.lowercased().hasPrefix(searchTerm.lowercased()) }
                    .prefix(10)
                    .map { String($0) }
            }
            
            showSuggestions = !suggestions.isEmpty
            selectedSuggestionIndex = 0
        } catch {
            suggestions = []
            showSuggestions = false
        }
    }
    
    private func expandTilde(_ path: String) -> String {
        if path.hasPrefix("~/") {
            return path.replacingOccurrences(of: "~/", with: "\(homeDirectory)/")
        } else if path == "~" {
            return homeDirectory
        }
        return path
    }
    
    private func autocompleteBestMatch() {
        guard !suggestions.isEmpty else { return }
        applySuggestion(suggestions[selectedSuggestionIndex])
    }
    
    private func applySuggestion(_ suggestion: String) {
        let expandedPath = expandTilde(inputText)
        let directory: String
        
        if expandedPath.isEmpty || expandedPath == homeDirectory {
            directory = homeDirectory
        } else {
            directory = (expandedPath as NSString).deletingLastPathComponent
        }
        
        let newPath = (directory as NSString).appendingPathComponent(suggestion)
        let relativePath = newPath.replacingOccurrences(of: homeDirectory, with: "~")
            .replacingOccurrences(of: "\(homeDirectory)/", with: "~/")
        inputText = relativePath + "/"
        updateSuggestions(for: inputText)
    }
    
    private func confirmPath() {
        let expanded = expandTilde(inputText)
        currentPath = expanded
        onDismiss?() ?? environmentDismiss()
    }
}

struct SuggestionRow: View {
    let text: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.green.opacity(0.2) : Color.clear)
    }
}


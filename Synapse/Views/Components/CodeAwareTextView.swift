import SwiftUI

/// Parses text containing markdown-style code blocks (```...```) and inline code (`...`)
/// and renders them with proper formatting.
struct CodeAwareTextView: View {
    let text: String
    var baseFont: Font = .callout

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let content):
                    if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        inlineCodeText(content)
                    }
                case .codeBlock(let language, let code):
                    codeBlockView(language: language, code: code)
                }
            }
        }
    }

    // MARK: - Code Block

    private func codeBlockView(language: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                Text(language)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(.label))
                    .padding(.horizontal, 12)
                    .padding(.vertical, language.isEmpty ? 10 : 6)
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    // MARK: - Inline code within regular text

    private func inlineCodeText(_ content: String) -> some View {
        let parts = parseInlineCode(content)
        return parts.reduce(Text("")) { result, part in
            switch part {
            case .plain(let s):
                return result + Text(s).font(baseFont)
            case .code(let s):
                return result + Text(s)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(.systemIndigo))
            case .bold(let s):
                return result + Text(s).font(baseFont).bold()
            }
        }
    }

    // MARK: - Parsing

    private enum Segment {
        case text(String)
        case codeBlock(language: String, code: String)
    }

    private enum InlinePart {
        case plain(String)
        case code(String)
        case bold(String)
    }

    private var segments: [Segment] {
        var result: [Segment] = []
        let pattern = "```(\\w*)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [.text(text)]
        }

        let nsText = text as NSString
        var lastEnd = 0
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            let matchRange = match.range
            // Text before this code block
            if matchRange.location > lastEnd {
                let before = nsText.substring(with: NSRange(location: lastEnd, length: matchRange.location - lastEnd))
                result.append(.text(before))
            }
            let language = nsText.substring(with: match.range(at: 1))
            let code = nsText.substring(with: match.range(at: 2))
                .trimmingCharacters(in: .newlines)
            result.append(.codeBlock(language: language, code: code))
            lastEnd = matchRange.location + matchRange.length
        }

        // Remaining text after last code block
        if lastEnd < nsText.length {
            let remaining = nsText.substring(from: lastEnd)
            result.append(.text(remaining))
        }

        if result.isEmpty {
            result.append(.text(text))
        }

        return result
    }

    private func parseInlineCode(_ text: String) -> [InlinePart] {
        var parts: [InlinePart] = []
        // Match inline code `...` and bold **...**
        let pattern = "`([^`]+)`|\\*\\*([^*]+)\\*\\*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [.plain(text)]
        }

        let nsText = text as NSString
        var lastEnd = 0
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            let matchRange = match.range
            if matchRange.location > lastEnd {
                parts.append(.plain(nsText.substring(with: NSRange(location: lastEnd, length: matchRange.location - lastEnd))))
            }
            if match.range(at: 1).location != NSNotFound {
                parts.append(.code(nsText.substring(with: match.range(at: 1))))
            } else if match.range(at: 2).location != NSNotFound {
                parts.append(.bold(nsText.substring(with: match.range(at: 2))))
            }
            lastEnd = matchRange.location + matchRange.length
        }

        if lastEnd < nsText.length {
            parts.append(.plain(nsText.substring(from: lastEnd)))
        }

        if parts.isEmpty {
            parts.append(.plain(text))
        }

        return parts
    }
}

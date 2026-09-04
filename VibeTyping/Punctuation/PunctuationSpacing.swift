import Foundation

/// Restores the whitespace that the CT-Transformer punctuation model discards.
///
/// The model is a per-token tagger: it never rewrites characters, it only decides
/// where a punctuation mark belongs. What it does lose is the original spacing —
/// `用 open mind 的` comes back as `用open mind的`, because the tokenizer strips
/// whitespace at CJK/Latin boundaries before re-joining. Breeze-ASR-25 emits those
/// spaces, so dropping them would trade one formatting regression for another.
///
/// The two strings share a character sequence once whitespace and the newly inserted
/// marks are set aside, which is enough to walk them in lockstep: every character the
/// model kept is matched against the original and carries the original's leading
/// whitespace with it; anything that fails to match is a mark the model added.
enum PunctuationSpacing {

    /// The full-width marks the CT-Transformer model emits. They carry their own
    /// visual spacing, so a space after one of them is wrong in Chinese typography.
    private static let fullWidthMarks: Set<Character> = ["，", "。", "？", "、", "！", "；", "：", "」", "』"]

    /// Re-applies `original`'s whitespace to `punctuated`.
    ///
    /// Falls back to `punctuated` unchanged if the two strings cannot be walked in
    /// lockstep — a model that dropped or rewrote a character would otherwise produce
    /// a silently mangled result, and punctuation without the original spacing is
    /// still the better of the two outcomes.
    static func restore(original: String, punctuated: String) -> String {
        let source = Array(original)
        var result = ""
        result.reserveCapacity(punctuated.count + 8)
        var cursor = 0

        for character in punctuated {
            if character.isWhitespace { continue }

            // Collect whatever whitespace the original holds before its next character.
            var gap = ""
            var probe = cursor
            while probe < source.count, source[probe].isWhitespace {
                gap.append(source[probe])
                probe += 1
            }

            if probe < source.count, source[probe] == character {
                // A mark inserted right where the original had a CJK/Latin space takes
                // that space's place rather than sitting beside it.
                if let previous = result.last, !fullWidthMarks.contains(previous) {
                    result += gap
                }
                result.append(character)
                cursor = probe + 1
            } else {
                // Not in the original at this position — a mark the model inserted.
                // It is emitted before the pending gap so the space lands after it.
                result.append(character)
            }
        }

        // Every non-whitespace character of the original must have been consumed;
        // anything less means the alignment slipped and the result is untrustworthy.
        let remainder = source[cursor...].contains { !$0.isWhitespace }
        return remainder ? punctuated : result
    }
}

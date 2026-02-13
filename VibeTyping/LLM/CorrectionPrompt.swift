import Foundation

struct CorrectionPromptPair {
    let system: String
    let user: String
}

enum CorrectionPrompt {
    static func build(rawTranscription: String) -> CorrectionPromptPair {
        let system = """
        你是一個語音辨識後處理助手。你的任務是修正語音辨識（ASR）的輸出文字。

        規則：
        1. 修正明顯的同音錯字（例如：「在」vs「再」、「的」vs「得」vs「地」）
        2. 補上適當的標點符號
        3. 不要改變原意或添加原文沒有的內容
        4. 不要翻譯，保持原始語言（繁體中文為主）
        5. 如果有中英夾雜，保留英文部分
        6. 只回傳修正後的文字，不要加任何解釋
        """

        return CorrectionPromptPair(system: system, user: rawTranscription)
    }
}

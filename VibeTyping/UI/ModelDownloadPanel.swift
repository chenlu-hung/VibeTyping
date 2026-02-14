import Cocoa

/// A floating panel that shows model download progress.
/// Displayed as a centered window with progress bar and status text.
class ModelDownloadPanel: NSPanel {
    private let statusLabel = NSTextField(labelWithString: "")
    private let progressBar = NSProgressIndicator()
    private let percentLabel = NSTextField(labelWithString: "0%")

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 100),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.title = "VibeTyping"
        self.level = .floating
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false

        setupUI()
        center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = self.contentView else { return }

        // Title label
        let titleLabel = NSTextField(labelWithString: "正在下載語音辨識模型...")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Status label (e.g., "Breeze-ASR-25 (CoreML)")
        statusLabel.stringValue = "Breeze-ASR-25 — 首次使用需下載模型"
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)

        // Progress bar
        progressBar.isIndeterminate = false
        progressBar.minValue = 0
        progressBar.maxValue = 1
        progressBar.doubleValue = 0
        progressBar.style = .bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressBar)

        // Percent label
        percentLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        percentLabel.textColor = .secondaryLabelColor
        percentLabel.alignment = .right
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(percentLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            progressBar.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: percentLabel.leadingAnchor, constant: -8),
            progressBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            percentLabel.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor),
            percentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            percentLabel.widthAnchor.constraint(equalToConstant: 40),
        ])
    }

    /// Update progress (0.0 ~ 1.0). Must be called on main thread.
    func updateProgress(_ fraction: Double) {
        progressBar.doubleValue = fraction
        percentLabel.stringValue = "\(Int(fraction * 100))%"

        if fraction >= 1.0 {
            statusLabel.stringValue = "下載完成，正在載入模型..."
        }
    }

    /// Show a loading state after download completes.
    func showLoadingModel() {
        progressBar.isIndeterminate = true
        progressBar.startAnimation(nil)
        statusLabel.stringValue = "正在載入模型，請稍候..."
        percentLabel.stringValue = ""
    }

    /// Show an error message.
    func showError(_ message: String) {
        progressBar.isHidden = true
        percentLabel.isHidden = true
        statusLabel.stringValue = message
        statusLabel.textColor = .systemRed
    }

    func dismiss() {
        progressBar.stopAnimation(nil)
        orderOut(nil)
    }
}

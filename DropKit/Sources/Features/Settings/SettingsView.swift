import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var showAppPicker = false
    @State private var selectedTab = 0
    @State private var folderSelectionError: String?

    var body: some View {
        VStack(spacing: 0) {
            // 自定义 Tab 选择器
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Shelf").tag(1)
                Text("Clipboard").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 80)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Tab 内容
            Group {
                switch selectedTab {
                case 0:
                    generalTab
                case 1:
                    shelfTab
                case 2:
                    clipboardTab
                default:
                    generalTab
                }
            }
        }
        .frame(width: 520, height: 440)
        .background(.background)
    }

    // MARK: - 通用设置（合并原通用 + 快捷键）

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            } header: {
                Text("Startup")
            }

            Section {
                LabeledContent("Show shelf") {
                    KeyboardShortcuts.Recorder(for: .showShelf)
                }
                LabeledContent("Clipboard history") {
                    KeyboardShortcuts.Recorder(for: .showClipboardHistory)
                }
                LabeledContent("Settings") {
                    KeyboardShortcuts.Recorder(for: .showSettings)
                }
            } header: {
                Text("Keyboard Shortcuts")
            }

            Section {
                LabeledContent("Current version") {
                    Text(Bundle.main.shortVersionString)
                        .foregroundColor(.secondary)
                }

                Text("The App Store version is distributed and updated through the system store.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - 悬浮窗设置（合并原摇晃触发 + 文件夹监听）

    private var shelfTab: some View {
        Form {
            Section {
                LabeledContent("Shake count") {
                    Stepper("\(settings.shakeMinShakes)x", value: $settings.shakeMinShakes, in: 2...8)
                        .frame(width: 100)
                }

                LabeledContent("Time window") {
                    HStack {
                        Slider(value: $settings.shakeTimeWindow, in: 0.2...0.8, step: 0.05)
                            .frame(width: 120)
                        Text("\(String(format: "%.2f", settings.shakeTimeWindow)) s")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                }

                LabeledContent("Min movement") {
                    HStack {
                        Slider(value: $settings.shakeMinMovement, in: 10...60, step: 5)
                            .frame(width: 120)
                        Text("\(Int(settings.shakeMinMovement)) px")
                            .monospacedDigit()
                            .frame(width: 55, alignment: .trailing)
                    }
                }
            } header: {
                Text("Shake Trigger")
            }

            Section {
                Toggle("Enable folder watching", isOn: $settings.folderMonitorEnabled)

                LabeledContent("Folder") {
                    HStack {
                        Text(settings.watchedFolderPath ?? "Not selected")
                            .foregroundColor(settings.watchedFolderPath == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 150, alignment: .leading)
                        Button("Choose...") {
                            selectFolder()
                        }
                    }
                }

                Button("Choose suggested screenshots folder...") {
                    selectFolder(suggestedURL: FolderMonitor.getScreenshotFolderURL())
                }

                if settings.watchedFolderPath != nil {
                    Button("Clear selected folder", role: .destructive) {
                        settings.clearWatchedFolder()
                    }
                }
            } header: {
                Text("Folder Watch")
            } footer: {
                Text("Because of sandboxing, watched folders must be selected and authorized manually.")
            }

            Section {
                Toggle("Automatically copy to clipboard", isOn: $settings.autoCopyToClipboard)
                Toggle("Automatically show shelf", isOn: $settings.autoShowShelfOnNewFile)
            } header: {
                Text("New File Behavior")
            } footer: {
                Text("When a new file appears, copy its path so you can paste it with Command-V.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - 剪切板设置（保持不变）

    private var clipboardTab: some View {
        Form {
            Section {
                LabeledContent("Retention") {
                    HStack(spacing: 4) {
                        TextField("", value: $settings.clipboardRetentionDays, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        Text("days")
                    }
                }

                LabeledContent("Max items") {
                    HStack(spacing: 4) {
                        TextField("", value: $settings.clipboardMaxItems, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        Text("items")
                    }
                }
            } header: {
                Text("History")
            } footer: {
                Text("Use 0 to keep items indefinitely. Limits apply only to non-favorite items.")
            }

            Section {
                Toggle("Ignore password manager content", isOn: $settings.ignoreConcealed)
            } footer: {
                Text("Automatically skips concealed clipboard content. Common password managers are always ignored.")
            }

            Section {
                Toggle("Enable app blacklist", isOn: $settings.clipboardBlacklistEnabled)

                if settings.clipboardBlacklistEnabled {
                    ForEach(Array(settings.clipboardBlacklist).sorted(), id: \.self) { bundleId in
                        HStack {
                            Text(getAppName(for: bundleId) ?? bundleId)
                            Spacer()
                            Button {
                                settings.clipboardBlacklist.remove(bundleId)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("Add app...") {
                        showAppPicker = true
                    }
                }
            } footer: {
                Text("You can manually exclude more apps in addition to the built-in sensitive-app list.")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete all history", systemImage: "trash")
                        Spacer()
                    }
                }

                if showDeleteSuccess {
                    HStack {
                        Spacer()
                        Text("All history deleted")
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Could not save folder access", isPresented: Binding(
            get: { folderSelectionError != nil },
            set: { if !$0 { folderSelectionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(folderSelectionError ?? "Choose another folder and try again.")
        }
        .alert("Confirm Delete", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                ClipboardMonitor.shared.clearAll()
                showDeleteSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showDeleteSuccess = false
                }
            }
        } message: {
            Text("Delete all clipboard history? This cannot be undone.")
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerView(selectedBundleIds: $settings.clipboardBlacklist)
        }
    }

    private func getAppName(for bundleId: String) -> String? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: appURL.path)
        }
        return nil
    }

    private func selectFolder(suggestedURL: URL? = nil) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose the folder to watch"
        panel.directoryURL = suggestedURL

        if panel.runModal() == .OK, let url = panel.url {
            guard settings.setWatchedFolder(url) else {
                folderSelectionError = "DropKit could not save access to that folder."
                return
            }
        }
    }
}

private extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}

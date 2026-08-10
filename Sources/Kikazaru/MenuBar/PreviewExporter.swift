import SwiftUI

/// 設定画面を PNG に書き出す。実際に開かずにレイアウトを確認するための補助。
enum SettingsExporter {

    @MainActor
    static func run(into path: String) async {
        var settings = Settings()
        settings.hotkeyEnabled = true          // 隠れている項目も含めて確認する

        // 実際に検出して、一覧の見え方まで確認できるようにする
        let model = AppModel(action: SpeakersAction())
        await model.refresh()

        let view = SettingsView(settings: settings, model: model) { _ in }

        let renderer = ImageRenderer(content: view.content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            print("書き出しに失敗しました")
            return
        }
        try? png.write(to: URL(fileURLWithPath: path))
        print("書き出しました: \(path)")
    }
}


/// 「このアプリについて」を PNG に書き出す。
enum AboutExporter {

    @MainActor
    static func run(into path: String) {
        let renderer = ImageRenderer(content: AboutView().content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            print("書き出しに失敗しました")
            return
        }
        try? png.write(to: URL(fileURLWithPath: path))
        print("書き出しました: \(path)")
    }
}

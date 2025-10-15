cask "altopin" do
  version "1.2.0"
  sha256 "d24537a77ce3291fedbd11098a9ea75eecd11cdf2b0238309f329937ceb785d9"

  url "https://github.com/jagoff/altopin/releases/download/v#{version}/AlwaysOnTop.app.zip"
  name "AltoPin"
  desc "Pin any window to stay always on top"
  homepage "https://github.com/jagoff/altopin"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :monterey"

  app "AlwaysOnTop.app"

  uninstall quit: "com.altopin.AlwaysOnTop"

  zap trash: [
    "~/Library/Application Support/AlwaysOnTop",
    "~/Library/Caches/com.altopin.AlwaysOnTop",
    "~/Library/Preferences/com.altopin.AlwaysOnTop.plist",
  ]

  caveats <<~EOS
    AltoPin requires Accessibility permissions to function.

    After installation:
    1. Open System Settings → Privacy & Security → Accessibility
    2. Add AlwaysOnTop.app and enable it
    3. Launch the app

    Keyboard shortcut: Control+Cmd+T to pin/unpin the active window
  EOS
end

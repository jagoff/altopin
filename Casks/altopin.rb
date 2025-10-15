cask "altopin" do
  version "1.1.0"
  sha256 :no_check

  url "https://github.com/jagoff/altopin/releases/download/v#{version}/AlwaysOnTop.app.zip"
  name "AltoPin"
  desc "Pin any macOS window to stay always on top"
  homepage "https://github.com/jagoff/altopin"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "AlwaysOnTop.app"

  zap trash: [
    "~/Library/Preferences/com.altopin.AlwaysOnTop.plist",
    "~/Library/Caches/com.altopin.AlwaysOnTop",
  ]
end

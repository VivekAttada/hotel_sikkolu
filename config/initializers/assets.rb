# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path only when present
# (Render production may not keep node_modules after build).
[
  Rails.root.join("node_modules/bootstrap-icons/font"),
  Rails.root.join("node_modules/bootstrap/dist/js")
].each do |path|
  Rails.application.config.assets.paths << path if path.exist?
end

Rails.application.config.assets.precompile << "bootstrap.bundle.min.js"

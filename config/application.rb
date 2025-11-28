require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module SaasTemplate
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.autoload_paths += %W[#{config.root}/app/notifiers]
  end
end

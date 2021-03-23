# frozen_string_literal: true
require_relative "dev_server/config"
require_relative "dev_server/hot_reload"
require_relative "dev_server/ignore_filter"
require_relative "dev_server/header_hash"
require_relative "dev_server/local_assets"
require_relative "dev_server/proxy"
require_relative "dev_server/sse"
require_relative "dev_server/theme"
require_relative "dev_server/uploader"
require_relative "dev_server/watcher"
require_relative "dev_server/web_server"
require_relative "dev_server/certificate_manager"

require "pathname"

module ShopifyCli
  module Theme
    module DevServer
      class << self
        attr_accessor :debug

        def start(root, silent: false, port: 9292)
          config = Config.from_path(root)
          theme = Theme.new(config)
          watcher = Watcher.new(theme)

          # Setup the middleware stack. Mimics Rack::Builder / config.ru, but in reverse order
          @app = Proxy.new(theme)
          @app = LocalAssets.new(@app, theme)
          @app = HotReload.new(@app, theme, watcher)

          puts "Syncing theme ##{config.theme_id} on #{config.store} ..." unless silent
          watcher.start

          unless silent
            puts "Serving #{theme.root}"
            puts "Browse to http://127.0.0.1:#{port}"
            puts "(Use Ctrl-C to stop)"
          end

          trap("INT") do
            stop
          end

          WebServer.run(
            @app,
            Port: port,
            Logger: silent ? WEBrick::Log.new(nil, WEBrick::BasicLog::FATAL) : nil,
            AccessLog: silent ? [] : nil,
          )
          watcher.stop
        end

        def stop
          @app.close
          WebServer.shutdown
        end
      end
    end
  end
end
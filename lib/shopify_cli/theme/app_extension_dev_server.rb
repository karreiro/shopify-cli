# frozen_string_literal: true

require_relative "dev_server_common"
require_relative "dev_server/app_extensions"
require_relative "dev_server/web_server"

require "pathname"

module ShopifyCLI
  module Theme
    module DevServer
      class AppExtensionDevServer < DevServerCommon
        class << self
          def start(ctx, _root, host: "127.0.0.1", _theme: nil, port: 9292, _poll: false)
            @ctx = ctx
            @app = AppExtensions.new
            logger = WEBrick::Log.new(nil, WEBrick::BasicLog::INFO)

            catch_stop_cli_command

            WebServer.run(
              @app,
              BindAddress: host,
              Port: port,
              Logger: logger,
              AccessLog: [],
            )
          end
        end
      end
    end
  end
end

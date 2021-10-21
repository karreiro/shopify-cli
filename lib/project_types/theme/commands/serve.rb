# frozen_string_literal: true
require "shopify_cli/theme/dev_server"

module Theme
  class Command
    class Serve < ShopifyCLI::SubCommand
      DEFAULT_HTTP_BIND = "127.0.0.1"

      options do |parser, flags|
        parser.on("--http-bind=HOST") { |_bind| flags[:http_bind] = http_bind.to_s }
        parser.on("--port=PORT") { |port| flags[:port] = port.to_i }
        parser.on("--poll") { flags[:poll] = true }
      end

      def call(*)
        flags = options.flags.dup
        http_bind = flags[:http_bind] || DEFAULT_HTTP_BIND
        ShopifyCLI::Theme::DevServer.start(@ctx, ".", http_bind: http_bind, **flags) do |syncer|
          UI::SyncProgressBar.new(syncer).progress(:upload_theme!, delay_low_priority_files: true)
        end
      rescue ShopifyCLI::Theme::DevServer::AddressBindingError
        raise ShopifyCLI::Abort,
          ShopifyCLI::Context.message("theme.serve.error.address_binding_error", ShopifyCLI::TOOL_NAME)
      end

      def self.help
        ShopifyCLI::Context.message("theme.serve.help", ShopifyCLI::TOOL_NAME)
      end
    end
  end
end

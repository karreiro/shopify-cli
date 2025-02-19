# frozen_string_literal: true
require "theme_check"

module Theme
  class Command
    class LanguageServer < ShopifyCLI::SubCommand
      def call(*)
        ThemeCheck::LanguageServer.start
      end

      def self.help
        ShopifyCLI::Context.message("theme.language_server.help", ShopifyCLI::TOOL_NAME)
      end
    end
  end
end

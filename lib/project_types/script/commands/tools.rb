# frozen_string_literal: true
require "shopify_cli"

module Script
  class Command
    class Tools < ShopifyCLI::Command
      subcommand :Javy, "javy", Project.project_filepath("commands/tools/javy")

      def self.call(args, command_name, _)
        super(args[1..-1], command_name)
      end

      def call(_args, _name)
        @ctx.puts(self.class.help)
      end

      def self.help
        ShopifyCLI::Context.message("script.tools.help", ShopifyCLI::TOOL_NAME)
      end

      def self.extended_help
        ShopifyCLI::Context.message("script.tools.extended_help", ShopifyCLI::TOOL_NAME)
      end
    end
  end
end

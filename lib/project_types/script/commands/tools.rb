# frozen_string_literal: true
require "shopify_cli"

module Script
  class Command
    class Tools < ShopifyCLI::Command
      prerequisite_task ensure_project_type: :script

      subcommand :Javy, "javy", Project.project_filepath("commands/tools/javy")

      def self.call(args, command_name, _)
        # run_prerequisites
        # new(@ctx).call(args[1..-1], command_name)
        super(args[1..-1], command_name)
      end

      autoload :Javy, Project.project_filepath("commands/tools/javy")

      JAVY = "javy"

      # def call(args, name)
      #   subcommand = args.first
      #   case subcommand
      #   when JAVY
      #     Script::Command::Tools::Javy.ctx = @ctx
      #     Script::Command::Tools::Javy.call(args, JAVY, name)
      #   else
      #     @ctx.puts(self.class.help)
      #   end
      # end

      def self.help
        ShopifyCLI::Context.message("script.tools.help", ShopifyCLI::TOOL_NAME)
      end

      def self.extended_help
        ShopifyCLI::Context.message("script.tools.extended_help", ShopifyCLI::TOOL_NAME)
      end
    end
  end
end

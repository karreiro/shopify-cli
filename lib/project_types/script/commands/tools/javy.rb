# frozen_string_literal: true
require "shopify_cli"
require_relative "../../../../../ext/javy/javy.rb"

module Script
  class Command
    class Tools
      class Javy < ShopifyCLI::SubCommand
        prerequisite_task ensure_project_type: :script

        options do |parser, flags|
          parser.on("--in=IN") { |in_file| flags[:in_file] = in_file }
          parser.on("--out=OUT") { |out_file| flags[:out_file] = out_file }
        end

        def call(_args, _name)
          source = options.flags[:in_file]
          dest = options.flags[:out_file]

          return @ctx.puts(self.class.help) unless source && dest

          ::Javy.build(source: source, dest: dest)
        end

        def self.help
          ShopifyCLI::Context.message("script.tools.javy.help", ShopifyCLI::TOOL_NAME)
        end
      end
    end
  end
end

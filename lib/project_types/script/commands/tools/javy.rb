# frozen_string_literal: true
require "shopify_cli"
require_relative "../../../../../ext/javy/javy.rb"

module Script
  class Command
    class Tools
      class Javy < ShopifyCLI::SubCommand
        options do |parser, flags|
          parser.on("--in=IN") { |in_file| flags[:in_file] = in_file }
          parser.on("--out=OUT") { |out_file| flags[:out_file] = out_file }
        end

        def call(args, name)
          ::Javy.build(source: options.flags[:in_file], dest: options.flags[:out_file])
        end

        def self.help
          ShopifyCLI::Context.message("script.tools.javy.help", ShopifyCLI::TOOL_NAME)
        end
      end
    end
  end
end

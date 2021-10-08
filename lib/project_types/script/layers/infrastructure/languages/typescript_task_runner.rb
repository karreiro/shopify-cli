# frozen_string_literal: true

module Script
  module Layers
    module Infrastructure
      module Languages
        class TypeScriptTaskRunner < TaskRunner
          BYTECODE_FILE = "build/index.wasm"
          SCRIPT_SDK_BUILD = "npm run build"
          GEN_METADATA = "npm run gen-metadata"
          MIN_NPM_VERSION = "5.2.0"
          MIN_NODE_VERSION = "14.15.0"
          REQUIRED_TOOL_VERSIONS = [
            { "tool_name": "npm", "min_version": MIN_NPM_VERSION },
            { "tool_name": "node", "min_version": MIN_NODE_VERSION },
          ]
          INSTALL_COMMAND = "npm install --no-audit --no-optional --legacy-peer-deps --loglevel error"

          attr_reader :ctx, :script_name

          def initialize(ctx, script_name)
            super()
            @ctx = ctx
            @script_name = script_name
          end

          def build
            compile
            bytecode
          end

          private

          def compile
            check_compilation_dependencies!
            CommandRunner.new(ctx: ctx).call(SCRIPT_SDK_BUILD)
            CommandRunner.new(ctx: ctx).call(GEN_METADATA)
          end

          def check_compilation_dependencies!
            pkg = JSON.parse(File.read("package.json"))
            build_script = pkg.dig("scripts", "build")

            raise Errors::BuildScriptNotFoundError,
              "Build script not found" if build_script.nil?

            unless build_script.start_with?("javy")
              raise Errors::InvalidBuildScriptError, "Invalid build script"
            end
          end

          def bytecode
            raise Errors::WebAssemblyBinaryNotFoundError unless ctx.file_exist?(BYTECODE_FILE)

            contents = ctx.binread(BYTECODE_FILE)
            ctx.rm(BYTECODE_FILE)

            contents
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Extension
  module Models
    class DevelopmentServer
      class DevelopmentServerError < StandardError; end

      include SmartProperties

      EXECUTABLE_DIRECTORY = File.join(ShopifyCLI::ROOT, "ext", "shopify-extensions")

      property :executable, converts: :to_s

      def executable
        super || begin
          case RbConfig::CONFIG.fetch("host_os")
          when /(linux)|(darwin)/
            File.join(EXECUTABLE_DIRECTORY, "shopify-extensions")
          else
            File.join(EXECUTABLE_DIRECTORY, "shopify-extensions.exe")
          end
        end
      end

      def executable_installed?
        File.exist?(executable)
      end

      def create(server_config)
        CLI::Kit::System.capture3(executable, "create", "-", stdin_data: server_config.to_yaml)
      rescue StandardError => error
        raise error
      end

      def build(server_config)
        _, error, status = CLI::Kit::System.capture3(executable, "build", "-", stdin_data: server_config.to_yaml)
        return if status.success?
        raise DevelopmentServerError, error
      end

      def serve(context, server_config)
        CLI::Kit::System.popen3(executable, "serve", "-") do |input, out, err, status|
          context.puts("Sending configuration data …")
          input << server_config.to_yaml
          input.close

          forward_output_to_user(out, err, context)

          status.value
        end
      end

      def version
        raise NotImplementedError
      end

      private

      def forward_output_to_user(out, err, ctx)
        ctx.puts("Starting monitoring threads …")

        Thread.new do
          ctx.puts("Ready to process standard output")
          while (line = out.gets)
            ctx.puts(line)
          end
        end

        Thread.new do
          ctx.puts("Ready to process standard error")
          while (error = err.gets)
            ctx.puts(error)
          end
        end
      end
    end
  end
end

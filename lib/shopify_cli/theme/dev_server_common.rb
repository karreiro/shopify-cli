# frozen_string_literal: true

require "pathname"

module ShopifyCLI
  module Theme
    module DevServer
      # Errors
      Error = Class.new(StandardError)
      AddressBindingError = Class.new(Error)

      class DevServerCommon
        class << self
          attr_accessor :ctx, :app, :stopped, :syncer

          def stop
            @stopped = true
            @ctx.puts("Stopping…")
            @app.close unless !@app.respond_to?(:close=)
            @syncer&.shutdown
            WebServer.shutdown
          end

          def catch_stop_cli_command
            trap("INT") do
              stop
            end
          end
        end
      end
    end
  end
end

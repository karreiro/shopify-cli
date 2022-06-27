# frozen_string_literal: true

module ShopifyCLI
  module Theme
    module DevServer
      class AppExtensions
        def call(_env)
          # TODO: use HeaderHash
          headers = {}

          headers["Content-Type"] = "text/plain"
          [200, headers, ["Hello, World!"]]
        end

        def close
          @streams.close
        end
      end
    end
  end
end

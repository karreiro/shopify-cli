# frozen_string_literal: true

require "json"

module ShopifyCLI
  module Theme
    module DevServer
      class ContextualExtension
        def initialize(ctx, app, theme:)
          @ctx = ctx
          @app = app
          @theme = theme
        end

        def call(env)
          if env["PATH_INFO"] == "/contextual-extension"
            return vscode_error unless VSCode.exists?(@ctx)

            section = section_type(env)
            section_file = @theme["sections/#{section}.liquid"]

            return open_file(section_file.absolute_path) if section_file.exist?
          end

          status, headers, body = @app.call(env)

          body = inject_contextual_extension_js(body) if html_request?(headers)

          [status, headers, body]
        end

        private

        def open_file(path)
          VSCode.open_file(@ctx, path)
          response(200, { file: path })
        rescue => error
          response(500, { error: error.message })
        end

        def vscode_error
          # TODO: move to a messages file.
          error = "Visual Studio Code is not instaled. Install it to support contextual features."
          @ctx.puts("{{x}} {{red:#{error}}}")
          response(500, { error: error })
        end

        def section_type(env)
          form_data = URI.decode_www_form(env["rack.input"].read).to_h
          form_data["section"]
        end

        def response(status, body)
          json_body = body.to_json
          [
            status,
            {
              "Content-Type" => "application/json",
              "Content-Length" => json_body.size.to_s,
            },
            [json_body],
          ]
        end

        def html_request?(headers)
          headers["content-type"]&.start_with?("text/html")
        end

        def inject_contextual_extension_js(body)
          js = ::File.read("#{__dir__}/contextual-extension.js")
          css = ::File.read("#{__dir__}/contextual-extension.css")
          html = ::File.read("#{__dir__}/contextual-extension.html")
          js_body = [
            "<style type='text/css'>",
            css,
            "</style>",
            "<script>",
            js,
            "</script>",
            html,
            "</body>"
          ].join("\n")

          body = body.join.gsub("</body>", js_body)

          [body]
        end
      end
    end
  end
end

# frozen_string_literal: true

module ShopifyCLI
  module Theme
    module DevServer
      class LocalAssets
        ASSET_REGEX = %r{//cdn\.shopify\.com/s/.+?/(assets/.+?\.(?:css|js))}
        # FONT_REGEX = %r{https://fonts\.shopifycdn\.com/assistant/(.+\.(?:woff2|woff))}

        class FileBody
          def initialize(path)
            @path = path
          end

          # Naive implementation. Only used in unit tests.
          def each
            yield @path.read
          end

          # Rack will stream a body that responds to `to_path`
          def to_path
            @path.to_path
          end
        end

        def initialize(ctx, app, theme:)
          @ctx = ctx
          @app = app
          @theme = theme
        end

        def call(env)
          if env["PATH_INFO"].start_with?("/assets")
            # Serve from disk
            serve_file(env["PATH_INFO"])
          elsif env["PATH_INFO"].start_with?("/fonts")
            # Server from fonts.shopifycdn
            serve_font(env)
          else
            # Proxy the request, and replace the URLs in the response
            status, headers, body = @app.call(env)
            body = replace_asset_urls(body)
            [status, headers, body]
          end
        end

        def serve_font(env)
          response = request(env["REQUEST_METHOD"],
                             env["PATH_INFO"].gsub(/^\/fonts\//, ''),
                             headers: {
                              'Transfer-Encoding' => 'chunked',
                              'Origin' => "https://cheap-comic-strip-com.myshopify.com",
                              'Referer' => "https://cheap-comic-strip-com.myshopify.com",
                             },
                             query: URI.decode_www_form(env["QUERY_STRING"]).to_h,
                             body_stream: env["rack.input"])

          b =response.body
          
            [
              200,
              {
                "Content-Type" => MimeType.by_filename(env["PATH_INFO"]).to_s,
                "Content-Length" => b.size.to_s,
              },
              [b],
            ]
        end

        def request(method, path, headers: nil, query: {}, form_data: nil, body_stream: nil)
          uri = URI.join("https://fonts.shopifycdn.com/assistant/", path)
          uri.query = URI.encode_www_form(query.merge(_fd: 0, pb: 0))

          Net::HTTP.start(uri.host, 443, use_ssl: true) do |http|
            req_class = Net::HTTP.const_get(method.capitalize)
            req = req_class.new(uri)
            req.initialize_http_header(headers) if headers
            req.set_form_data(form_data) if form_data
            req.body_stream = body_stream if body_stream
            http.request(req)
          end
        end

        # private

        def serve_file(path_info)
          path = @theme.root.join(path_info[1..-1])
          if path.file? && path.readable?
            [
              200,
              {
                "Content-Type" => MimeType.by_filename(path).to_s,
                "Content-Length" => path.size.to_s,
              },
              FileBody.new(path),
            ]
          else
            fail(404, "Not found")
          end
        end

        def fail(status, body)
          [
            status,
            {
              "Content-Type" => "text/plain",
              "Content-Length" => body.size.to_s,
            },
            [body],
          ]
        end

        def replace_asset_urls(body)
          replaced_body = body.join.gsub(ASSET_REGEX) do |match|
            path = Pathname.new(Regexp.last_match[1])
            if @theme.static_asset_paths.include?(path)
              "/#{path}"
            else
              match
            end
          end

          [replaced_body.gsub(/https\:\/\/fonts\.shopifycdn\.com\/assistant\//, '/fonts/')]
        end
      end
    end
  end
end

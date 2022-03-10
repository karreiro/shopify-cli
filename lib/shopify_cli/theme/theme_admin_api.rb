module ShopifyCLI
  module Theme
    class ThemeAdminAPI
      API_VERSION = "unstable"

      attr_reader :ctx, :shop, :theme

      def initialize(ctx, theme = nil)
        @ctx = ctx
        @theme = theme
        @shop = theme&.shop || ShopifyCLI::AdminAPI.get_shop_or_abort(ctx)
      end

      def get(path:, **args)
        rest_request(method: "GET", path: path, **args)
      end

      def put(path:, **args)
        rest_request(method: "PUT", path: path, **args)
      end

      def post(path:, **args)
        rest_request(method: "POST", path: path, **args)
      end

      def delete(path:, **args)
        rest_request(method: "DELETE", path: path, **args)
      end

      private

      def rest_request(**args)
        ShopifyCLI::AdminAPI.rest_request(
          ctx,
          shop: shop,
          api_version: API_VERSION,
          **args.compact
        )
      rescue ShopifyCLI::API::APIRequestForbiddenError,
             ShopifyCLI::API::APIRequestUnauthorizedError
        handle_permissions_error
      end

      def handle_permissions_error
        ensure_user_error = ctx.message("theme.ensure_user_error", shop)
        ensure_user_try_this = ctx.message("theme.ensure_user_try_this")

        ctx.abort(ensure_user_error, ensure_user_try_this)
      end
    end
  end
end

# frozen_string_literal: true

module ShopifyCLI
  ##
  # ShopifyCLI::Git wraps Visual Studio Code features.
  #
  class VSCode
    VISUAL_STUDIO_CODE_PATH = "/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"

    class << self
      def exists?(ctx)
        _output, status = vscode(ctx, ["-v"])
        status.success?
      rescue Errno::ENOENT # Visual Studio Code is not installed
        false
      end

      def open_file(ctx, path)
        output, status = vscode(ctx, ["-r", path])
        status.success?
      end

      private

      def vscode(ctx, opts)
        ctx.capture2e(VISUAL_STUDIO_CODE_PATH, *opts)
      end
    end
  end
end

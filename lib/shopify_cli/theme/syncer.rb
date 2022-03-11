# frozen_string_literal: true
require "thread"
require "json"
require "base64"
require "forwardable"

require_relative "syncer/error_reporter"
require_relative "syncer/standard_reporter"
require_relative "syncer/operation"
require_relative "theme_admin_api"
require_relative "syncer/merger"

module ShopifyCLI
  module Theme
    class Syncer
      extend Forwardable

      QUEUEABLE_METHODS = %i[
        get
        update
        delete
      ]

      attr_reader :checksums
      attr_reader :checksums_mutex
      attr_accessor :include_filter
      attr_accessor :ignore_filter

      def_delegators :@error_reporter, :has_any_error?

      def initialize(ctx, theme:, include_filter: nil, ignore_filter: nil)
        @ctx = ctx
        @theme = theme
        @include_filter = include_filter
        @ignore_filter = ignore_filter
        @error_reporter = ErrorReporter.new(ctx)
        @standard_reporter = StandardReporter.new(ctx)
        @reporters = [@error_reporter, @standard_reporter]

        # Queue of `Operation`s waiting to be picked up from a thread for processing.
        @queue = Queue.new
        # `Operation`s will be removed from this Array completed.
        @pending = []
        # Thread making the API requests.
        @threads = []
        # Mutex used to pause all threads when backing-off when hitting API rate limits
        @backoff_mutex = Mutex.new

        # Mutex used to coordinate changes in the checksums (shared accross all threads)
        @checksums_mutex = Mutex.new

        # Latest theme assets checksums. Updated on each upload.
        @checksums = {}

        # Checksums of assets with errors.
        @error_checksums = []
      end

      def api_client
        @api_client ||= ThemeAdminAPI.new(@ctx, @theme.shop)
      end

      def lock_io!
        @reporters.each(&:disable!)
      end

      def unlock_io!
        @reporters.each(&:enable!)
      end

      def enqueue_updates(files, opts = {})
        files.each { |file| enqueue(:update, file, opts) }
      end

      def enqueue_get(files, opts = {})
        files.each { |file| enqueue(:get, file, opts) }
      end

      def enqueue_deletes(files, opts = {})
        files.each { |file| enqueue(:delete, file, opts) }
      end

      def size
        @pending.size
      end

      def empty?
        @pending.empty?
      end

      def pending_updates
        @pending.select { |op| op.method == :update }.map(&:file)
      end

      def remote_file?(file)
        checksums.key?(@theme[file].relative_path.to_s)
      end

      def wait!
        raise ThreadError, "No syncer threads" if @threads.empty?
        total = size
        last_size = size
        until empty? || @queue.closed?
          if block_given? && last_size != size
            yield size, total
            last_size = size
          end
          Thread.pass
        end
      end

      def fetch_checksums!
        _status, response = api_client.get(
          path: "themes/#{@theme.id}/assets.json"
        )
        update_checksums(response)
      end

      def shutdown
        @queue.close unless @queue.closed?
      ensure
        @threads.each { |thread| thread.join if thread.alive? }
      end

      def start_threads(count = 2)
        count.times do
          @threads << Thread.new do
            loop do
              operation = @queue.pop
              break if operation.nil? # shutdown was called
              perform(operation)
            rescue Exception => e # rubocop:disable Lint/RescueException
              error_suffix = ": #{e}"
              error_suffix += + "\n\t#{e.backtrace.join("\n\t")}" if @ctx.debug?
              report_error(operation, error_suffix)
            end
          end
        end
      end

      def upload_theme!(delay_low_priority_files: false, delete: true, overwrite_json_files: true, &block)
        fetch_checksums!

        delete_files_not_present_locally if delete

        enqueue_updates(@theme.liquid_files)
        enqueue_json_updates(overwrite_json_files)

        if delay_low_priority_files
          # Wait for liquid & JSON files to upload, because those are rendered remotely
          wait!(&block)
        end

        # Process lower-priority files in the background

        # Assets are served locally, so can be uploaded in the background
        enqueue_updates(@theme.static_asset_files)

        unless delay_low_priority_files
          wait!(&block)
        end
      end

      def download_theme!(delete: true, &block)
        fetch_checksums!

        if delete
          # Delete local files not present remotely
          missing_files = @theme.theme_files
            .reject { |file| checksums.key?(file.relative_path) }.uniq
            .reject { |file| ignore_file?(file) }
          missing_files.each do |file|
            @ctx.debug("rm #{file.relative_path}")
            file.delete
          end
        end

        enqueue_get(checksums.keys)

        wait!(&block)
      end

      private

      def delete_files_not_present_locally(overwrite_json_files)
        removed_files = []
        restored_files = []

        # Delete remote non-json-files that are not present locally
        removed_files += @theme
          .theme_files
          .reject(&:json?)
          .select { |file| !present_locally?(file) }
          .map { |file| file.relative_path }

        # Ask if remote json-files not present locally must be removed
        apply_to_all = ApplyToAll.new(@ctx)
        json_files = @theme.json_files.select { |file| !present_locally?(file) }
        json_files.each do |file|
          action = apply_to_all.value || ask_delete_or_restore?(file)
          apply_to_all.apply?(action) if json_files.size > 1

          if overwrite_json_files != false || action == :delete
            removed_files << file
            next
          end

          if action == :restore
            restored_files << file
          end
        end

        enqueue_deletes(removed_files)
        enqueue_get(restored_files)
      end

      def enqueue_json_updates(overwrite_json_files)
        updated_files = []
        outdated_files = []

        # Some files must be uploaded after the other ones
        delayed_config_files = [
          @theme["config/settings_schema.json"],
          @theme["config/settings_data.json"],
        ]

        json_files = @theme.json_files - delayed_config_files + delayed_config_files

        if overwrite_json_files != false
          enqueue_updates(removed_files)
          return
        end

        apply_to_all = ApplyToAll.new(@ctx)
        modified_json_files = json_files.select { |file| !ignore_file?(file) && file_has_changed?(file) }
        modified_json_files.each do |file|

          update_strategy = apply_to_all.value || ask_update_strategy(file)
          apply_to_all.apply?(update_strategy) if modified_json_files.size > 1

          case update_strategy
          when :keep_remote
            enqueue(:get, file)
          when :remote_merge
            enqueue(:update, file, merge: true)
          when :keep_local
            enqueue(:update, file)
          end
        end
      end

      def present_locally?(file)
        checksums.keys.include?(file.relative_path)
      end

      def ask_update_strategy(file)
        Forms::SelectUpdateStrategy.new(file).ask.strategy
      end

      def ask_delete_or_restore?(file)
        Forms::SelectDeleteStrategy.new(@ctx, [], file: file).ask.strategy
      end

      def remote_text_content(file)
        _status, body, _response = api_client.get(
          path: "themes/#{@theme.id}/assets.json",
          query: URI.encode_www_form("asset[key]" => file.relative_path),
        )

        body.dig("asset", "value")
      end

      def asset_update_param(file, merge)
        asset = { key: file.relative_path }

        return asset.merge(attachment: Base64.encode64(file.read)) unless file.text?
        return asset.merge(value: file.read) unless merge
        return asset.merge(value: Merger.merge!(file, remote_text_content(file)))
      end

      def report_error(operation, error_suffix = "")
        @error_checksums << @checksums[operation.file_path]
        @error_reporter.report("#{operation.as_error_message}#{error_suffix}")
      end

      def enqueue(method, file, opts = {})
        raise ArgumentError, "file required" unless file
        raise ArgumentError, "method #{method} cannot be queued" unless QUEUEABLE_METHODS.include?(method)

        operation = Operation.new(@ctx, method, @theme[file], opts)

        # Already enqueued
        return if @pending.include?(operation)

        if ignore_operation?(operation)
          @ctx.debug("ignore #{operation.file_path}")
          return
        end

        if [:update, :get].include?(method) && operation.file.exist? && !file_has_changed?(operation.file)
          is_fixed = !!@error_checksums.delete(operation.file.checksum)
          @standard_reporter.report(operation.as_fix_message) if is_fixed
          return
        end

        @pending << operation
        @queue << operation unless @queue.closed?
      end

      def perform(operation)
        return if @queue.closed?
        wait_for_backoff!
        @ctx.debug(operation.to_s)

        response = send(operation.method, operation.file, operation.options)

        @standard_reporter.report(operation.as_synced_message)

        # Check if the API told us we're near the rate limit
        if !backingoff? && (limit = response["x-shopify-shop-api-call-limit"])
          used, total = limit.split("/").map(&:to_i)
          backoff_if_near_limit!(used, total)
        end
      rescue ShopifyCLI::API::APIRequestError => e
        error_suffix = ":\n  " + parse_api_errors(e).join("\n  ")
        report_error(operation, error_suffix)
      ensure
        @pending.delete(operation)
      end

      def update(file, opts = {})
        merge = opts[:merge]
        asset = asset_update_param(file, merge)

        _status, body, response = api_client.put(
          path: "themes/#{@theme.id}/assets.json",
          body: JSON.generate(asset: asset)
        )

        update_checksums(body)

        file.write(asset[:value]) if merge

        response
      end

      def ignore_operation?(operation)
        path = operation.file_path
        ignore_path?(path)
      end

      def ignore_file?(file)
        path = file.path
        ignore_path?(path)
      end

      def ignore_path?(path)
        ignored_by_ignore_filter?(path) || ignored_by_include_filter?(path)
      end

      def ignored_by_ignore_filter?(path)
        ignore_filter&.ignore?(path)
      end

      def ignored_by_include_filter?(path)
        include_filter && !include_filter.match?(path)
      end

      def get(file, opts = {})
        _status, body, response = api_client.get(
          path: "themes/#{@theme.id}/assets.json",
          query: URI.encode_www_form("asset[key]" => file.relative_path),
        )

        update_checksums(body)

        attachment = body.dig("asset", "attachment")
        if attachment
          file.write(Base64.decode64(attachment))
        else
          content = body.dig("asset", "value")
          content = Merger.merge!(file, content) if opts[:merge]

          file.write(content)
        end

        response
      end

      def delete(file, opts = {})
        _status, _body, response = api_client.delete(
          path: "themes/#{@theme.id}/assets.json",
          body: JSON.generate(asset: {
            key: file.relative_path,
          })
        )
        response
      end

      def update_checksums(api_response)
        api_response.values.flatten.each do |asset|
          next unless asset["key"]
          checksums_mutex.synchronize do
            @checksums[asset["key"]] = asset["checksum"]
          end
        end
        # Generate .liquid asset files are reported twice in checksum:
        # once of generated, once for .liquid. We only keep the .liquid, that's the one we have
        # on disk.
        checksums_mutex.synchronize do
          @checksums.reject! { |key, _| @checksums.key?("#{key}.liquid") }
        end
      end

      def file_has_changed?(file)
        file.checksum != @checksums[file.relative_path]
      end

      def parse_api_errors(exception)
        parsed_body = JSON.parse(exception&.response&.body)
        message = parsed_body.dig("errors", "asset") || parsed_body["message"] || exception.message
        # Truncate to first lines
        [message].flatten.map { |m| m.split("\n", 2).first }
      rescue JSON::ParserError
        [exception.message]
      end

      def backoff_if_near_limit!(used, limit)
        if used > limit - @threads.size
          @ctx.debug("Near API call limit, waiting 2 sec…")
          @backoff_mutex.synchronize { sleep(2) }
        end
      end

      def backingoff?
        @backoff_mutex.locked?
      end

      def wait_for_backoff!
        # Sleeping in the mutex in another thread. Wait for unlock
        @backoff_mutex.synchronize {} if backingoff?
      end
    end
  end
end

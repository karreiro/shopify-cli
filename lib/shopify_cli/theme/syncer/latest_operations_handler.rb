# frozen_string_literal: true

module ShopifyCLI
  module Theme
    class Syncer
      module LastestOperationsHandler
        def track_latest_operations(operation)
          latest_operations_buffer << operation if track_latest_operations?
        end

        def modified_recently?(file)
          now = Time.now
          latest_updated_files = []
          operation = latest_operations_buffer.pop

          while recent_update?(operation, now) && !empty_buffer?
            latest_updated_files << operation.file
            operation = latest_operations_buffer.pop
          end

          latest_updated_files.map(&:relative_path).include?(file.relative_path)
        end

        def clear_latest_operations_buffer
          latest_operations_buffer.clear
        end

        private

        def latest_operations_buffer
          # Queue of with the latest enqueued `Operation`s
          @latest_operations_buffer ||= Queue.new
        end

        def empty_buffer?
          latest_operations_buffer.empty?
        end

        def recent_update?(operation, now)
          return false if operation.method != :update
          seconds_ago = operation.created_at - now
          seconds_ago < @pull_interval
        end

        def track_latest_operations?
          @pull_interval > 0
        end
      end
    end
  end
end

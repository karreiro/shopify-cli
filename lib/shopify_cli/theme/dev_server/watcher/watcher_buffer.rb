# frozen_string_literal: true

require "shopify_cli/thread_pool/job"

module ShopifyCLI
  module Theme
    module DevServer
      class Watcher
        class WatcherBuffer
          def initialize(buffer_interval: 0)
            @buffer_entries = Queue.new
            @buffer_interval = buffer_interval
          end

          ##
          # Add a new enty in the buffer
          def <<(file)
            return unless enabled?
            entry = BufferEntry.new(file)
            @buffer_entries.push(entry)
          end

          ##
          # Returns the latest modified files and clean the buffer
          def latest_modified_files!
            files = latest_modified_files
            clear
            files
          end

          ##
          # Returns the latest modified files
          def latest_modified_files
            return unless enabled?

            now = Time.now
            files = []
            current_entry = @buffer_entries.pop

            while !@buffer_entries.empty? && recent?(current_entry, now)
              files << current_entry.file
              current_entry = @buffer_entries.pop
            end

            files
          end

          def clear
            @buffer_entries.clear
          end

          def enabled?
            @buffer_interval > 0
          end

          private

          def recent?(entry, now)
            seconds_ago = entry.watched_at - now
            seconds_ago < @buffer_interval
          end

          class BufferEntry
            attr_reader :file, :watched_at

            def initialize(file)
              @file = file
              @watched_at = Time.now
            end
          end
        end
      end
    end
  end
end

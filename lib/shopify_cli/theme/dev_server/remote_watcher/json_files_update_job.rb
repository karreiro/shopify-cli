# frozen_string_literal: true

require "shopify_cli/thread_pool/job"

module ShopifyCLI
  module Theme
    module DevServer
      class RemoteWatcher
        class JsonFilesUpdateJob < ShopifyCLI::ThreadPool::Job
          def initialize(theme, syncer, interval)
            super(interval)

            @theme = theme
            @syncer = syncer
          end

          def perform!
            @syncer.fetch_checksums!
            @syncer.enqueue_get(json_files)
          end

          private

          def json_files
            @theme
              .json_files
              .reject { |file| @syncer.pending_updates.include?(file) }
          end
        end
      end
    end
  end
end

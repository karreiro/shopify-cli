# frozen_string_literal: true

require "shopify_cli/thread_pool/job"

module ShopifyCLI
  module Theme
    module DevServer
      class Watcher
        class JsonFilesUpdateJob < ShopifyCLI::ThreadPool::Job
          def initialize(theme, syncer, interval)
            super(interval)

            @theme = theme
            @syncer = syncer
          end

          def perform!
            @syncer.fetch_checksums!
            @syncer.enqueue_get(@theme.json_files, merge: true)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "shopify_cli/thread_pool"

require_relative "json_files_update_job"

module ShopifyCLI
  module Theme
    module DevServer
      class Watcher
        class RemoteListen
          class << self
            def to(theme:, syncer:, interval:)
              new(theme, syncer, interval)
            end
          end

          def start
            return if @thread_pool || !activated?

            @thread_pool = ShopifyCLI::ThreadPool.new
            @thread_pool.schedule(recurring_job)
          end

          def stop
            return unless activated?
            @thread_pool&.shutdown
          end

          private

          def activated?
            @interval > 0
          end

          def initialize(theme, syncer, interval)
            @theme = theme
            @syncer = syncer
            @interval = interval
          end

          def recurring_job
            JsonFilesUpdateJob.new(@theme, @syncer, @interval)
          end
        end
      end
    end
  end
end

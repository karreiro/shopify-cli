# frozen_string_literal: true

require "listen"
require "observer"

require_relative "watcher/remote_listen"

module ShopifyCLI
  module Theme
    module DevServer
      # Watches for file changes and publish events to the theme
      class Watcher
        include Observable

        def initialize(ctx, theme:, syncer:, ignore_filter: nil, poll: false, pull_interval: 0)
          @ctx = ctx
          @theme = theme
          @syncer = syncer
          @ignore_filter = ignore_filter
          @listener = Listen.to(@theme.root, force_polling: poll) do |modified, added, removed|
            changed
            notify_observers(modified, added, removed)
          end
          @remote_listener = RemoteListen.to(theme: @theme, syncer: @syncer, interval: pull_interval)

          add_observer(self, :upload_files_when_changed)
        end

        def start
          @listener.start
          @remote_listener.start
        end

        def stop
          @remote_listener.stop
          @listener.stop
        end

        def upload_files_when_changed(modified, added, removed)
          modified_theme_files = filter_theme_files(modified + added)
          if modified_theme_files.any?
            @syncer.enqueue_updates(modified_theme_files)
          end

          removed_theme_files = filter_remote_files(removed)
          if removed_theme_files.any?
            @syncer.enqueue_deletes(removed_theme_files)
          end
        end

        def filter_theme_files(files)
          files
            .select { |file| @theme.theme_file?(file) }
            .map { |file| @theme[file] }
            .reject { |file| ignore_file?(file) }
        end

        def filter_remote_files(files)
          files
            .select { |file| @syncer.remote_file?(file) }
            .map { |file| @theme[file] }
            .reject { |file| ignore_file?(file) }
        end

        private

        def ignore_file?(file)
          @ignore_filter&.ignore?(file.relative_path.to_s)
        end
      end
    end
  end
end

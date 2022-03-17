# frozen_string_literal: true

require "listen"
require "observer"

require_relative "watcher/remote_listen"
require_relative "watcher/local_files_listener"

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
          @watcher_buffer = WatcherBuffer.new(buffer_interval: pull_interval)
          @listener = Listen.to(@theme.root, force_polling: poll) do |modified, added, removed|
            changed
            notify_observers(modified, added, removed)
          end
          @remote_listener = RemoteListen.to(theme: @theme, syncer: @syncer, watcher: self, interval: pull_interval)

          add_observer(self, :on_local_file_changed)
        end

        def start
          @listener.start
          @remote_listener.start
        end

        def stop
          @remote_listener.stop
          @listener.stop
        end

        def latest_modified_files!
          @watcher_buffer.latest_modified_files!
        end

        def on_local_file_changed(modified, added, removed)
          modified_theme_files = filter_theme_files(modified + added)
          removed_theme_files = filter_remote_files(removed)

          upload_files(modified_theme_files, removed_theme_files)
          buffer_files(modified_theme_files)
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

        def upload_files(modified_files, removed_files)
          @syncer.enqueue_updates(modified_files) if modified_files.any?
          @syncer.enqueue_deletes(removed_files) if removed_files.any?
        end

        def buffer_files(files)
          files.each { |file| @watcher_buffer << file }
        end

        def ignore_file?(file)
          @ignore_filter&.ignore?(file.relative_path.to_s)
        end
      end
    end
  end
end

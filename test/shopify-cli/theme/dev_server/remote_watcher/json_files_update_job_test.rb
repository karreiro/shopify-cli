# frozen_string_literal: true

require "test_helper"
require "shopify_cli/theme/dev_server/remote_watcher/json_files_update_job"

module ShopifyCLI
  module Theme
    module DevServer
      class RemoteWatcher
        class JsonFilesUpdateJobTest < Minitest::Test
          def setup
            super

            interval = 2
            @job = JsonFilesUpdateJob.new(theme, syncer, interval)
          end

          def test_perform
            syncer.expects(:fetch_checksums!)
            syncer.expects(:enqueue_get).with(json_files)

            @job.perform!
          end

          def test_recurring
            assert(@job.recurring?)
            assert_equal(2, @job.interval)
          end

          private

          def theme
            @theme ||= stub(json_files: json_files)
          end

          def json_files
            @json_files ||= [mock, mock, mock]
          end

          def syncer
            @syncer ||= mock
          end
        end
      end
    end
  end
end

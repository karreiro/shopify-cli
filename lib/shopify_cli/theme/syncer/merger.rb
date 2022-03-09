# frozen_string_literal: true

require "tempfile"

module ShopifyCLI
  module Theme
    class Syncer
      class Merger
        class << self
          def merge!(theme_file, new_content)
            remote_file = create_tmp_file(theme_file, new_content)
            remote_path = remote_file.path
            local_path = theme_file.absolute_path

            ShopifyCLI::Git.merge_file(local_path, local_path, remote_path, ["--theirs", "-p"])
          ensure
            remote_file.close! # Remove temporary file on Windows as well
          end

          private

          def create_tmp_file(ref_file, content)
            tmp_file = Tempfile.new(tmp_file_name(ref_file))
            tmp_file.write(content)
            tmp_file.close # Make it ready to merge
            tmp_file
          end

          def tmp_file_name(ref_file)
            "shopify-cli-merge-#{ref_file.name(".*")}"
          end
        end
      end
    end
  end
end

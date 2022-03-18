# frozen_string_literal: true

require "tempfile"

module ShopifyCLI
  module Theme
    class Syncer
      class Merger
        class << self
          ##
          # Merge `theme_file` with the `new_content` by favoring lines from the `new_content`.
          #
          def merge(theme_file, new_content)
            git_merge(theme_file, new_content, ["--theirs", "-p"])
          end

          ##
          # Merge `theme_file` with the `new_content` by relying on the union merge
          #
          def union_merge(theme_file, new_content)
            git_merge(theme_file, new_content, ["--union", "-p"])
          end

          private

          ##
          # Merge theme file (`ShopifyCLI::Theme::File`) with a new content (String),
          # by creating a temporary file based on the `new_content`.
          #
          def git_merge(theme_file, new_content, opts)
            remote_file = create_tmp_file(theme_file, new_content)
            remote_path = remote_file.path
            local_path = theme_file.absolute_path

            ShopifyCLI::Git.merge_file(local_path, local_path, remote_path, opts)
          ensure
            remote_file.close! # Remove temporary file on Windows as well
          end

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

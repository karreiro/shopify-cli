# frozen_string_literal: true

require_relative "forms/apply_to_all"
require_relative "forms/select_update_strategy"

module ShopifyCLI
  module Theme
    class Syncer
      module JsonUpdateHandler
        def enqueue_json_updates(files)
          # Some files must be uploaded after the other ones
          delayed_files = [
            @theme["config/settings_schema.json"],
            @theme["config/settings_data.json"],
          ]

          # Update remote JSON files and delays `delayed_files` update
          files = files
            .-(delayed_files)
            .+(delayed_files)
            .select { |file| !ignore_file?(file) && file_has_changed?(file) }

          if overwrite_json?
            enqueue_updates(files)
          else
            # Handle conflicts when JSON files cannot be overwritten
            handle_update_conflicts(files)
          end
        end

        def handle_update_conflict(file)
          case ask_update_strategy(file)
          when :keep_remote
            enqueue(:get, file)
          when :keep_local
            enqueue(:update, file)
          when :union_merge
            enqueue(:union_merge, file)
          end
        end

        private

        def handle_update_conflicts(files)
          to_get = []
          to_update = []
          to_union_merge = []

          apply_to_all = Forms::ApplyToAll.new(@ctx, files.size)

          files.each do |file|
            update_strategy = apply_to_all.value || ask_update_strategy(file)
            apply_to_all.apply?(update_strategy)

            case update_strategy
            when :keep_remote
              to_get << file
            when :keep_local
              to_update << file
            when :union_merge
              to_union_merge << file
            end
          end

          enqueue_get(to_get)
          enqueue_updates(to_update)
          enqueue_union_merges(to_union_merge)
        end

        def ask_update_strategy(file)
          Forms::SelectUpdateStrategy.ask(@ctx, [], file: file).strategy
        end
      end
    end
  end
end

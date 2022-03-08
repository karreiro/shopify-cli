# frozen_string_literal: true

module ShopifyCLI
  module Theme
    class Syncer
      class ConflictHandler
        attr_reader :operation, :strategy_to_solve

        def initialize(operation)
          @operation = operation
        end

        def merge!

        end

        def ask_to_solve!
          # @strategy_to_solve = select_strategy_to_solve

          # case 
          # when :keep_local
          # when :keep_remote
          # when :auto_merge
          # when :show_diff
          # else
          #   raise "Not supported"
          # end
        end

        def skip_local_updates?
          [:keep_remote, :auto_merge].include?(strategy_to_solve)
        end

        private

        def select_strategy_to_solve
          # :keep_local
          # :keep_remote
          # :auto_merge
          # :show_diff
        end

        def file
          operation.file
        end

        def method
          operation.method
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base_strategy_form"

module ShopifyCLI
  module Theme
    class Syncer
      module Forms
        class SelectUpdateStrategy < BaseStrategyForm
          flag_arguments :file

          protected

          def strategies
            %i[
              keep_remote
              keep_local
              remote_merge
              exit
            ]
          end

          def prefix
            "theme.serve.syncer.forms.update_strategy"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module ShopifyCLI
  module Theme
    class Syncer
      module Forms
        class SelectDeleteStrategy < ShopifyCLI::Form
          attr_accessor :strategy

          STRATEGIES =  %i[
            remove
            restore
            exit
          ]

          flag_arguments :file, :strategies
    
          def ask
            self.strategy = CLI::UI::Prompt.ask(title, allow_empty: false) do |handler|
              strategies.each do |strategy|
                handler.option(as_text(strategy)) { strategy }
              end
            end
          end

          private

          def as_text(strategy)
            ctx.message("theme.serve.syncer.forms.remove_strategy.#{strategy}")
          end
    
          def title
            ctx.message("theme.serve.syncer.forms.remove_strategy.title", file.relative_path)
          end
        end
      end
    end
  end
end

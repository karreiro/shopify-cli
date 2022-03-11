# frozen_string_literal: true

module ShopifyCLI
  module Theme
    class Syncer
      module Forms
        class ApplyToAllForm < ShopifyCLI::Form
          attr_accessor :apply

          def ask
            title = message("title")

            self.apply = CLI::UI::Prompt.ask(title, allow_empty: false) do |handler|
              handler.option(message("yes")) { true }
              handler.option(message("no")) { false }
            end

            self
          end

          def apply?
            apply
          end

          private

          def message(key)
            ctx.message("theme.serve.syncer.forms.apply_to_all.#{key}")
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module ShopifyCLI
  module Theme
    class Syncer
      module Forms
        class BaseStrategyForm < ShopifyCLI::Form
          attr_accessor :strategy

          def ask

            # Line break (otherwise, the question mark from `CLI::UI::Prompt` doesn't line break)
            ctx.puts("\n")

            self.strategy = CLI::UI::Prompt.ask(title(file), allow_empty: false) do |handler|
              strategies.each do |strategy|
                handler.option(as_text(strategy)) { strategy }
              end
            end

            ctx.puts("\n")

            exit(0) if self.strategy == :exit

            self
          end

          protected

          ##
          # List of strategies that populate the form options
          #
          def strategies
            raise "`#{self.class.name}#strategies` must be defined"
          end

          ##
          # Message prefix for the form title and options (strategies).
          # See the methods `title` and `as_text`
          #
          def prefix
            raise "`#{self.class.name}#prefix` must be defined"
          end

          private

          def title(file)
            ctx.message("#{prefix}.title", file.relative_path)
          end

          def as_text(strategy)
            ctx.message("#{prefix}.#{strategy}")
          end
        end
      end
    end
  end
end

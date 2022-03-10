# frozen_string_literal: true

require_relative "apply_to_all_form"

module ShopifyCLI
  module Theme
    class Syncer
      module Forms
        class ApplyToAll
          attr_reader :value

          def initialize(ctx)
            @ctx = ctx
            @value = nil
          end

          def apply?(value)
            return @value unless @value.nil?
            @value = ask.apply?
          end

          private

          def ask
            ApplyToAllForm.ask(@ctx, []).ask
          end
        end
      end
    end
  end
end

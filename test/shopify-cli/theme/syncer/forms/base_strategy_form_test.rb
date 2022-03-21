# frozen_string_literal: true

require "test_helper"
require "shopify_cli/theme/syncer/forms/base_strategy_form"

module ShopifyCLI
  module Theme
    class Syncer
      module Forms
        class BaseStrategyFormTest < Minitest::Test
          def setup
            super
            @form = FakeForm.new(@context, [], {})
          end

          def test_ask
            file = mock

            @form.expects(:file).returns(file)
            @form.expects(:title).with(file).returns("title")

            CLI::UI::Prompt
              .expects(:ask)
              .with("title", allow_empty: false)
              .returns(:strategy1)

            assert_equal :strategy1, @form.ask.strategy
          end

          def test_ask_when_strategy_is_exit
            file = mock

            @form.expects(:file).returns(file)
            @form.expects(:title).with(file).returns("title")
            @form.expects(:exit_cli)

            CLI::UI::Prompt
              .expects(:ask)
              .with("title", allow_empty: false)
              .returns(:exit)

            @form.ask
          end

          def test_title
            file = stub(relative_path: "layout/theme.liquid")
            expected_title = "title"

            @context.expects(:message).with("prefix.title", "layout/theme.liquid").returns(expected_title)
            actual_title = @form.send(:title, file)

            assert_equal(expected_title, actual_title)
          end

          def test_as_text
            expected_text = "text"

            @context.expects(:message).with("prefix.strategy1").returns(expected_text)
            actual_text = @form.send(:as_text, :strategy1)

            assert_equal(expected_text, actual_text)
          end
        end

        class FakeForm < BaseStrategyForm
          attr_reader :file

          def strategies
            %i[
              strategy1
              strategy2
              strategy3
            ]
          end

          def prefix
            "prefix"
          end
        end
      end
    end
  end
end

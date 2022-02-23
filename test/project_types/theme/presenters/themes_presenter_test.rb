# frozen_string_literal: true

require "project_types/theme/test_helper"
require "project_types/theme/presenters/themes_presenter"
require "shopify_cli/theme/theme"

module Theme
  module Presenters
    class ThemesPresenterTest < MiniTest::Test
      def test_all
        ShopifyCLI::Theme::Theme
          .expects(:all)
          .with(ctx, root: root)
          .returns([
            theme(0, role: "live"),
            theme(1, role: "unpublished"),
            theme(2, role: "development"),
            theme(3, role: "unpublished"),
            theme(4, role: "other"),
            theme(5, role: "live"),
            theme(6, role: "development"),
            theme(7, role: "unpublished"),
            theme(8, role: "live"),
            theme(9, role: "development"),
          ])

        presenter = ThemesPresenter.new(ctx, root)

        actual_presenters = presenter.all.map(&:to_s)
        expected_presenters = [
          "{{green:#0}} {{bold:Theme 0 {{green:[live]}}}}",
          "{{green:#5}} {{bold:Theme 5 {{green:[live]}}}}",
          "{{green:#8}} {{bold:Theme 8 {{green:[live]}}}}",
          "{{green:#3}} {{bold:Theme 3 {{yellow:[unpublished]}}}}",
          "{{green:#7}} {{bold:Theme 7 {{yellow:[unpublished]}}}}",
          "{{green:#1}} {{bold:Theme 1 {{yellow:[unpublished]}}}}",
          "{{green:#9}} {{bold:Theme 9 {{blue:[development]}}}}",
          "{{green:#6}} {{bold:Theme 6 {{blue:[development]}}}}",
          "{{green:#2}} {{bold:Theme 2 {{blue:[development]}}}}",
          "{{green:#4}} {{bold:Theme 4 {{italic:[other]}}}}",
        ]

        assert_equal(expected_presenters, actual_presenters)
      end

      private

      def theme(id, attributes = {})
        stub(id: id, name: "Theme #{id}", current_development?: false, **attributes)
      end

      def ctx
        @ctx ||= ShopifyCLI::Context.new
      end

      def root
        @root ||= "."
      end
    end
  end
end

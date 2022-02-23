# frozen_string_literal: true

require "project_types/theme/presenters/themes_presenter"

module Theme
  module Forms
    class Select < ShopifyCLI::Form
      attr_accessor :theme
      flag_arguments :root, :title, :exclude_roles, :include_foreign_developments

      def ask
        self.theme = CLI::UI::Prompt.ask(title, allow_empty: false) do |handler|
          theme_presenters.each do |presenter|
            theme = presenter.theme

            next if exclude_roles&.include?(theme.role)
            next if !include_foreign_developments && theme.foreign_development?

            handler.option(presenter.to_s(:short)) { theme }
          end
        end
      end

      private

      def theme_presenters
        Theme::Presenters::ThemesPresenter.new(ctx, nil).all
      end
    end
  end
end

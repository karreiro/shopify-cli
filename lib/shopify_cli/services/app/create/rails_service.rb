require "semantic/semantic"

module ShopifyCLI
  module Services
    module App
      module Create
        class RailsService < BaseService
          USER_AGENT_CODE = <<~USERAGENT
            module ShopifyAPI
              class Base < ActiveResource::Base
                self.headers['User-Agent'] << " | ShopifyApp/\#{ShopifyApp::VERSION} | Shopify CLI"
              end
            end
          USERAGENT

          DEFAULT_RAILS_FLAGS = %w(--skip-spring)

          attr_reader :name, :organization_id, :shop_domain, :type, :db, :rails_opts, :context

          def initialize(name:, organization_id:, shop_domain:, type:, db:, rails_opts:, context:)
            @name = name
            @organization_id = organization_id
            @shop_domain = shop_domain
            @type = type
            @db = db
            @rails_opts = rails_opts
            @context = context
            super()
          end

          def call
            form = Rails::Forms::Create.ask(context, [], {
              name: name,
              organization_id: organization_id,
              shop_domain: shop_domain,
              type: type,
              db: db,
              rails_opts: rails_opts,
            })

            ruby_version = Ruby.version(context)
            context.abort(context.message("rails.create.error.invalid_ruby_version")) unless
              ruby_version.satisfies?("~>2.5") || ruby_version.satisfies?("~>3.0.0")

            check_node
            check_yarn

            build(form.name, form.db)
            set_custom_ua
            ShopifyCLI::Project.write(
              context,
              project_type: "rails",
              organization_id: form.organization_id,
            )

            api_client = ShopifyCLI::Tasks::CreateApiClient.call(
              context,
              org_id: form.organization_id,
              title: form.title,
              type: form.type,
            )

            ShopifyCLI::Resources::EnvFile.new(
              api_key: api_client["apiKey"],
              secret: api_client["apiSecretKeys"].first["secret"],
              shop: form.shop_domain,
              scopes: "write_products,write_customers,write_draft_orders",
            ).write(context)

            partners_url = ShopifyCLI::PartnersAPI.partners_url_for(form.organization_id, api_client["id"])

            context.puts(context.message("apps.create.info.created", form.title, partners_url))
            context.puts(context.message("apps.create.info.serve", form.name, ShopifyCLI::TOOL_NAME, "rails"))
            unless ShopifyCLI::Shopifolk.acting_as_shopify_organization?
              context.puts(context.message("apps.create.info.install", partners_url, form.title))
            end
          end

          private

          def check_node
            cmd_path = context.which("node")
            if cmd_path.nil?
              context.abort(context.message("rails.create.error.node_required")) unless context.windows?
              context.puts("{{x}} {{red:" + context.message("rails.create.error.node_required") + "}}")
              context.puts(context.message("rails.create.info.open_new_shell", "node"))
              raise ShopifyCLI::AbortSilent
            end

            version, stat = context.capture2e("node", "-v")
            unless stat.success?
              context.abort(context.message("rails.create.error.node_version_failure")) unless context.windows?
              # execution stops above if not Windows
              context.puts("{{x}} {{red:" + context.message("rails.create.error.node_version_failure") + "}}")
              context.puts(context.message("rails.create.info.open_new_shell", "node"))
              raise ShopifyCLI::AbortSilent
            end

            context.done(context.message("rails.create.node_version", version))
          end

          def check_yarn
            cmd_path = context.which("yarn")
            if cmd_path.nil?
              context.abort(context.message("rails.create.error.yarn_required")) unless context.windows?
              context.puts("{{x}} {{red:" + context.message("rails.create.error.yarn_required") + "}}")
              context.puts(context.message("rails.create.info.open_new_shell", "yarn"))
              raise ShopifyCLI::AbortSilent
            end

            version, stat = context.capture2e("yarn", "-v")
            unless stat.success?
              context.abort(context.message("rails.create.error.yarn_version_failure")) unless context.windows?
              context.puts("{{x}} {{red:" + context.message("rails.create.error.yarn_version_failure") + "}}")
              context.puts(context.message("rails.create.info.open_new_shell", "yarn"))
              raise ShopifyCLI::AbortSilent
            end

            context.done(context.message("rails.create.yarn_version", version))
          end

          def build(name, db)
            context.abort(context.message("rails.create.error.install_failure", "rails")) unless install_gem("rails",
              "<6.1")
            context.abort(context.message("rails.create.error.install_failure", "bundler ~>2.0")) unless
              install_gem("bundler", "~>2.0")

            full_path = File.join(context.root, name)
            context.abort(context.message("rails.create.error.dir_exists", name)) if Dir.exist?(full_path)

            CLI::UI::Frame.open(context.message("rails.create.generating_app", name)) do
              new_command = %w(rails new)
              new_command += DEFAULT_RAILS_FLAGS
              new_command << "--database=#{db}"
              new_command += rails_opts.split unless rails_opts.nil?
              new_command << name

              syscall(new_command)
            end

            context.root = full_path

            File.open(File.join(context.root, ".gitignore"), "a") { |f| f.write(".env") }

            context.puts(context.message("rails.create.adding_shopify_gem"))
            File.open(File.join(context.root, "Gemfile"), "a") do |f|
              f.puts "\ngem 'shopify_app', '>=17.0.3'"
            end
            CLI::UI::Frame.open(context.message("rails.create.running_bundle_install")) do
              syscall(%w(bundle install))
            end

            CLI::UI::Frame.open(context.message("rails.create.running_generator")) do
              syscall(%w(rails generate shopify_app --new-shopify-cli-app))
            end

            CLI::UI::Frame.open(context.message("rails.create.running_migrations")) do
              syscall(%w(rails db:create))
              syscall(%w(rails db:migrate RAILS_ENV=development))
            end

            unless File.exist?(File.join(context.root, "config/webpacker.yml"))
              CLI::UI::Frame.open(context.message("rails.create.running_webpacker_install")) do
                syscall(%w(rails webpacker:install))
              end
            end
          end

          def set_custom_ua
            ua_path = File.join("config", "initializers", "user_agent.rb")
            context.write(ua_path, USER_AGENT_CODE)
          end

          def syscall(args)
            args[0] = Gem.binary_path_for(context, args[0])
            context.system(*args, chdir: context.root)
          end

          def install_gem(name, version = nil)
            Gem.install(context, name, version)
          end
        end
      end
    end
  end
end
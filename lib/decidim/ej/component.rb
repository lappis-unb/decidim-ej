# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:ej) do |component|
  component.engine = Decidim::Ej::Engine
  component.admin_engine = Decidim::Ej::AdminEngine
  component.icon = "decidim/ej/icon.svg"

  # component.on(:before_destroy) do |instance|
  #   # Code executed before removing the component
  # end

  # These actions permissions can be configured in the admin panel
  # component.actions = %w()

  component.register_resource(:ej) do |resource|
    resource.model_class_name = "Decidim::Ej::EjClient"
  end

  component.on(:create) do |instance|
    Decidim::Ej::EjClient.create(instance) do
      on(:invalid) { raise "Cannot create client" }
    end
  end

  component.settings(:global) do |settings|
    # Add your global settings
    # Available types: :integer, :boolean
    settings.attribute :host, type: :string, default: "", required: true
    settings.attribute :conversation_id, type: :integer, default: 0, required: true
  end

  # component.settings(:step) do |settings|
  #   # Add your settings per step
  # end

  # component.register_resource(:some_resource) do |resource|
  #   # Register a optional resource that can be references from other resources.
  #   resource.model_class_name = "Decidim::Ej::SomeResource"
  #   resource.template = "decidim/ej/some_resources/linked_some_resources"
  # end

  # component.register_stat :some_stat do |context, start_at, end_at|
  #   # Register some stat number to the application
  # end

  # component.seeds do |participatory_space|
  #   # Add some seeds for this component
  # end
end

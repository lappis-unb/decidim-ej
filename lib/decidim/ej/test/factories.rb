# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  factory :ej_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :ej).i18n_name }
    manifest_name :ej
    participatory_space { create(:participatory_process, :with_steps) }
  end

  # Add engine factories here
end

# frozen_string_literal: true

require "decidim/ej/admin"
require "decidim/ej/engine"
require "decidim/ej/admin_engine"
require "decidim/ej/component"

Decidim.register_global_engine(
  :decidim_ej,
  ::Decidim::Ej::Engine,
  at: "/decidim_ej"
)

module Decidim
  # This namespace holds the logic of the `Ej` component. This component
  # allows users to create ej in a participatory space.
  module Ej
    module Connector
    end
  end
end

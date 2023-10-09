module Decidim
  module Ej
    class EjController < Decidim::Ej::ApplicationController
      def index
        @data = {"comments_count": 4, "votes_count": 334}
      end
    end
  end
end

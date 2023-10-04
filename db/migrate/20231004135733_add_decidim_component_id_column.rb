class AddDecidimComponentIdColumn < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_ej_ej_clients, :decidim_component_id, :integer
  end
end

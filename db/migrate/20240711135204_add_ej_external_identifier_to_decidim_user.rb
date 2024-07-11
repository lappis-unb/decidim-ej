class AddEjExternalIdentifierToDecidimUser < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_users, :ej_external_identifier, :string
  end
end

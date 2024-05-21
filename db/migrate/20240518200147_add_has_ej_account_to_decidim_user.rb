class AddHasEjAccountToDecidimUser < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_users, :has_ej_account, :boolean, default: false, null: false
  end
end

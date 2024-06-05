class AddEjPasswordToDecidimUser < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_users, :ej_password_digest, :string
  end
end

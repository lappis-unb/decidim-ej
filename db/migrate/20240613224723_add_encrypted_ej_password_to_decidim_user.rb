class AddEncryptedEjPasswordToDecidimUser < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_users, :encrypted_ej_password, :string
  end
end

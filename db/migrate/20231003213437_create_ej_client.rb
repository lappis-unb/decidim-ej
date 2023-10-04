class CreateEjClient < ActiveRecord::Migration[6.1]
  def change
     create_table :decidim_ej_ej_clients do |t|
      t.string :host
      t.integer :conversation_id
      t.timestamps
    end
  end
end

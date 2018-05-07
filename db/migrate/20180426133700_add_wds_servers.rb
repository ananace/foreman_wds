class AddWdsServers < ActiveRecord::Migration[4.2]
  def change
    create_table :wds_servers do |t|
      t.string :name, null: false, unique: true
      t.string :description, limit: 255
      t.string :url, limit: 255
      t.string :user, limit: 255
      t.text :password

      t.timestamps
    end
  end
end

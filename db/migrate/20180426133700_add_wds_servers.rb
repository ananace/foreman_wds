class AddWdsServers < ActiveRecord::Migration[4.2]
  def change
    create_table :wds_servers do |t|
      t.string :name, null: false, unique: true
      t.string :description, limit: 255
      t.string :url, limit: 255
      t.string :user, limit: 255
      t.text :password

      t.timestamps null: false
    end

    create_table :wds_facets do |t|
      t.references :host, null: false, foreign_key: true, index: true, unique: true
      t.references :wds_server, foreign_key: true, index: true

      t.string :boot_image_name, limit: 255
      t.string :install_image_name, limit: 255

      t.timestamps null: false
    end
  end
end

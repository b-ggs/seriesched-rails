class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :username
      t.string :showid
      t.string :url

      t.timestamps null: false
    end
  end
end

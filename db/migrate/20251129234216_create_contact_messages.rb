class CreateContactMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :title, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end

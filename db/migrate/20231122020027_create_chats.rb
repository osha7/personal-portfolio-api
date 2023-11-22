class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.string :role
      t.text :content

      t.timestamps
    end
  end
end

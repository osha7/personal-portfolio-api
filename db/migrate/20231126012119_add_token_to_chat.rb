class AddTokenToChat < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :encrypted_token, :string
  end
end

class CreateAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :account_invitations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :account_invitations, :token, unique: true
    add_index :account_invitations, [ :account_id, :email ], unique: true
  end
end

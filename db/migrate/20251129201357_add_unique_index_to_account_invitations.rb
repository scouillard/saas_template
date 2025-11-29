class AddUniqueIndexToAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    remove_index :account_invitations, :email
    add_index :account_invitations, [ :account_id, :email ], unique: true
  end
end

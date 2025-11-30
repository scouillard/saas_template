class AddStripeFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :subscription_status, :string
    add_column :accounts, :current_period_ends_at, :datetime
  end
end

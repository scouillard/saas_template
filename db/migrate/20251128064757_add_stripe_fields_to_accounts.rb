class AddStripeFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :subscription_status, :string, default: "none"
    add_column :accounts, :stripe_price_id, :string
  end
end

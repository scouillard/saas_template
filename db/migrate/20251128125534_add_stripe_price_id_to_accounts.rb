class AddStripePriceIdToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :stripe_price_id, :string
  end
end

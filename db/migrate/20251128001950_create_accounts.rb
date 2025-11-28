class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :plan, null: false, default: "free"
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.datetime :subscription_started_at
      t.datetime :subscription_ends_at

      t.timestamps
    end

    add_index :accounts, :stripe_customer_id, unique: true
    add_index :accounts, :stripe_subscription_id
    add_index :accounts, :plan
  end
end

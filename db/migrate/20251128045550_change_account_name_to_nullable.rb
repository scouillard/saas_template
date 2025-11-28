class ChangeAccountNameToNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :accounts, :name, true
  end
end

class ConvertUserRolesColumnToText < ActiveRecord::Migration[4.2]
  def up
    change_column :user_roles, :users, :text
  end

  def down
    change_column :user_roles, :users, :string
  end
end

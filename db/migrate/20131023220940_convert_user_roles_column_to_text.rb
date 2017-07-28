# frozen_string_literal: true
class ConvertUserRolesColumnToText < ActiveRecord::Migration
  def up
    change_column :user_roles, :users, :text
  end

  def down
    change_column :user_roles, :users, :string
  end
end

# frozen_string_literal: true

class AddWeightToObjectFile < ActiveRecord::Migration
  def change
    add_column :object_files, :weight, :integer, default: 0
  end
end

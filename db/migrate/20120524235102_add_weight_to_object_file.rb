class AddWeightToObjectFile < ActiveRecord::Migration[4.2]
  def change
    add_column :object_files, :weight, :integer, default: 0
  end
end

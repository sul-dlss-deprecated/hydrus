class AddHideToObjectFile < ActiveRecord::Migration[4.2]
  def change
    add_column(:object_files, :hide, :boolean, default: false)
  end
end

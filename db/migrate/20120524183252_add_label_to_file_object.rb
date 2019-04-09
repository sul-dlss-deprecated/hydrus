class AddLabelToFileObject < ActiveRecord::Migration[4.2]
  def change
    add_column :object_files, :label, :string, default: ''
  end
end

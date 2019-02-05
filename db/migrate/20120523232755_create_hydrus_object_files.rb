class CreateHydrusObjectFiles < ActiveRecord::Migration[4.2]
  def change
    create_table(:object_files) do |t|
      t.string :pid, null: false, default: ''
      t.string :file, null: false, default: ''
      t.timestamps
    end
    add_index :object_files, :pid
  end
end

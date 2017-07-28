# frozen_string_literal: true
class AddLabelToFileObject < ActiveRecord::Migration
  def change
    add_column :object_files, :label, :string, default: ''
  end
end

# -*- encoding : utf-8 -*-
# frozen_string_literal: true
class RemoveEditableFieldsFromBookmarks < ActiveRecord::Migration
  def self.up
    remove_column :bookmarks, :notes
    remove_column :bookmarks, :url
  end

  def self.down
    add_column :bookmarks, :notes, :text
    add_column :bookmarks, :url, :string
  end
end

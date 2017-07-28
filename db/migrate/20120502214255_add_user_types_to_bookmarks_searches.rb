# -*- encoding : utf-8 -*-
# frozen_string_literal: true

class AddUserTypesToBookmarksSearches < ActiveRecord::Migration
  def self.up
    add_column :searches, :user_type, :string
    add_column :bookmarks, :user_type, :string
    Search.reset_column_information
    Bookmark.reset_column_information
    Search.update_all("user_type = 'user'")
    Bookmark.update_all("user_type = 'user'")
  end

  def self.down
    remove_column :searches, :user_type, :string
    remove_column :bookmarks, :user_type, :string
  end
end

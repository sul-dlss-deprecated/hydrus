class CreateDefaultUser < ActiveRecord::Migration
  def up
    unless Rails.env.production?
      User.find_all_by_email('archivist1@example.com').each { |u| u.destroy }
      User.create(:email=>'archivist1@example.com',:password=>'beatcal')
    end
  end

  def down
    unless Rails.env.production?
      User.find_all_by_email('archivist1@example.com').each { |u| u.destroy }
    end
  end
end

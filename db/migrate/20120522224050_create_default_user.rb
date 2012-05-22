class CreateDefaultUser < ActiveRecord::Migration
  def up
    unless Rails.env.production?
      User.create(:email=>'archivist1@example.com',:password=>'beatcal')
    end
  end

  def down
    unless Rails.env.production?
      User.find_by_email('archivist1@example.com').destroy
    end
  end
end

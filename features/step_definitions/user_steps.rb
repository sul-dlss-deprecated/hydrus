Given /^I (?:am )?log(?:ged)? in as "([^\"]*)"$/ do |email|
  # Given %{a User exists with a Login of "#{login}"}
  user = User.find_by_email(email) 
  unless user
    user = User.create(:email=>email,:password=>"beatcal")  
  end
  visit destroy_user_session_path
  visit new_user_session_path
  fill_in "Email", :with => email 
  fill_in "Password", :with => "beatcal"
  click_button "Sign in"
end

Given /^I am on the home page$/ do
  visit "/"
end

When /^I am viewing "([^"]*)"$/ do |object_id|
  visit catalog_path(object_id)
  # visit catalog_path(CGI.escape object_id)
  # visit "/catalog/#{CGI.escape object_id}"
end

 
Then /^I should not see "([^"]*)"$/ do |text|
  page.should_not have_content text
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content text
end

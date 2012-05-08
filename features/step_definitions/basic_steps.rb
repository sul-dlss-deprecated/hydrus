
Given /^I am on the home page$/ do
  visit "/"
end

When /^I am viewing "([^"]*)"$/ do |object_id|
  visit "/catalog/#{object_id}"
#  pending # express the regexp above with the code you wish you had
end

 
Then /^I should not see "([^"]*)"$/ do |text|
  page.should_not have_content text
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content text
end

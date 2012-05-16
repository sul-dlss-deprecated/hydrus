
# steps for paths/routes

Given /^I am on the home page$/ do
  visit "/"
end

When /^I am viewing collection "([^"]*)"$/ do |object_id|
  visit dor_collection_path(object_id)
end

When /^I am viewing item "([^"]*)"$/ do |object_id|
  visit dor_item_path(object_id)
end



When /^I am viewing "([^"]*)"$/ do |object_id|
  visit catalog_path(object_id)
end


# steps to work with page content

Then /^I should not see "([^"]*)"$/ do |text|
  page.should_not have_content text
end

Then /^I should see "([^"]*)"$/ do |text|
  page.should have_content text
end

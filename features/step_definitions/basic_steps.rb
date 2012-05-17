
# steps for paths/routes

When /^I am viewing collection "([^"]*)"$/ do |object_id|
  visit dor_collection_path(object_id)
end

When /^I am editing collection "([^"]*)"$/ do |object_id|
  visit edit_dor_collection_path(object_id)
end

When /^I am viewing item "([^"]*)"$/ do |object_id|
  visit dor_item_path(object_id)
end

When /^I am editing item "([^"]*)"$/ do |object_id|
  visit edit_dor_item_path(object_id)
end

When /^I am viewing "([^"]*)"$/ do |object_id|
  visit catalog_path(object_id)
end

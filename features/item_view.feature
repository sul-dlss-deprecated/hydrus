Feature: Item view
  I want the item show page to reflect Hydrus expectations

  Scenario: Item description is displayed
		When I am viewing item "druid:oo000oo0001"
		Then I should see "The story of Pinocchio"
		And I should see "oo000oo0001"
    And I should see "Title:"
    And I should see "Object type"
    And I should see "item"
    And I should see "Publisher"

  Scenario: Default labels should be overridden
		When I am viewing "druid:oo000oo0001"
		Then I should not see "Download"

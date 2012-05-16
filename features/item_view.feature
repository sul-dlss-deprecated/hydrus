Feature: Item view
  I want the item show page to reflect Hydrus expectations

  Scenario: Item description is displayed
		When I am viewing item "druid:pv309jn3099"
		Then I should see "STATISTICAL MOMENT EQUATIONS FOR FORWARD"
		And I should see "pv309jn3099"
    And I should see "Title:"
    And I should see "Object type"
    And I should see "Publisher"
    And I should see "FooBar Publishing Inc."
    And I should see "item"

  Scenario: Default labels should be overridden
		When I am viewing "druid:sw909tc7852"
		Then I should not see "Download"

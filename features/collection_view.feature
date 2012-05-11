Feature: Collection view
  I want the collection show page to reflect Hydrus expectations

  Scenario: Collection description (mods:abstract) is displayed
		When I am viewing collection "druid:sw909tc7852"
		Then I should see "The Electronic Theses and Dissertations colleciton"
		And I should see "sw909tc7852"
    And I should see "Title:"
    And I should see "collection"
    And I should see "set"

  Scenario: Default labels should be overridden
		When I am viewing "druid:sw909tc7852"
		Then I should not see "Download"

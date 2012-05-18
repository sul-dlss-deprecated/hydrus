Feature: Collection view
  I want the collection show page to reflect Hydrus expectations

  Scenario: Collection description is displayed
		When I am viewing collection "druid:oo000oo0003"
		Then I should see "The Electronic Theses and Dissertations colleciton"
		And I should see "oo000oo0003"
    And I should see "Title:"
    And I should see "collection"

  Scenario: Default labels should be overridden
		When I am viewing "druid:oo000oo0003"
		Then I should not see "Download"

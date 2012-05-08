Feature: Collection view
	I want the collection show page to reflect Hydrus expectations

@wip
  Scenario: Collection description (mods:abstract) is displayed
		When I am viewing "druid:sw909tc7852"
		Then I should see "The Electronic Theses and Dissertations colleciton"

@wip
  Scenario: Default labels should be overridden
		When I am viewing "druid:sw909tc7852"
		Then I should not see "Download"

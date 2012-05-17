Feature: Collection edit
  Collection editing should work.

  Scenario: Collection is edited
		When I am editing collection "druid:sw909tc7852"
    Then I should not see "foobarfubb"
    And I fill in "Abstract" with "foobarfubb"
    And I press "Save"
    Then I should see "foobarfubb"
    Then I should be on the collection page "druid:sw909tc7852"

  Scenario: Clean up
		When I am editing collection "druid:sw909tc7852"
    And I fill in "Abstract" with "The Electronic Theses and Dissertations colleciton"
    And I press "Save"

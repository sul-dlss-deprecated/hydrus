Feature: Collection edit
  Collection editing should work.

  Scenario: Collection is edited
		When I am editing collection "druid:oo000oo0003"
    Then I should not see "foobarfubb"
    And I fill in "Abstract" with "foobarfubb"
    And I press "Save"
    Then I should see "foobarfubb"
    Then I should be on the collection page "druid:oo000oo0003"

  Scenario: Clean up
		When I am editing collection "druid:oo000oo0003"
    And I fill in "Abstract" with "The Electronic Theses and Dissertations colleciton"
    And I press "Save"

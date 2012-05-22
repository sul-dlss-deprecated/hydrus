Feature: Collection edit
  Collection editing should work.

  Scenario: Unauthorized collection edit
		When I am editing collection "druid:oo000oo0003"
		Then I should see "Sign in"
		
  Scenario: Collection is edited
    Given I am logged in as "archivist1@example.com" 
		When I am editing collection "druid:oo000oo0003"
    Then I should not see "foobarfubb"
    And I fill in "Abstract" with "foobarfubb"
    And I press "Save"
    Then I should see "foobarfubb"
    Then I should be on the collection page "druid:oo000oo0003"

  Scenario: Clean up
    Given I am logged in as "archivist1@example.com" 
		When I am editing collection "druid:oo000oo0003"
    And I fill in "Abstract" with "The Electronic Theses and Dissertations colleciton"
    And I press "Save"

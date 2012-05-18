Feature: Item edit
  Item editing should work.

  Scenario: Item is edited
		When I am editing item "druid:oo000oo0001"
    Then I should not see "abcxyz123"
    And I fill in "Publisher" with "abcxyz123"
    And I press "Save"
    Then I should see "abcxyz123"
    Then I should be on the item page "druid:oo000oo0001"

  Scenario: Clean up
		When I am editing item "druid:oo000oo0001"
    And I fill in "Publisher" with "FooBar Publishing Inc."
    And I press "Save"

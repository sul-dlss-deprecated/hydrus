Feature: Item edit
  Item editing should work.

  Scenario: Item is edited
		When I am editing item "druid:oo000oo0001"
    Then I should not see "abcxyz123"
    And I fill in "Publisher" with "abcxyz123"
    And I press "Save"
    Then I should see "abcxyz123"
    Then I should be on the item page "druid:oo000oo0001"

  Scenario: People/Role editing
    When I am editing item "druid:oo000oo0001"
    Then the "asset_descMetadata_name_namePart_0" field should contain "Rosenfeld, Michael J."
    And I should see "Principal Investigator"
    When I fill in "asset_descMetadata_name_namePart_0" with "MY EDITIED PERSON"
    And I select "Collector" from "asset_descMetadata_name_role_roleTerm_0"
    When I press "Save"
    Then I should see "MY EDITIED PERSON"
    And I should see "Collector"
    And I should not see "Rosenfeld, Michael J."
    And I should not see "Principal Investigator"

  Scenario: Clean up
		When I am editing item "druid:oo000oo0001"
    And I fill in "Publisher" with "FooBar Publishing Inc."
    And I fill in "asset_descMetadata_name_namePart_0" with "Rosenfeld, Michael J."
    And select "Principal Investigator" from "asset_descMetadata_name_role_roleTerm_0"
    And I press "Save"

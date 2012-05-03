Feature: Home page
  I want the home page to reflect Hydrus localizations properly

	Scenario: home page text
		When I am on the home page
		Then I should not see "override"
		And I should see "Hydrus"

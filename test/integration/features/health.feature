@health
Feature: API proxy health
	As API administrator
	I want to ensure basic functionality is working
    So I can demonstrate the solution.
    
	@get-oas
    Scenario: Verify the Open API Spec is returned
        Given I set X-APIKey header to `clientId`
		When I GET /openapi
        Then response code should be 200
        And response header Content-Type should be application/json
        And response body path $.openapi should be 3.0.3
        And response body path $.info.version should be 0.0.1
        And response body path $.info.title should be Product Recommendations

    @sleep
    Scenario: Wait for 6 seconds to avoid triggering spike arrest of 10pm
        Given I wait 6000 milli-seconds
        
	@get-products
    Scenario: Verify the backend service is responding
        Given I set X-APIKey header to `clientId`
        And I set Cach-Control header to no-cache
		When I GET /products
        Then response code should be 200
        And response header Content-Type should be application/json
        And response body path $.products should be of type array
        

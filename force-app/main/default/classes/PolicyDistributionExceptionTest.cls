/**
* @description This class is used to test the PolicyDistributionException.
**/
@isTest(seealldata=false)
private with sharing class PolicyDistributionExceptionTest {
	
	/**
	*	@description : Test Product Name method
	**/
	@isTest static void testProductAreaException_ProductName() {
        ComplianceException pdException = new PolicyDistributionException('Mock Exception Message 1');
        system.assertEquals('Compliance',pdException.getProductName());
    }

    /**
	*	@description : Test Product Area method
	**/
    @isTest static void testProductAreaException_ProductArea() {
        ComplianceException pdException = new PolicyDistributionException('Mock Exception Message 1');
        system.assertEquals('Policy Distribution',pdException.getProductArea());
    }
}
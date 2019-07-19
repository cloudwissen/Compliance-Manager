/**
* @description This class is used to test Compliance Exception.
**/
@isTest(seealldata=false)
private with sharing class ComplianceExceptionTest {
	
	/**
	*	@description : Test Product Name method
	**/
	@isTest static void testProductAreaException_ProductName() {
        ComplianceException complianceException = new ComplianceException('Mock Exception Message 1');
        System.assertEquals('Compliance',complianceException.getProductName());
    }

    /**
	*	@description : Test Product Area method
	**/
    @isTest static void testProductAreaException_ProductArea() {
        ComplianceException complianceException = new ComplianceException('Mock Exception Message 1');
        System.assertEquals('Unknown',complianceException.getProductArea());
    }

    /**
	*	@description : Test Exception getExceptionString method 
	**/
    @isTest static void testComplianeException_ThrowSalesforceException() {
		try{
			Database.query('select Unknown_Field__c from Account');
		}catch(Exception ex){
			ComplianceException complianceException = new ComplianceException(ex.getMessage());
			System.assertEquals('Compliance',complianceException.getProductName());
			System.assertEquals('Unknown',complianceException.getProductArea());
			System.assertNotEquals('Unknown',complianceException.getMessage());
			System.assertNotEquals('Unknown',complianceException.getStackTraceString());
			String exceptionString = complianceException.getExceptionString();
			System.assert(exceptionString.contains('Product:  Compliance'));
			System.assert(exceptionString.contains('Area:  Unknown'));
			System.assert(exceptionString.contains('Cause:  Unknown'));
			System.assert(exceptionString.contains('Message:  ' + ex.getMessage()));
		}

    }

    /**
	*	@description : Test Exception addPageMessage method 
	**/
    @isTest static void testComplianeException_addPageMessage() {
		ComplianceException complianceException = new ComplianceException();
    	System.assertEquals(false, ApexPages.hasMessages(), 'Current page should not have messages');
    	complianceException.addPageMessage();
    	System.assertEquals(true, ApexPages.hasMessages(), 'Current page should have messages');
    	System.assertEquals(1, ApexPages.getMessages().size(), 'Expected only single message');
    }

    /**
	*	@description : Test Exception setSeverity method 
	**/
    @isTest static void testComplianeException_setSeverity() {
		ComplianceException complianceException = new ComplianceException();
    	// Severity changed
    	complianceException.severity = ApexPages.Severity.WARNING;
    	// Severity in page message should reflect severity
    	System.assertEquals(ApexPages.Severity.WARNING, complianceException.severity, 'Unexpected severity');
    	System.assertEquals(ApexPages.Severity.WARNING, complianceException.getPageMessage().getSeverity(), 'Expected severity INFO');
    }
}
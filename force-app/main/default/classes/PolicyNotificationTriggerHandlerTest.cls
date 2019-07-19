/**
* @description Test class for policy notitication trigger handler
**/
@isTest(seeAllData=false)
private with sharing class PolicyNotificationTriggerHandlerTest {

	private static List<User> usersList;

	/**
	*	@description : Set up test data
	**/
	@testSetup
	static void setUpTestData(){
		// create policies 
		List<grc__Policy__c> policiesToCreate = new List<grc__Policy__c>{new grc__Policy__c(Name = 'Test Policy 1')};
		insert policiesToCreate;

		// Create policy Version
		List<Policy_Version__c> policyVersionsList = new List<Policy_Version__c>{new Policy_Version__c(Policy__c=policiesToCreate[0].Id)};
		insert policyVersionsList;

		policiesToCreate = [SELECT Id FROM grc__Policy__c];
        System.assertEquals(1, policiesToCreate.size(), 'One Policy must be created.');   
        policyVersionsList = [SELECT Id FROM Policy_Version__c];
        System.assertEquals(1, policyVersionsList.size(), 'One Policy Version must be created.');  
	}

	/**
	*   @description Test afterInsert method.
	**/
	@isTest 
	static void test_afterInsert(){
		Test.startTest();
		List<Policy_Version__c> policyVersionsList = [SELECT Id, Policy__r.OwnerId FROM Policy_Version__c];
		// create notified users
		List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>{new Policy_Notification__c(Policy_Version__c=policyVersionsList[0].Id,OwnerId=UserInfo.getUserId(),Policy_Read__c=false)};
		insert policyNotificationsList;
		// check share record for policy owner
		System.assertEquals(1,[SELECT count() FROM Policy_Notification__Share WHERE RowCause =: PolicyNotificationHelper.POLICY_OWNER_APEX_SHARING_REASON AND UserOrGroupId =: policyVersionsList[0].Policy__r.OwnerId],'There should be a share record for policy owner');
		Test.stopTest();
	}
}

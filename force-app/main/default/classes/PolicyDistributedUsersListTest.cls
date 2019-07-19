/**
*	@description : Test Class for PolicyDistributedUsersListController
**/
@isTest(seeAllData=false)
private with sharing class PolicyDistributedUsersListTest {
	
	/**
	*	@description : Set up test data
	**/
	static void setUpTestData(){
		// create policies 
		List<grc__Policy__c> policiesToCreate = new List<grc__Policy__c>{new grc__Policy__c(Name = 'Test Policy 1')};
		insert policiesToCreate;

		// Create policy Version
		List<Policy_Version__c> policyVersionsList = new List<Policy_Version__c>{new Policy_Version__c(Policy__c=policiesToCreate[0].Id)};
		insert policyVersionsList;

		// create notified users
		List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>{new Policy_Notification__c(Policy_Version__c=policyVersionsList[0].Id,OwnerId=UserInfo.getUserId(),Policy_Read__c=false)};
		insert policyNotificationsList;
	}

	/**
	*	@description : Test getUsersList method
	**/
    @isTest
	static void test_getUsersList(){
		Test.startTest();
		setUpTestData();
		// get policies
		List<grc__Policy__c> policiesList = [SELECT Id FROM grc__Policy__c LIMIT 1];
		List<String> fds = new List<String>{'Id','Name','CreatedDate'};
		PolicyDistributedUsersListController.sObjectFieldsList = new List<Schema.SObjectField>();
		for(String fd : fds) {
			String objectName = Policy_Notification__c.sObjectType.getDescribe().getName();
			PolicyDistributedUsersListController.sObjectFieldsList.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fd));
		}
		Map<String, Object> objectsMap = PolicyDistributedUsersListController.getUsersList(policiesList[0].Id,'test');
		System.assertNotEquals(null, objectsMap, 'The objects map should be initialised and have value');
		List<XLC.DataTableField> dataTableFieldsList = (List<XLC.DataTableField>)objectsMap.get('columns');
		List<sObject> recordsList = (List<sObject>)objectsMap.get('data');
		System.assertEquals(3,dataTableFieldsList.size(), 'The size of the dataTableFieldsList should be 3');
		System.assertEquals(1,recordsList.size(), 'The size of the recordsList should be 1');
		Test.stopTest();
	}
    
    /**
	*	@description : Test getNotifiedUsers method.
	**/
	@isTest
	private static void test_getNotifiedUsers() {
		setUpTestData();
		List<Policy_Version__c> policyVersionsList = [SELECT Id FROM Policy_Version__c LIMIT 1];
		Test.startTest();
        
        List<String> fds = new List<String>{'Id','Name','CreatedDate'};
		PolicyDistributedUsersListController.sObjectFieldsList = new List<Schema.SObjectField>();
		for(String fd : fds) {
			String objectName = Policy_Notification__c.sObjectType.getDescribe().getName();
			PolicyDistributedUsersListController.sObjectFieldsList.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fd));
		}
        
		//test positive case
		List<sObject> plUsers = PolicyDistributedUsersListController.getNotifiedUsers(policyVersionsList[0].Id);
		System.assertEquals(1, plUsers.size(), 'Expecting a single policy distribution user record.');
		//test negative case
        try {
			plUsers = PolicyDistributedUsersListController.getNotifiedUsers(null);            
        }catch(Exception ex) {
            System.assertNotEquals(null, ex);
        }
		Test.stopTest();
	}
    
   	/**
	*	@description : Test getColumn method
	**/
    @isTest
	static void test_getColumn(){
		Test.startTest();
		List<String> fds = new List<String>{'Id','Name','CreatedDate'};
		PolicyDistributedUsersListController.sObjectFieldsList = new List<Schema.SObjectField>();
		for(String fd : fds) {
			String objectName = Policy_Notification__c.sObjectType.getDescribe().getName();
			PolicyDistributedUsersListController.sObjectFieldsList.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fd));
		}
		System.assertEquals(3, PolicyDistributedUsersListController.getColumns().size(), 'The size of the dataTableFieldsList should be 3');
		Test.stopTest();
	}
    /**
	*	@description : Test getColumn method without any fields
	**/
 	@isTest
	static void test_getColumnWithoutFields(){
		Test.startTest();
        PolicyDistributedUsersListController.sObjectFieldsList = new List<Schema.SObjectField>();
		System.assertEquals(0,PolicyDistributedUsersListController.getColumns().size(), 'The size of the columns should always be 0.');
		Test.stopTest();
	}

    /**
	*	@description : Test getFields method
	**/
    @isTest
	static void test_getFields(){
		Test.startTest();
		List<String> fds = new List<String>{'Id','Name','CreatedDate'};
		PolicyDistributedUsersListController.sObjectFieldsList = new List<Schema.SObjectField>();
		for(String fd : fds) {
			String objectName = Policy_Notification__c.sObjectType.getDescribe().getName();
			PolicyDistributedUsersListController.sObjectFieldsList.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fd));
		}
		System.assertEquals(3, PolicyDistributedUsersListController.getFields().size(), 'The size of the dataTableFieldsList should be 3');
		Test.stopTest();
	}

    /**
	*	@description : Test getFields method without any fields
	**/
 	@isTest
	static void test_getFieldsWithoutFields(){
		Test.startTest();
        PolicyDistributedUsersListController.sObjectFieldsList = new List<Schema.SObjectField>();
		System.assertEquals(0, PolicyDistributedUsersListController.getFields().size(), 'The size of the fields should be 0 since no fields been set');
		Test.stopTest();
	}

	/**
	*	@description : Test sendNotifications method
	**/
 	@isTest
	static void test_sendNotifications(){
		Test.startTest();
		setUpTestData();
		// get policy notifications 
		List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Send_Notification__c FROM Policy_Notification__c];
		// check assert before sending notification
		System.assertEquals(0,[SELECT count() FROM Policy_Notification__c WHERE Send_Notification__c =: true],'Sent notification should be zero');
		// call send notifications method
		PolicyDistributedUsersListController.sendNotifications(JSON.serialize(new Map<Id, Policy_Notification__c>(policyNotificationsList).keySet()),'Test Message');
		// check assert after sending notification
		// workflow will set the send notification to false.
		System.assertEquals(0,[SELECT count() FROM Policy_Notification__c WHERE Send_Notification__c =: true],'Sent notification should be zero again');
		Test.stopTest();
	}

	/**
	*	@description : Test removeNotifiedUser method
	**/
 	@isTest
	static void test_removeNotifiedUser(){
		Test.startTest();
		setUpTestData();
		// get policy notifications 
		List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Send_Notification__c FROM Policy_Notification__c];
		// check assert before delete
		System.assertEquals(1,policyNotificationsList.size(),'There should be one policy notification record.');
		// call removeNotifiedUser method
		PolicyDistributedUsersListController.removeNotifiedUser(policyNotificationsList[0].Id);
		// check assert after delete
		policyNotificationsList = [SELECT Id, Send_Notification__c FROM Policy_Notification__c];
		System.assertEquals(0,policyNotificationsList.size(),'There should be no policy notification record.');
		Test.stopTest();
	}
}
/**
 * @description Test Class for PolicyTriggerHandler Trigger
 **/
@isTest(SeeAllData = false)
private with sharing class PolicyTriggerHandlerTest {

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

		// create notified users
		List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>{new Policy_Notification__c(Policy_Version__c=policyVersionsList[0].Id,OwnerId=UserInfo.getUserId(),Policy_Read__c=false)};
		insert policyNotificationsList;

		policiesToCreate = [SELECT Id FROM grc__Policy__c];
        System.assertEquals(1, policiesToCreate.size(), 'One Policy must be created.');   
        policyVersionsList = [SELECT Id FROM Policy_Version__c];
        System.assertEquals(1, policyVersionsList.size(), 'One Policy Version must be created.');  
		policyNotificationsList = [SELECT Id FROM Policy_Notification__c];
		System.assertEquals(1, policyNotificationsList.size(), 'One Policy Notification must be created.');
	}

	/**
	 * @description Method to update Policy
	 * @return	  grc__Policy__c
	 **/
	static grc__Policy__c updatePolicy() {
		grc__Policy__c policy = new grc__Policy__c(Name = 'P1');
		insert policy;
		List<ContentDocumentLink> cdl = createContentDocument(policy.Id);
		policy.Content_Document_Id__c = cdl[0].ContentDocumentId;
		update policy;
		return policy;
	}
	/**
	 * @description Method to create policy content documents
	 * @return	  List of ContentDocumentLink
	 **/
	static List<ContentDocumentLink> createContentDocument(Id policyId) {
		// create content documents 
		List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
		insert contentVersionsList;
		 // get content document id
		contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
		// create content document links 
		List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policyId,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
		insert contentDocumentLinksList;
		return contentDocumentLinksList;
	}
	/**
	 * @description Method to test create a new policy
	 **/
	@isTest static void updateExistingPolicy() {
		grc__Policy__c newPolicy = UpdatePolicy();
		System.Assert(newPolicy.Content_Document_Id__c != null, 'Content Document has been associated with policy');
	}
}

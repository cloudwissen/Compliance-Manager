/**
*	@description : Test Class for content version trigger handler
**/
@isTest(seeAllData=false)
private with sharing class ContentVersionTriggerHandlerTest {
	
	/**
	*	@description : Set up test data
	**/
	@testSetup
	static void setUpTestData(){
		// create policies 
		List<grc__Policy__c> policiesToCreate = new List<grc__Policy__c>{new grc__Policy__c(Name='Test Policy - 1')};
		insert policiesToCreate;
		policiesToCreate = [SELECT Id FROM grc__Policy__c];
		System.assertEquals(1, policiesToCreate.size(), 'One Policy must be created.');
	}

	/**
	*	@description : test content version trigger
	**/
	@isTest static void test_contentTriggerHandler(){
		Test.startTest();
		// check before inserting file 
		System.assertEquals(0,[SELECT count() FROM Policy_Version__c],'No policy version record created.');
		// get policies
		List<grc__Policy__c> policiesList = [SELECT Id, Content_Document_Id__c FROM grc__Policy__c LIMIT 1]; 
		// create content documents 
		List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
		insert contentVersionsList;
		// get content document id
		contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
		// create content document links 
		List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policiesList[0].Id,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
		insert contentDocumentLinksList;
        // update content document ids to policy 
        policiesList[0].Content_Document_Id__c = contentVersionsList[0].ContentDocumentId;
        update policiesList;

        // check after updating inserting file 
		System.assertEquals(1,[SELECT count() FROM Policy_Version__c],'A policy version record created.');
		Test.stopTest();
	}
}
/**
*	@description : Test Class for content version trigger helper
**/
@isTest(seeAllData=false)
public with sharing class ContentVersionHelperTest {
	
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
	*	@description : Test fetchContentDocumentIdByContentVersionMap method
	**/
	@isTest static void test_fetchContentDocumentIdByContentVersionMap(){
		Test.startTest();
		// create content documents 
		List<ContentVersion> contentVersionsList =  new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
		insert contentVersionsList;
		// call fetch document methods
		System.assertEquals(1,ContentVersionHelper.fetchContentDocumentIdByContentVersionMap(contentVersionsList).size(),'Map size must be equals 1');
		Test.stopTest();
	}

	/**
	*	@description : Test getLinkedEntityIds method
	**/
	@isTest static void test_getLinkedEntityIds(){
		Test.startTest();
		List<grc__Policy__c> policiesList = [SELECT Id FROM grc__Policy__c LIMIT 1]; 
		// create content documents 
		List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
		insert contentVersionsList;
		// get content document id
		contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
		// create content document links 
		List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policiesList[0].Id,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
		insert contentDocumentLinksList;
		// call fetch document methods
		System.assertEquals(1,ContentVersionHelper.getLinkedEntityIds(new Set<String>{grc__Policy__c.sObjectType.getDescribe().getName()},new Set<Id>{contentVersionsList[0].ContentDocumentId}).size(),'Size must be equals 1');
		Test.stopTest();
	}

    /**
	*	@description : Test getPolicyVersionsMap method
	**/
	@isTest static void test_getPolicyVersionsMap(){
		Test.startTest();
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

        Map<Id, ContentVersion> contentDocumentByContentVersionMap = ContentVersionHelper.fetchContentDocumentIdByContentVersionMap(contentVersionsList);
        Map<Id,Integer> policyVersionsMap = ContentVersionHelper.getPolicyVersionsMap(new Set<Id>{policiesList[0].Id},contentDocumentByContentVersionMap);
        System.assertEquals(1,policyVersionsMap.size(),'Map size should be 1.');
        System.assert(policyVersionsMap.containsKey(policiesList[0].Id),'Map should contains policy id');
        System.assert(policyVersionsMap.get(policiesList[0].Id) == 1,'Policy version should equals 1.');
		Test.stopTest();
	}

    /**
	*	@description : Test getContentDocumentIdsFromPolicies method
	**/
	@isTest static void test_getContentDocumentIdsFromPolicies(){
		Test.startTest();
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

        Map<Id,Id> contentDocumentByPoliciesMap = ContentVersionHelper.getContentDocumentIdsFromPolicies(new Set<Id>{policiesList[0].Id});
        System.assertEquals(1,contentDocumentByPoliciesMap.size(),'Map size should be 1.');
        System.assert(contentDocumentByPoliciesMap.containsKey(contentVersionsList[0].ContentDocumentId),'Map should contains content document id');
		Test.stopTest();
	}

	/**
	*	@description : Test createPolicyVersion method
	**/
	@isTest static void test_createPolicyVersion(){
		Test.startTest();
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

        Map<Id, ContentVersion> contentDocumentByContentVersionMap = ContentVersionHelper.fetchContentDocumentIdByContentVersionMap(contentVersionsList);
        Map<Id,Integer> policyVersionsMap = ContentVersionHelper.getPolicyVersionsMap(new Set<Id>{policiesList[0].Id},contentDocumentByContentVersionMap);
        System.assertEquals(1,[SELECT count() FROM Policy_Version__c],'A policy version record created for this content verison');
        // create policy version
        ContentVersionHelper.createPolicyVersion(policyVersionsMap);
        System.assertEquals(2,[SELECT count() FROM Policy_Version__c],'Another policy version record should be created for this content verison');
		Test.stopTest();
	}
}
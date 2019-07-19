/**
* @description Test class for policy version trigger handler
**/
@isTest(seeAllData=false)
private with sharing class PolicyVersionTriggerHandlerTest {
   
    /**
    *    @description : Set up test data
    **/
    @testSetup
    static void setUpTestData(){
        // create policies 
        List<grc__Policy__c> policiesToCreate = new List<grc__Policy__c>{new grc__Policy__c(Name = 'Test Policy 1')};
        insert policiesToCreate;

        policiesToCreate = [SELECT Id FROM grc__Policy__c];
        System.assertEquals(1, policiesToCreate.size(), 'One Policy must be created.');   
    } 

    /**
	*	@description : Test createPolicyNotifications method
	**/
    @isTest static void test_createPolicyNotifications(){
        Test.startTest();
        System.assertEquals(0,[SELECT count() FROM Policy_Notification__c],'No notification records created.');
        // get policies 
        List<grc__Policy__c> policiesList = [SELECT Id FROM grc__Policy__c];
        // create policy share
        PolicyDistributionHelper.createPolicyShares(policiesList[0].Id,new Set<Id>{UserInfo.getUserId()});
        // create policy version 
        List<Policy_Version__c> policyVersionsList = new List<Policy_Version__c>{new Policy_Version__c(Policy__c=policiesList[0].Id)};
        insert policyVersionsList;
        System.assertEquals(1,[SELECT count() FROM Policy_Notification__c],'A notification record created for a current user.');
        Test.stopTest();
    }

     /**
	*	@description : Test deleteContentDocuments method
	**/
    @isTest static void test_deleteContentDocuments(){
        Test.startTest();
        List<grc__Policy__c> policiesList = [SELECT Id, Content_Document_Id__c  FROM grc__Policy__c];
        // create content documents 
        List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
        insert contentVersionsList;
        // get content document id
        contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
        // create content document links 
        List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policiesList[0].Id,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
        insert contentDocumentLinksList;
        // update policy with content document ids
        policiesList[0].Content_Document_Id__c = contentVersionsList[0].ContentDocumentId;
        update policiesList;
        // get policies 
        policiesList = [SELECT Id, Content_Document_Id__c  FROM grc__Policy__c];
        System.assertEquals(contentVersionsList[0].ContentDocumentId,policiesList[0].Content_Document_Id__c,'Content document id should be populated in policy record.');
        System.assertEquals(1,[SELECT count() FROM ContentDocument],'There should be one content document.');
        // get policy versions
        List<Policy_Version__c> policyVersionsList =  [SELECT Id, Policy__c FROM Policy_Version__c];
        delete policyVersionsList;
        policiesList = [SELECT Id, Content_Document_Id__c FROM grc__Policy__c];
        System.assertEquals(null,policiesList[0].Content_Document_Id__c,'Content document id must be null');
        System.assertEquals(0,[SELECT count() FROM ContentDocument],'There should be no content document.');
        Test.stopTest();
    }

}

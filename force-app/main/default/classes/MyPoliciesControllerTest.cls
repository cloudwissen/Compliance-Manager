/**
*    @description : Test Class for MyPoliciesController
**/
@isTest(seeAllData=false)
private with sharing class MyPoliciesControllerTest {

    /**
    *    @description : Set up test data
    **/
    @testSetup
    static void setUpTestData(){
        // create policies 
        List<grc__Policy__c> policiesToCreate = new List<grc__Policy__c>{new grc__Policy__c(Name = 'Test Policy 1')};
        insert policiesToCreate;

        // create policy share
        PolicyDistributionHelper.createPolicyShares(policiesToCreate[0].Id,new Set<Id>{UserInfo.getUserId()});

        // create content documents 
        List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
        insert contentVersionsList;

        // get content document id
        contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
        // create content document links 
        List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policiesToCreate[0].Id,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
        insert contentDocumentLinksList;

        // update policy with content document ids
        policiesToCreate[0].Content_Document_Id__c = contentVersionsList[0].ContentDocumentId;
        update policiesToCreate;

        policiesToCreate = [SELECT Id,Content_Document_Id__c FROM grc__Policy__c];
        System.assertEquals(1, policiesToCreate.size(), 'One Policy must be created.');
        System.assertNotEquals(null, policiesToCreate[0].Content_Document_Id__c, 'Content Document Id on policy must be populated.');
        contentVersionsList = [SELECT Id FROM ContentVersion];
        System.assertEquals(1, contentVersionsList.size(), 'One Content Version must be created.');
        contentDocumentLinksList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId =: policiesToCreate[0].Id];
        System.assertEquals(1, contentDocumentLinksList.size(), 'One Content Document Link must be created.');
    }

    /**
    *    @description : Test getMyPolicies method
    **/
    @isTest static void test_getMyPolicies(){
        Test.startTest();
        System.assertEquals(3,MyPoliciesController.getMyPolicies().size());
        System.assertEquals(grc__Policy__c.Name.getDescribe().getLabel(),(String)MyPoliciesController.getMyPolicies().get('fieldlabel'));
        
        List<Policy_Notification__c> unreadPoliciesList = (List<Policy_Notification__c>)MyPoliciesController.getMyPolicies().get('Unread');
        System.assertEquals(1,unreadPoliciesList.size());
        
        List<Policy_Notification__c> readPoliciesList = (List<Policy_Notification__c>)MyPoliciesController.getMyPolicies().get('Read');
        System.assertEquals(0,readPoliciesList.size());
        
        // update read status
        List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Policy_Read__c, Date_Policy_Read__c FROM Policy_Notification__c LIMIT 1];
        MyPoliciesController.setPolicyRead(policyNotificationsList[0].Id);
        
        // check read list
        readPoliciesList = (List<Policy_Notification__c>)MyPoliciesController.getMyPolicies().get('Read');
        System.assertEquals(1,readPoliciesList.size());
        Test.stopTest();
    }

    /**
    *    @description : Test getDocuments method
    **/
    @isTest static void test_getDocuments(){
        Test.startTest();
        
        // get policies list 
        List<grc__Policy__c> policiesList = [SELECT Id, Name FROM grc__Policy__c LIMIT 1];
        System.assertEquals(2,MyPoliciesController.getDocuments(policiesList[0].Id).size());
        System.assertEquals(policiesList[0].Name,(String)MyPoliciesController.getDocuments(policiesList[0].Id).get('policyname'));
        Set<Id> documentIds = (Set<Id>)MyPoliciesController.getDocuments(policiesList[0].Id).get('documentIds');
        System.assertEquals(1,documentIds.size());
        
        Test.stopTest();
    }

    /**
    *    @description : Test setPolicyRead method
    **/
    @isTest static void test_setPolicyRead(){
        Test.startTest();
        
        // get policies list 
        List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Policy_Read__c, Date_Policy_Read__c FROM Policy_Notification__c LIMIT 1];
        
        // before setting the read attribute
        System.assert(!policyNotificationsList[0].Policy_Read__c);
        System.assertEquals(null,policyNotificationsList[0].Date_Policy_Read__c);
        
        // set the read equals true
        MyPoliciesController.setPolicyRead(policyNotificationsList[0].Id);
        
        // after setting the read attribute
        policyNotificationsList = [SELECT Id, Policy_Read__c, Date_Policy_Read__c FROM Policy_Notification__c LIMIT 1];
        System.assert(policyNotificationsList[0].Policy_Read__c);
        System.assertEquals(System.today(),policyNotificationsList[0].Date_Policy_Read__c);
        
        Test.stopTest();
    }

    /**
    *    @description : Test getListView method
    **/
    @isTest static void test_getListView(){
        Test.startTest();
        List<ListView> listViewsList = [SELECT Id, DeveloperName FROM ListView WHERE SobjectType =: Policy_Notification__c.sObjectType.getDescribe().getName() LIMIT 1];
        if(!listViewsList.isEmpty()){
            Map<String, Object> objectsMap = MyPoliciesController.getListView(listViewsList[0].DeveloperName);
            System.assertEquals(2,objectsMap.size());
            System.assertEquals(listViewsList[0].Id,(Id)objectsMap.get('listviewid'));
            System.assertEquals(Policy_Notification__c.sObjectType.getDescribe().getName(),(String)objectsMap.get('sobjectname'));
        }
        Test.stopTest();
    }
    
}

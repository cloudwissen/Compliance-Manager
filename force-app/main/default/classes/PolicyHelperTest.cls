/**
*    @description : Test Class for PolicyHelper
**/
@isTest(seeAllData=false)
private with sharing class PolicyHelperTest {
    private static User testUser;
    private static PermissionSet ps;
    private static ObjectPermissions objPermission;
    private static FieldPermissions fieldPermission;
    private static List<User> usersList;

    /**
    *    @description : Set up test data
    **/
    @testSetup
    static void setUpTestData(){
        grc__Policy__c policy = new grc__Policy__c(Name = 'P2');
        insert policy;

        // create content documents 
        List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
        insert contentVersionsList;
         // get content document id
        contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
        // create content document links 
        List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policy.Id,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
        insert contentDocumentLinksList;

        Set<Id> contentIds = new Set<Id>();
        for (ContentVersion contentVersion : contentVersionsList) {
            contentIds.add(contentVersion.ContentDocumentId);           
        }
        policy.Content_Document_Id__c = contentDocumentLinksList[0].ContentDocumentId;
        update policy;

        Policy_Version__c pv = new Policy_Version__c(Policy__c=policy.Id,Version__c=1);
        insert pv;

        System.assertEquals(1, [SELECT Id FROM grc__Policy__c ].size());
    }

    /**
    *    @description : create test users
    **/
    static void createUsers(){
        usersList = new List<User>();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        for(Integer i=0;i<1;i++){
            usersList.add(new User(firstname = 'Test '+String.valueOf(i),
                                lastName = 'Test '+String.valueOf(i),
                                email = uniqueName + '@test'+String.valueOf(i)+orgId+'.org',
                                Username = uniqueName + '@test'+String.valueOf(i)+orgId+'.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = uniqueName.substring(18, 23),
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = profileId));
        }
        insert usersList;
    }

    /**
    *   @description Test getChangedDocumentIdPolicies method.
    **/
    @isTest 
    static void test_getChangedDocumentIdPolicies(){
        List<grc__Policy__c> newPolicies = [SELECT Id, Content_Document_Id__c FROM grc__Policy__c LIMIT 1];

        Map<Id,grc__Policy__c> oldPoliciesMap = new Map<Id,grc__Policy__c>(newPolicies.deepClone(true, false, false));
        oldPoliciesMap.get(newPolicies[0].Id).Content_Document_Id__c = null;

        Test.startTest();

        Set<Id> policyIds = PolicyHelper.getChangedDocumentIdPolicies(oldPoliciesMap, newPolicies);
        System.assertEquals(1, policyIds.size());
        System.assertEquals(true, policyIds.contains(newPolicies[0].Id));
        System.assertEquals(true, PolicyHelper.contentDocumentIds.contains(newPolicies[0].Content_Document_Id__c));

        Test.stopTest();
    }

    /**
    *   @description Test validatePolicyDocumentIds method.
    **/
    @isTest 
    static void test_validatePolicyDocumentIds(){
        List<grc__Policy__c> newPolicies = [SELECT Id, Content_Document_Id__c FROM grc__Policy__c LIMIT 1];

        Map<Id,grc__Policy__c> oldPoliciesMap = new Map<Id,grc__Policy__c>(newPolicies.deepClone(true, false, false));
        newPolicies[0].Content_Document_Id__c = null;

        Test.startTest();

        Set<Id> policyIds = PolicyHelper.getChangedDocumentIdPolicies(oldPoliciesMap, newPolicies);
        try {
            PolicyHelper.validatePolicyDocumentIds(oldPoliciesMap, newPolicies, policyIds);
        }catch(Exception ex) {
            System.assertNotEquals(null, ex);
        }

        Test.stopTest();
    }

    /**
    *   @description Test getContentDocumentWithVersions method.
    **/
    @isTest 
    static void test_getContentDocumentWithVersions(){
        Test.startTest();
        Set<Id> contentIds = new Set<Id>();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion];
        for (ContentVersion contentVersion : contentVersions) {
            contentIds.add(contentVersion.ContentDocumentId);           
        }
        PolicyHelper.contentDocumentIds = contentIds;
        Map<Id, ContentDocument> contentDocs = PolicyHelper.getContentDocumentWithVersions();
        ContentVersion contentVer = contentDocs.get(contentVersions[0].ContentDocumentId).ContentVersions;

        System.assertEquals(1, contentDocs.size(), 'Expected 1 content document to be returned');
        System.assertNotEquals(null, contentVer, 'Expected a content version to be returned');
        System.assertEquals('1', contentVer.VersionNumber, 'Expected version number to be 1');
        Test.stopTest();
    }

    /**
    *   @description Test getContentDocumentWithVersions method no content ids set.
    **/
    @isTest 
    static void test_getContentDocumentWithVersionsNoContentIds(){
        Test.startTest();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion];
        Map<Id, ContentDocument> contentDocs = PolicyHelper.getContentDocumentWithVersions();
        
        System.assertEquals(null, contentDocs, 'Expected null to be returned');
        Test.stopTest();
    }

    /**
    *   @description Test createPolicyVersion method.
    **/
    @isTest 
    static void test_createPolicyVersion(){
        Test.startTest();
        List<grc__Policy__c> policiesList = [SELECT Id, Name, Content_Document_Id__c FROM grc__Policy__c];
        Set<Id> changedContentDocumentPolicies = new Set<Id>();
        changedContentDocumentPolicies.add(policiesList[0].Id);

        Set<Id> contentIds = new Set<Id>();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion];
        for (ContentVersion contentVersion : contentVersions) {
            contentIds.add(contentVersion.ContentDocumentId);           
        }
        PolicyHelper.contentDocumentIds = contentIds;

        PolicyHelper.createPolicyVersion(policiesList, changedContentDocumentPolicies);
        List<Policy_Version__c> policyVersions = [SELECT Id, Policy__c, Version__c FROM Policy_Version__c WHERE Policy__c =: policiesList[0].Id];

        System.assertEquals(3, policyVersions.size(), 'Expected 3 policy version to be returned');
        Test.stopTest();
    }

    /**
    *   @description Test getContentDocumentLinks method.
    **/
    @isTest 
    static void test_getContentDocumentLinks(){
        Test.startTest();
        Set<Id> contentIds = new Set<Id>();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion];
        for (ContentVersion contentVersion : contentVersions) {
            contentIds.add(contentVersion.ContentDocumentId);           
        }
        PolicyHelper.contentDocumentIds = contentIds;
        Set<String> sObjectTypesList = new Set<String>();
        sObjectTypesList.add('grc__Policy__c');

        List<grc__Policy__c> newPolicies = [SELECT Id, Content_Document_Id__c FROM grc__Policy__c LIMIT 1];

        Map<Id, contentDocumentLink> docLinks = PolicyHelper.getContentDocumentLinks(sObjectTypesList);
        contentDocumentLink cdl = docLinks.get(newPolicies[0].Id);

        System.assertEquals(1, docLinks.size(), 'Expected 1 content document link to be returned');
        System.assertEquals(newPolicies[0].Id, cdl.LinkedEntityId, 'Expected linked entity id to be ' + newPolicies[0].Id);
        Test.stopTest();
    }

    /**
    *   @description Test updateContentDocumentShareType method.
    **/
    @isTest 
    static void test_updateContentDocumentShareType(){
        Test.startTest();
        Set<Id> contentIds = new Set<Id>();
        List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion];
        for (ContentVersion contentVersion : contentVersions) {
            contentIds.add(contentVersion.ContentDocumentId);           
        }
        PolicyHelper.contentDocumentIds = contentIds;

        Set<String> sObjectTypesList = new Set<String>();
        sObjectTypesList.add('grc__Policy__c');

        Map<Id, contentDocumentLink> docLinks = PolicyHelper.getContentDocumentLinks(sObjectTypesList);
        List<grc__Policy__c> newPolicies = [SELECT Id, Content_Document_Id__c FROM grc__Policy__c LIMIT 1];
        Map<Id,sObject> policyMap = new Map<Id,sObject>();
        policyMap.put(newPolicies[0].Id, newPolicies[0]);

        PolicyHelper.updateContentDocumentShareType(policyMap, docLinks);

        List<ContentDocumentLink> contentDocumentLinksListAfter = [SELECT ContentDocumentId, LinkedEntityId, ShareType FROM ContentDocumentLink
                                                                   WHERE ContentDocumentId IN: contentIds LIMIT 50000];

        System.assertEquals(2, contentDocumentLinksListAfter.size(), 'Expected 2 content document links to be returned');
        System.assertEquals('I', contentDocumentLinksListAfter[0].ShareType, 'Expected share type to have been updated to I');
        System.assertEquals('I', contentDocumentLinksListAfter[1].ShareType, 'Expected share type to have been updated to I');
        Test.stopTest();
    }

    /**
    *   @description Test updatePolicyOwnersOnPolicyNotificationShares method.
    **/
    @isTest 
    static void test_updatePolicyOwnersOnPolicyNotificationShares(){
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            Test.startTest();
            createUsers();
            List<grc__Policy__c> newPoliciesList = [SELECT Id, Name, OwnerId, Content_Document_Id__c FROM grc__Policy__c LIMIT 1];
            List<grc__Policy__c> oldPoliciesList = [SELECT Id, Name, OwnerId, Content_Document_Id__c FROM grc__Policy__c LIMIT 1];
            Map<Id, grc__Policy__c> oldPoliciesMap = new Map<Id, grc__Policy__c>();

            Set<Id> changedContentDocumentPolicies = new Set<Id>();
            changedContentDocumentPolicies.add(oldPoliciesList[0].Id);
            Set<Id> contentIds = new Set<Id>();
            List<ContentVersion> contentVersions = [SELECT ContentDocumentId FROM ContentVersion];
            for (ContentVersion contentVersion : contentVersions) {
                contentIds.add(contentVersion.ContentDocumentId);           
            }
            PolicyHelper.contentDocumentIds = contentIds;

            PolicyHelper.createPolicyVersion(oldPoliciesList, changedContentDocumentPolicies);
            List<Policy_Version__c> policyVersions = [SELECT Id, Policy__c, Version__c FROM Policy_Version__c WHERE Policy__c =: oldPoliciesList[0].Id];

            Policy_Notification__c policyNotification = new Policy_Notification__c(Policy_Version__c=policyVersions[0].Id,Policy_Read__c=false);
            insert policyNotification;

            for(grc__Policy__c oldpolicy : oldpoliciesList){
                oldPoliciesMap.put(oldpolicy.Id, oldpolicy);
            }
            for(grc__Policy__c newpolicy : newPoliciesList){
                newpolicy.OwnerId = usersList[0].Id;
            }
            update newPoliciesList;
            PolicyHelper.updatePolicyOwnersOnPolicyNotificationShares(newPoliciesList, oldPoliciesMap);

            Integer oldUserShares = [SELECT count() FROM Policy_Notification__Share 
                                     WHERE RowCause =: PolicyNotificationHelper.POLICY_OWNER_APEX_SHARING_REASON 
                                     AND UserOrGroupId =: u.Id];

            Integer newUserShares = [SELECT count() FROM Policy_Notification__Share 
                                     WHERE RowCause =: PolicyNotificationHelper.POLICY_OWNER_APEX_SHARING_REASON 
                                     AND UserOrGroupId =: usersList[0].Id];


            System.assertEquals(0, oldUserShares, 'Expected no shares for original owner');
            System.assertEquals(1, newUserShares, 'Expected shares for new owner');

            Test.stopTest();
        }
    }
}

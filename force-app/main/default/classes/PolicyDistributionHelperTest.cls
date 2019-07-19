/**
*   @description : Test Class for policy distribution helper
**/
@isTest(seeAllData=false)
private with sharing class PolicyDistributionHelperTest {
    
    /**
    *    @description : Set up test data
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
        System.assertEquals(1, policyVersionsList.size(), 'One Policy version must be created.');
    } 

    /**
    *    @description : test createPolicyShares method
    **/
    @isTest static void test_createPolicyShares(){
        Test.startTest();
        // get policy 
        List<grc__Policy__c> policiesList = [SELECT Id FROM grc__Policy__c LIMIT 1];
        System.assertEquals(0,[SELECT count() FROM grc__Policy__Share WHERE ParentId =: policiesList[0].Id AND RowCause =: PolicyDistributionHelper.POLICY_APEX_SHARING_REASON],'No share records created for a current user.');
        // create share records 
        PolicyDistributionHelper.createPolicyShares(policiesList[0].Id,new Set<Id>{UserInfo.getUserId()});
        System.assertEquals(1,[SELECT count() FROM grc__Policy__Share WHERE ParentId =: policiesList[0].Id AND RowCause =: PolicyDistributionHelper.POLICY_APEX_SHARING_REASON],'A share record created for a current user.');
        Test.stopTest();
    } 

    /**
    *    @description : test createPolicyNotifications method
    **/
    @isTest static void test_createPolicyNotifications(){
        Test.startTest();
        // get policy 
        List<Policy_Version__c> policyVersionsList = [SELECT Id FROM Policy_Version__c LIMIT 1];
        System.assertEquals(0,[SELECT count() FROM Policy_Notification__c],'No policy notification records created for a current user.');
        // create notificatiosn
        List<Policy_Notification__c> policyNotificationsList = PolicyDistributionHelper.createPolicyNotifications(policyVersionsList[0].Id,new Set<Id>{UserInfo.getUserId()},'Test Message');
        insert policyNotificationsList;
        System.assertEquals(1,[SELECT count() FROM Policy_Notification__c],'A policy notification record created for a current user.');
        Test.stopTest();
    } 

    /**
    *    @description : test getPolicyNotifications method
    **/
    @isTest static void test_getPolicyNotifications(){
        Test.startTest();
        // get policy 
        List<Policy_Version__c> policyVersionsList = [SELECT Id FROM Policy_Version__c LIMIT 1];
        System.assertEquals(0,PolicyDistributionHelper.getPolicyNotifications(policyVersionsList[0].Id).size(),'No policy notification records exists for a current user.');
        // create notificatiosn
        List<Policy_Notification__c> policyNotificationsList = PolicyDistributionHelper.createPolicyNotifications(policyVersionsList[0].Id,new Set<Id>{UserInfo.getUserId()},'Test Message');
        insert policyNotificationsList;
        System.assertEquals(1,PolicyDistributionHelper.getPolicyNotifications(policyVersionsList[0].Id).size(),'A policy notification record exists for a current user.');
        Test.stopTest();
    } 

    /**
    *    @description : test getPolicySharedUsers method
    **/
    @isTest static void test_getPolicySharedUsers(){
        Test.startTest();
        // get policy 
        List<grc__Policy__c> policiesList = [SELECT Id FROM grc__Policy__c LIMIT 1];
        System.assertEquals(0,PolicyDistributionHelper.getPolicySharedUsers(policiesList[0].Id).size(),'No share records created for a current user.');
        // create share records 
        PolicyDistributionHelper.createPolicyShares(policiesList[0].Id,new Set<Id>{UserInfo.getUserId()});
        System.assertEquals(1,PolicyDistributionHelper.getPolicySharedUsers(policiesList[0].Id).size(),'A share record created for a current user.');
        Test.stopTest();
    }
}

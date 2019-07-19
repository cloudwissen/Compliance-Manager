/**
*    @description : Test Class for PolicyNotificationTriggerHelper
**/
@isTest(seeAllData=false)
private with sharing class PolicyNotificationHelperTest {

    private static List<User> usersList;
    
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

        // create notified users
        List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>{new Policy_Notification__c(Policy_Version__c=policyVersionsList[0].Id,OwnerId=UserInfo.getUserId(),Policy_Read__c=false)};
        insert policyNotificationsList;

        policiesToCreate = [SELECT Id FROM grc__Policy__c];
        System.assertEquals(1, policiesToCreate.size(), 'One Policy must be created.');   
        policyVersionsList = [SELECT Id FROM Policy_Version__c];
        System.assertEquals(1, policyVersionsList.size(), 'One Policy Version must be created.');  
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
    *   @description Test getPolicyNotificationsByPolicyOwnerId method.
    **/
    @isTest 
    static void test_getPolicyNotificationsByPolicyOwnerId(){
        Test.startTest();
        List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Policy_Version__c FROM Policy_Notification__c];
        System.assertEquals(1,PolicyNotificationHelper.getPolicyNotificationsByPolicyOwnerId(policyNotificationsList).size(),'Map size should be one');
        System.assert(PolicyNotificationHelper.getPolicyNotificationsByPolicyOwnerId(policyNotificationsList).containsKey(UserInfo.getUserId()),'Map values should contain current user id.');
        Test.stopTest();
    }

    /**
    *   @description Test createPolicyNotificationSharesForPolicyOwners method.
    **/
    @isTest 
    static void test_createPolicyNotificationSharesForPolicyOwners(){
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            Test.startTest();
            createUsers();
            List<Policy_Notification__c> policyNotificationsList = [SELECT Id, OwnerId FROM Policy_Notification__c];
            // check policy notification shares
            System.assertEquals(0,[SELECT count() FROM Policy_Notification__Share WHERE RowCause =: PolicyNotificationHelper.POLICY_OWNER_APEX_SHARING_REASON AND UserOrGroupId =: usersList[0].Id],'There should be no share record for new user');
            PolicyNotificationHelper.createPolicyNotificationSharesForPolicyOwners(new Map<Id,List<Policy_Notification__c>>{usersList[0].Id => [SELECT Id FROM Policy_Notification__c]});
            // check policy notification shares after create
            System.assertEquals(1,[SELECT count() FROM Policy_Notification__Share WHERE RowCause =: PolicyNotificationHelper.POLICY_OWNER_APEX_SHARING_REASON AND UserOrGroupId =: usersList[0].Id],'There should be a share record for new user');
            // set owner as null
            Test.stopTest();
        }
    }
}

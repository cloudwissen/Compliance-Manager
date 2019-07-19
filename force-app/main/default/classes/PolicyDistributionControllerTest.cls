/**
*   @description : Test Class for policy distribution controller
**/
@isTest(seeAllData=false)
private with sharing class PolicyDistributionControllerTest {

    private static List<User> usersList;
    private static List<UserRole> rolesList;
    private static List<Group> groupsList;
    private static grc__Policy__c policy;
    private static Policy_Version__c policyVersion;
    
    /**
    *   @description : Set up test data
    **/
    static void setUpTestData(){
        groupsList = new List<Group>{new Group(Name='Test Group - 0')};
        insert groupsList;

        rolesList = new List<UserRole>{new UserRole(Name='Test Group - 0',DeveloperName='TestGroup0')};
        insert rolesList;

        usersList = new List<User>();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        for(Integer i=0;i<3;i++){
            usersList.add(new User(firstname = 'Test '+String.valueOf(i),
                                lastName = 'Test '+String.valueOf(i),
                                email = uniqueName + '@test'+String.valueOf(i)+orgId+'.org',
                                Username = uniqueName + '@test'+String.valueOf(i)+orgId+'.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = uniqueName.substring(18, 23),
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = profileId,
                                UserRoleId = rolesList[0].Id));
        }
        insert usersList;

        List<GroupMember> groupMembersList = new List<GroupMember>{new GroupMember(GroupId=groupsList[0].Id,UserOrGroupId=UserInfo.getUserId())};
        insert groupMembersList;
    }

    /**
    *   @description : Create policy data.
    **/
    private static void createPolicyData() {
        policy = new grc__Policy__c();
        insert policy;
        policyVersion = new Policy_Version__c(Policy__c = policy.Id, Version__c = 1, Description__c = 'Test');
        insert policyVersion;
    }

    /**
    *   @description : Test get policy info.
    **/
    @isTest
    static void test_getPolicyInfo() {
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            createPolicyData();

            Test.startTest();

            String policyInfoStr = PolicyDistributionController.getPolicyInfo(policy.Id);
            System.assertNotEquals(null, policyInfoStr);
            Map<String,Object> policyInfoMap = (Map<String,Object>)JSON.deserializeUntyped(policyInfoStr);
            grc__Policy__c testPolicy = (grc__Policy__c)JSON.deserialize(String.valueOf(policyInfoMap.get('policy')), grc__Policy__c.class);
            System.assertEquals(policy.Id, testPolicy.Id);
            System.assertEquals(1, testPolicy.Policy_Versions__r[0].Version__c);
            System.assertEquals(Policy_Notification__c.Transient_Message__c.getDescribe().getLabel(),String.valueOf(policyInfoMap.get('transientMessageFieldLabel')));
            Test.stopTest();
        }
    }
    

    /**
    *   @description : Successful policy distribution for users.
    **/
    @isTest
    static void test_distributePolicySuccessUsers(){
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {

            setUpTestData();
            Test.startTest();
            createPolicyData();

            //test initial submission
            Map<String,String> distributeInfo = PolicyDistributionController.distributePolicy(policy.Id, JSON.serialize(usersList), 'test');
            System.assertNotEquals(null, distributeInfo.get('message'));
            System.assertEquals(distributeInfo.get('type'), 'success');

            //test re-submission
            distributeInfo = PolicyDistributionController.distributePolicy(policy.Id, JSON.serialize(usersList), 'test');
            System.assertEquals(distributeInfo.get('message'), System.Label.Policy_Already_Distributed_Message);
            System.assertEquals(distributeInfo.get('type'), 'info');

            Test.stopTest();
        }
    }

    /**
    *   @description : Successful policy distribution for Groups.
    **/
    @isTest
    static void test_distributePolicySuccessGroups(){
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {

            setUpTestData();
            Test.startTest();
            createPolicyData();

            //test initial submission
            Map<String,String> distributeInfo = PolicyDistributionController.distributePolicy(policy.Id, JSON.serialize(groupsList), 'test');
            System.assertNotEquals(null, distributeInfo.get('message'));
            System.assertEquals(distributeInfo.get('type'), 'success');

            Test.stopTest();
        }
    }

    /**
    *   @description : Successful policy distribution for Roles.
    **/
    @isTest
    static void test_distributePolicySuccessRoles(){
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {

            setUpTestData();
            Test.startTest();
            createPolicyData();

            //test initial submission
            Map<String,String> distributeInfo = PolicyDistributionController.distributePolicy(policy.Id, JSON.serialize(rolesList), 'test');
            System.assertNotEquals(null, distributeInfo.get('message'));
            System.assertEquals(distributeInfo.get('type'), 'success');

            Test.stopTest();
        }
    }

    /**
	*	@description : Test getNotifiedUsers method.
	**/
	@isTest
	private static void test_getNotifiedUsers() {
		Test.startTest();
        createPolicyData();
        System.assertEquals(0,PolicyDistributionController.getNotifiedUsers(policy.Id).size(),'No notified user available.');
        // create notified users
		List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>{new Policy_Notification__c(Policy_Version__c=policyVersion.Id,OwnerId=UserInfo.getUserId(),Policy_Read__c=false)};
		insert policyNotificationsList;
        System.assertEquals(1,PolicyDistributionController.getNotifiedUsers(policy.Id).size(),'One notified user available.');
		Test.stopTest();
	}

    /**
	*	@description : Test getUserIdsToExclude method.
	**/
	@isTest
	private static void test_getUserIdsToExclude() {
		Test.startTest();
        createPolicyData();
        Integer excludedUsers = PolicyDistributionController.getUserIdsToExclude(policy.Id).size();
        System.assert(excludedUsers == 0 || excludedUsers > 0,'There might be users with or without custom permission.');
        // create notified users
		List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>{new Policy_Notification__c(Policy_Version__c=policyVersion.Id,OwnerId=UserInfo.getUserId(),Policy_Read__c=false)};
		insert policyNotificationsList;
        System.assertEquals(excludedUsers+1,PolicyDistributionController.getUserIdsToExclude(policy.Id).size(),'Exclude notified user.');
		Test.stopTest();
	}
}
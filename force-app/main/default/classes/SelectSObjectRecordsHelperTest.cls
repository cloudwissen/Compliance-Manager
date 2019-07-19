/**
* @description Test class for SelectSObjectRecordsController
**/
@isTest(seeAllData=false)
private with sharing class SelectSObjectRecordsHelperTest {

    private static List<User> usersList;
    private static List<UserRole> rolesList;
    private static List<Group> groupsList;
    private static Id profileId;
    
    /**
    *   @description : Set up test data
    **/
    private static void setUpTestData(){
        groupsList = new List<Group>{new Group(Name='Test Group - 0')};
        insert groupsList;

        rolesList = new List<UserRole>{new UserRole(Name='Test Group - 0',DeveloperName='TestGroup0')};
        insert rolesList;

        usersList = new List<User>();
        profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
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
	*   @description Test sharing group field avail
	**/
	@isTest 
    static void test_isSharingGroupFieldAvailable() {
		System.assertEquals(grc__Business_Unit__c.sObjectType.getDescribe().fields.getMap().keySet().contains(SelectSObjectRecordsHelper.BUSINESS_UNIT_SHARING_GROUP_NAME_FIELD),SelectSObjectRecordsHelper.isSharingGroupFieldAvailable());
	}

	/**
	*   @description Test to check the sObjectNameFromId method
	**/
	@isTest 
    static void test_getsObjectNameFromId() {
		System.assertEquals('user', SelectSObjectRecordsHelper.getsObjectNameFromId(UserInfo.getUserId()),'It should return user since the user id is been passed into it');
	}
    
    /**
	*   @description Test document by developer name getBusinessUnitPublicGroupNames
	**/
	@isTest 
    static void test_getBusinessUnitPublicGroupNames() {
		System.assert(SelectSObjectRecordsHelper.getBusinessUnitPublicGroupNames(new Set<Id>()).size() == 0);
	}
    /**
	*   @description Test document by developer name getBusinessUnitPublicGroupNames
	**/
	@isTest 
    static void test_getgetDocumentByDeveloperName() {
		System.assertEquals(null, SelectSObjectRecordsHelper.getDocumentByDeveloperName('test doc xact !'));
	}

	/**
    *   @description Test getsObjectByRecordIds Map
    **/
    @isTest 
    static void test_getsObjectByRecordIdsMap() {
        Test.startTest();
        Id userId = UserInfo.getUserId();
        SelectSObjectRecordsHelper.Record record1 = new SelectSObjectRecordsHelper.Record();
        record1.Id = UserInfo.getUserId();
        record1.Name = 'Test User';
        SelectSObjectRecordsHelper.Record record2 = new SelectSObjectRecordsHelper.Record();
        record2.Id = '0059E000001kTLW';
        record2.Name = 'Test User 1';
        List<SelectSObjectRecordsHelper.Record> recordsList = new List<SelectSObjectRecordsHelper.Record>{record1,record2};
        System.assertEquals(2, SelectSObjectRecordsHelper.getsObjectByRecordIdsMap(recordsList).get('user').size(), 'There should be 2 user ids available');
        Test.stopTest();
    }

    /**
	*   @description Test Get related user ids method with users.
	**/
	@isTest 
    static void test_getRelatedUserIds_users() {
        User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
            Test.startTest();
            Id userId = UserInfo.getUserId();
            SelectSObjectRecordsHelper.Record record1 = new SelectSObjectRecordsHelper.Record();
            record1.Id = UserInfo.getUserId();
            record1.Name = 'Test User';
            SelectSObjectRecordsHelper.Record record2 = new SelectSObjectRecordsHelper.Record();
            record2.Id = usersList[0].Id;
            record2.Name = 'Test User 1';
            List<SelectSObjectRecordsHelper.Record> recordsList = new List<SelectSObjectRecordsHelper.Record>{record1,record2};
            System.assertEquals(2, SelectSObjectRecordsHelper.getRelatedUserIds(recordsList).size(), 'There should be 2 user ids available');
            Test.stopTest();
        }
	}

    /**
	*   @description Test Get related user ids method with public groups.
	**/
	@isTest 
    static void test_getRelatedUserIds_groups() {
        User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
            Test.startTest();
            Id userId = UserInfo.getUserId();
            SelectSObjectRecordsHelper.Record record1 = new SelectSObjectRecordsHelper.Record();
            record1.Id = groupsList[0].Id;
            record1.Name = 'Test Group';
            List<SelectSObjectRecordsHelper.Record> recordsList = new List<SelectSObjectRecordsHelper.Record>{record1};
            System.assertEquals(1, SelectSObjectRecordsHelper.getRelatedUserIds(recordsList).size(), 'There should be 1 user id available');
            Test.stopTest();
        }
	}

    /**
	*   @description Test Get related user ids method with roles.
	**/
	@isTest 
    static void test_getRelatedUserIds_roles() {
		User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
            Test.startTest();
            Id userId = UserInfo.getUserId();
            SelectSObjectRecordsHelper.Record record1 = new SelectSObjectRecordsHelper.Record();
            record1.Id = rolesList[0].Id;
            record1.Name = 'Test Role';
            List<SelectSObjectRecordsHelper.Record> recordsList = new List<SelectSObjectRecordsHelper.Record>{record1};
            System.assertEquals(3, SelectSObjectRecordsHelper.getRelatedUserIds(recordsList).size(), 'There should be 3 user ids available');
            Test.stopTest();
        }
	}

    /**
	*   @description Test getUsersWithCustomPermission method.
	**/
	@isTest 
    static void test_getUsersWithCustomPermission(){
		User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
            Test.startTest();
            // check permission set already assigned to a profile
            Set<Id> permissionSetIds = new Set<Id>();
            for(SetupEntityAccess entityAccess : [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName =: PolicyDistributionController.CUSTOM_PERMISSION_TO_CHECK)]){
			    permissionSetIds.add(entityAccess.ParentId);
		    }
            List<PermissionSet> permissionSetsList = [SELECT Id FROM PermissionSet WHERE Id IN: permissionSetIds AND ProfileId =: profileId LIMIT 1]; 
            System.assertEquals(permissionSetsList.isEmpty() ? 0 : 3,SelectSObjectRecordsHelper.getUsersWithCustomPermission(new Map<Id,User>(usersList).keySet(),PolicyDistributionController.CUSTOM_PERMISSION_TO_CHECK).size(),'There should be no users if the custom permission already not assigned to a system admin profile.');
            List<CustomPermission> customPermissionsList = [SELECT Id FROM CustomPermission WHERE DeveloperName  =: PolicyDistributionController.CUSTOM_PERMISSION_TO_CHECK LIMIT 1];
            PermissionSet permissionSet = new PermissionSet(Name='Test',Label='Test');
            insert permissionSet;
            SetupEntityAccess entityAccess = new SetupEntityAccess(ParentId=permissionSet.Id,SetupEntityId=customPermissionsList[0].Id);
            insert entityAccess;
            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            for(User user : usersList){
                permissionSetAssignments.add(new PermissionSetAssignment(PermissionSetId=permissionSet.Id,AssigneeId=user.Id));
            }
            insert permissionSetAssignments;
            System.assertEquals(3,SelectSObjectRecordsHelper.getUsersWithCustomPermission(new Map<Id,User>(usersList).keySet(),PolicyDistributionController.CUSTOM_PERMISSION_TO_CHECK).size(),'There should be three users with the custom permission.');
            Test.stopTest();
        }
	}
}
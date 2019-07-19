/**
*	@description : Test Class for Invite Users
**/
@isTest(seeAllData=false)
private with sharing class InviteUsersControllerTest {
	
	private static List<Group> groupsList;
    private static List<UserRole> rolesList;
    private static List<User> usersList;
    private static List<Training_Course__c> trainingCoursesList;
    
    /**
	*	@description : Set up test data
	**/
	static void setUpTestData(){
		// create public groups 
		groupsList = new List<Group>{new Group(Name='Test Group - 0')};
		insert groupsList;

		// create user roles 
		rolesList = new List<UserRole>{new UserRole(Name='Test Group - 0',DeveloperName='TestGroup0')};
		insert rolesList;

		// create users 
		usersList = new List<User>();
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
		String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
		Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
		String uniqueName = orgId + dateString + randomInt;
		for(Integer i=0;i<2;i++){
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
        
        usersList[0].UserRoleId = rolesList[0].Id;
		insert usersList;
		
		// create public group members 
		List<GroupMember> groupMembersList = new List<GroupMember>{new GroupMember(GroupId=groupsList[0].Id,UserOrGroupId=UserInfo.getUserId())};
		insert groupMembersList;
		
		// create training courses
		trainingCoursesList = new List<Training_Course__c>{new Training_Course__c(Name='Test Training - 1',Start_Date__c=System.today(),End_Date__c=System.today().addDays(10))};
		insert trainingCoursesList;

		// create training modules
		List<Training_Module__c> trainingModulesList = new List<Training_Module__c>{new Training_Module__c(Name='Test Module - 1',Training_Course__c=trainingCoursesList[0].Id,Start_Date_Time__c=System.today(),End_Date_Time__c=System.today().addDays(10))};
		insert trainingModulesList;
	}

	/**
	*	@description : test saveUsers method
	**/
	@isTest static void test_saveUsers(){
        String recordsJSON = '';
		
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
            Test.startTest();
            // create records json
            recordsJSON += '{"Id":"' + groupsList[0].Id + '","Name":"' + groupsList[0].Name + '"},';
            recordsJSON += '{"Id":"' + rolesList[0].Id + '","Name":"' + rolesList[0].Name + '"},';
            recordsJSON += '{"Id":"' + usersList[1].Id + '","Name":"' + usersList[1].Name + '"}';
            Test.stopTest();
        }
		// call saveUsers method
		InviteUsersController.saveUsers(trainingCoursesList[0].Id, '['+recordsJSON+']');
		List<Event> results = [Select Id from Event];
		System.assertEquals(3,results.size(),'There should be 3 new events, one for each user and module.');
        
        // call saveUsers method without new users
		InviteUsersController.saveUsers(trainingCoursesList[0].Id, '[]');
		results = [Select Id from Event];
		System.assertEquals(3,results.size(),'There should be no new events, just the 3 previously created.');

		InviteUsersController.saveUsers(trainingCoursesList[0].Id, '['+recordsJSON+']');
		results = [Select Id from Event];
		System.assertEquals(3,results.size(),'There should be no new events, just the 3 previously created.');

		// create new training module
		List<Training_Module__c> trainingModulesList = new List<Training_Module__c>{new Training_Module__c(Name='Test Module - 2',Training_Course__c=trainingCoursesList[0].Id,Start_Date_Time__c=System.today(),End_Date_Time__c=System.today().addDays(10))};
		insert trainingModulesList;

		InviteUsersController.saveUsers(trainingCoursesList[0].Id, '['+recordsJSON+']');
		results = [Select Id from Event];
		System.assertEquals(6,results.size(),'There should be three new events for the new training module');
	}

	/**
	*	@description : test saveUsers method without training module
	**/
	@isTest static void test_saveUsersWithoutTrainingModule(){
        String recordsJSON = '';
		
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
            Test.startTest();
			delete [SELECT Id from Training_Module__c WHERE Training_Course__c =: trainingCoursesList[0].Id LIMIT 1];
            // create records json
            recordsJSON += '{"Id":"' + groupsList[0].Id + '","Name":"' + groupsList[0].Name + '"},';
            recordsJSON += '{"Id":"' + rolesList[0].Id + '","Name":"' + rolesList[0].Name + '"},';
            recordsJSON += '{"Id":"' + usersList[1].Id + '","Name":"' + usersList[1].Name + '"}';
            Test.stopTest();
        }

		InviteUsersController.saveUsers(trainingCoursesList[0].Id, '['+recordsJSON+']');
		List<Event> results = [Select Id from Event];
		System.assertEquals(0,results.size(),'There should no events created since there is no training module');
	}

	/**
	*	@description : test isTrainingInviteValid method
	**/
	@isTest static void test_isTrainingInviteValid(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u){
            setUpTestData();
        }
		Test.startTest();
		Map<String,Object> trainingInfo = (Map<String,Object>)JSON.deserializeUntyped(InviteUsersController.getTrainingInfo(trainingCoursesList[0].Id));
		System.assertEquals(true,(Boolean)trainingInfo.get('isvalid'),'training module available so the method should return true');
		Test.stopTest();
	}

	/**
	*	@description : test isTrainingInviteValid method without training module
	**/
	@isTest static void test_isTrainingInviteValidWithoutTrainingModule(){
		List<Training_Course__c> trainingCoursesList = new List<Training_Course__c>{new Training_Course__c(Name='Test Training - 1',Start_Date__c=System.today(),End_Date__c=System.today().addDays(10))};
		insert trainingCoursesList;
		Test.startTest();
		Map<String,Object> trainingInfo = (Map<String,Object>)JSON.deserializeUntyped(InviteUsersController.getTrainingInfo(trainingCoursesList[0].Id));
		System.assertEquals(false,(Boolean)trainingInfo.get('isvalid'),'training module not available so the method should return false');
		Test.stopTest();
	}
}
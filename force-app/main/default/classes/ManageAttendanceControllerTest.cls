/**
*	@description : Test Class for Manage Attendance Controller
**/
@isTest(seeAllData=false)
private with sharing class ManageAttendanceControllerTest {
	
	/**
	*	@description : Set up test data
	**/
	@testSetup
	static void setUpTestData(){
		// create training courses
		List<Training_Course__c> trainingCoursesList = new List<Training_Course__c>{new Training_Course__c(Name='Test Training - 1',Start_Date__c=System.today(),End_Date__c=System.today().addDays(10))};
		insert trainingCoursesList;

		// create training modules
		List<Training_Module__c> trainingModulesList = new List<Training_Module__c>{new Training_Module__c(Name='Test Module - 1',Training_Course__c=trainingCoursesList[0].Id,Start_Date_Time__c=System.today(),End_Date_Time__c=System.today().addDays(10))};
		insert trainingModulesList;

		// create training events
		Id trainingRecordTypeId = Event.SObjectType.getDescribe().getRecordTypeInfosByName().containsKey(ManageAttendanceController.TRAINING_RECORD_TYPE_NAME) ? Event.SObjectType.getDescribe().getRecordTypeInfosByName().get(ManageAttendanceController.TRAINING_RECORD_TYPE_NAME).getRecordTypeId() : null;
		List<Event> eventsToCreate = new List<Event>{new Event(WhatId=trainingModulesList[0].Id,OwnerId=UserInfo.getUserId(),Subject=trainingModulesList[0].Name,RecordTypeId=trainingRecordTypeId,EndDateTime=trainingModulesList[0].End_Date_Time__c,StartDateTime=trainingModulesList[0].Start_Date_Time__c)};
		insert eventsToCreate;

		trainingCoursesList = [SELECT Id FROM Training_Course__c];
		System.assertEquals(1, trainingCoursesList.size(), 'One Training Course must be created.');
		trainingModulesList = [SELECT Id FROM Training_Module__c];
		System.assertEquals(1, trainingModulesList.size(), 'One Training Module must be created.');
		eventsToCreate = [SELECT Id FROM Event];
		System.assertEquals(1, eventsToCreate.size(), 'One Event must be created.');
	}

	/**
	*	@description : test getUsers method
	**/
	@isTest static void test_getUsers(){
		Test.startTest();
		// fetch training module records 
		List<Training_Module__c> trainingModulesList = [SELECT Id FROM Training_Module__c LIMIT 1];

		// call getRecords method 
		Map<String,Object> objectsMap = ManageAttendanceController.getUsers(trainingModulesList[0].Id);
		List<sObject> recordsList = (List<sObject>)objectsMap.get('data');
		List<XLC.DataTableField> columnsList = (List<XLC.DataTableField>)objectsMap.get('columns');
		Set<Id> attendedUsers = (Set<Id>)objectsMap.get('selectedIds');
		System.assertEquals(4,objectsMap.size(),'Objects Map size must be 3');
		System.assert(recordsList.size() == 1, 'Records list must be equal to 1');
		System.assertEquals(1, columnsList.size(), 'Columns list must be 1');
		System.assertEquals(User.sObjectType.getDescribe().getLabelPlural(), (String)objectsMap.get('labelPlural'), 'This should be equal to plural label of the user object.');
		System.assertEquals(0, attendedUsers.size(), 'There should be no attended users.');
		Test.stopTest();
	}


	/**
	*	@description : test fetchUsers method
	**/
	@isTest static void test_fetchUsers(){
		Test.startTest();
		// call fetchUsers method 
		System.assert(ManageAttendanceController.fetchUsers(new Set<Id>{UserInfo.getUserId()}).size() == 1,'This should be only one user.'); 
		Test.stopTest();
	}

	/**
	*	@description : test getInvitedUsers method 
	**/
	@isTest static void test_getInvitedUsers(){
		Test.startTest();
		// fetch training module records 
		List<Training_Module__c> trainingModulesList = [SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c FROM Training_Module__c LIMIT 1];
		// fetch training module events 
		List<Event> eventsList = [SELECT Id, OwnerId, Attended__c FROM Event WHERE WhatId =: trainingModulesList[0].Id LIMIT 25000];
		// call getInvitedUsers method 
		System.assertEquals(1,ManageAttendanceController.getInvitedUsers(eventsList).size(),'This should return only one user.');
		Test.stopTest();
	}

	/**
	*	@description : test getAttendedUsers method 
	**/
	@isTest static void test_getAttendedUsers(){
		Test.startTest();
		// fetch training module records 
		List<Training_Module__c> trainingModulesList = [SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c FROM Training_Module__c LIMIT 1];
		// fetch training module events 
		List<Event> eventsList = [SELECT Id, OwnerId, Attended__c FROM Event WHERE WhatId =: trainingModulesList[0].Id LIMIT 25000];
		// call getAttendedUsers method 
		System.assertEquals(0,ManageAttendanceController.getAttendedUsers(eventsList).size(),'There should be no attended users.');
		Test.stopTest();
	}

	/**
	*	@description : test markAttendance method  
	**/
	@isTest static void test_markAttendance(){
		Test.startTest();
		System.assertEquals(0,[SELECT count() FROM Event WHERE Attended__c =: true LIMIT 1],'There should not be any users attended the training');
		// fetch training module records 
		List<Training_Module__c> trainingModulesList = [SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c FROM Training_Module__c LIMIT 1];
		// call markAttendance method 
		ManageAttendanceController.markAttendance(trainingModulesList[0].Id,JSON.serialize(new List<String>{UserInfo.getUserId()}));
		System.assertEquals(1,[SELECT count() FROM Event WHERE Attended__c =: true LIMIT 1],'There should be one user attended the training.');
		Test.stopTest();
	}
}
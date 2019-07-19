/**
*    @description : Test Class for Invited Users
**/
@isTest(seeAllData=false)
private with sharing class InvitedUsersControllerTest {
    
    /**
    *    @description : Set up test data
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
        Id trainingRecordTypeId = Event.SObjectType.getDescribe().getRecordTypeInfosByName().containsKey(InviteUsersController.TRAINING_RECORD_TYPE_NAME) ? Event.SObjectType.getDescribe().getRecordTypeInfosByName().get(InviteUsersController.TRAINING_RECORD_TYPE_NAME).getRecordTypeId() : null;
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
    *    @description : Test getInvitedUsers method on InvitedUsersController
    **/
    @isTest static void test_getInvitedUsers(){
        Test.startTest();
        // get training course
        List<Training_Course__c> trainingCoursesList = [SELECT Id FROM Training_Course__c LIMIT 1];
        List<User> recordsList = InvitedUsersController.getInvitedUsers(trainingCoursesList[0].Id);
        System.assertEquals(1,recordsList.size(),'There should only be one user in the list.'); 
        Test.stopTest();
    }

    /**
    *    @description : Test deleteEvents
    **/
    @isTest
    static void test_deleteEvents(){
        Test.startTest();
        // get training course
        
        List<Training_Course__c> trainingCoursesList = [SELECT Id FROM Training_Course__c LIMIT 1];
        List<User> recordsList = InvitedUsersController.getInvitedUsers(trainingCoursesList[0].Id);
        System.assertEquals(1,recordsList.size(),'There should only be one user in the list.'); 
        InvitedUsersController.deleteEvents(trainingCoursesList[0].Id,UserInfo.getUserId());

        trainingCoursesList = [SELECT Id FROM Training_Course__c LIMIT 1];
        recordsList = InvitedUsersController.getInvitedUsers(trainingCoursesList[0].Id);
        System.assertEquals(0,recordsList.size(),'There should be no event, since event has been deleted'); 
        Test.stopTest();
    }


    /**
    *    @description : Test getOwnerIdsFromTrainingEvents method on InvitedUsersController
    **/
    @isTest
    static void test_getOwnerIdsFromTrainingEvents(){
        Test.startTest();
        // get training course
        List<Training_Course__c> trainingCoursesList = [SELECT Id FROM Training_Course__c LIMIT 1];
        System.assertEquals(1,InvitedUsersController.getOwnerIdsFromTrainingEvents(trainingCoursesList[0].Id).size(),'There should only be one user id in the list as we created one event for the current user.'); 
        Test.stopTest();
    }

}
/**
*    @description : Apex class to get the list of attended users for a training course
**/
public with sharing class InvitedUsersController {

    
    /**
    *    @description : Method to used to fetch all the users from the system
    *    @param trainingCourseId Id of the training course currently in context
    *    @return List<Object> Invited Users data
    **/
    @AuraEnabled
    public static List<User> getInvitedUsers(Id trainingCourseId){
        List<User> usersList = new List<User>();
        
        //Check user has sufficient access to Query Training Module and Event Data
        Boolean queryAccessTrainingModule = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                                Training_Module__c.sObjectType.getDescribe().getName(), 
                                                new Set<String>{Training_Module__c.Training_Course__c.getDescribe().getName()}, 
                                                XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                            );
        Boolean queryAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                        Event.sObjectType.getDescribe().getName(), 
                                        new Set<String>{Event.OwnerId.getDescribe().getName()}, 
                                        XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                    );
        
        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessTrainingModule || !queryAccessEvents){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }

        try{
            Set<Id> userIds = getOwnerIdsFromTrainingEvents(trainingCourseId);
            usersList = [SELECT Id, Name, FullPhotoUrl FROM User WHERE Id IN: userIds LIMIT 25000];
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return usersList;
    }

    /**
    *    @description : Delete Event
    *    @param         trainingCourseId Id of the training course currently in context
    *    @param         userId -  Id of the users
    **/
    @AuraEnabled
    public static void deleteEvents(Id trainingCourseId, Id userId){
        
        //Check user has sufficient access to Query Training Module and Event Data
        Boolean queryAccessTrainingModule = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                                Training_Module__c.sObjectType.getDescribe().getName(), 
                                                new Set<String>{Training_Module__c.Training_Course__c.getDescribe().getName()}, 
                                                XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                            );
		Boolean queryAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                        Event.sObjectType.getDescribe().getName(),  
                                        new Set<String>{Event.OwnerId.getDescribe().getName()}, 
                                        XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                    );
        //Check user has sufficient access to Delete Event Data
        Boolean deleteAccessEvents =  Event.sObjectType.getDescribe().isDeletable();

        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessTrainingModule || !queryAccessEvents || !deleteAccessEvents){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }

        try{
            List<Event> eventsToBeDeleted = new List<Event>();
            for(Training_Module__c trainingModule : [SELECT Id, Name, (SELECT OwnerId FROM Events WHERE OwnerId = :userId) FROM Training_Module__c WHERE Training_Course__c =: trainingCourseId LIMIT 10000]){
                eventsToBeDeleted.addAll(trainingModule.Events);
            }
            delete eventsToBeDeleted;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    *    @description : Method used to get the owner ids from training events
    *    @param trainingCourseId Id of the training course currently in context
    *    @return Set<Id> Owner Ids from Training Events
    **/
    @testVisible
    private static Set<Id> getOwnerIdsFromTrainingEvents(Id trainingCourseId){
        Set<Id> userIds = new Set<Id>();
        // query training modules with events 
        for(Training_Module__c trainingModule : [SELECT Id, Name, (SELECT OwnerId FROM Events) FROM Training_Module__c WHERE Training_Course__c =: trainingCourseId LIMIT 10000]){
            for(Event event : trainingModule.Events){
                userIds.add(event.OwnerId);
            }
        }
        return userIds;
    }
}
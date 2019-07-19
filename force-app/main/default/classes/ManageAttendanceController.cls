/**
*	@description : Apex class mark user attendance on a training module
**/
public with sharing class ManageAttendanceController {

	@testVisible
	private static final String TRAINING_RECORD_TYPE_NAME = 'Training';
	
	/**
	*	@description : Method to used to fetch the participants for a training module
	*	@param trainingModuleId Id of the training module
	* 	@return Map<String, Object> Map contains user data and field information for lightning datatable column
	**/
	@AuraEnabled
	public static Map<String,Object> getUsers(Id trainingModuleId){
		Map<String, object> objectsMap = new Map<String, Object>();
        
        //Check user has sufficient access to Query Event Data
        Boolean queryAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										Event.sObjectType.getDescribe().getName(),
										new Set<String>{	Event.OwnerId.getDescribe().getName(),
															Event.XLComp__Attended__c.getDescribe().getName(),
															Event.WhatId.getDescribe().getName()
														}, 
										XLC.SchemaHelper.DatabaseAction.QUERY_DATA
									);
        
        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessEvents){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }

		List<Event> eventsList = [SELECT Id, OwnerId, Attended__c FROM Event WHERE WhatId =: trainingModuleId LIMIT 25000];
		Set<Id> invitedUsersList = getInvitedUsers(eventsList);
		objectsMap.put('data',fetchUsers(invitedUsersList));
		objectsMap.put('columns',new List<XLC.DataTableField>{new XLC.DataTableField(User.Name.getDescribe().getLabel(),User.Name.getDescribe().getName(),User.Name.getDescribe().getType().name().toLowerCase(),true)});
		objectsMap.put('labelPlural',User.sObjectType.getDescribe().getLabelPlural());
		objectsMap.put('selectedIds',getAttendedUsers(eventsList));
		return objectsMap;
	}

	/**
	*	@description : Method used to fetch all invited users for a training module
	*	@param invitedUsers List of invited users
	*	@return List<sObject> List of invited users
	**/
	@testVisible
	private static List<sObject> fetchUsers(Set<Id> invitedUsers){
		// fetch users
		return [SELECT Id, Name FROM User WHERE Id IN: invitedUsers ORDER BY Name LIMIT 30000];	
	}

	/**
	*	@description : Method to get the list of invited users for a training
	*	@param trainingModuleId Id of the training module
	*	@return Set<Id> List of invited user ids for a training module
	**/
	@testVisible
	private static Set<Id> getInvitedUsers(List<Event> eventsList){
		Set<Id> userIds = new Set<Id>();
		for(Event event : eventsList){
			userIds.add(event.OwnerId);
		}
		return userIds;
	}

	/**
	*	@description : Method to get the list of users attended for a training
	*	@param eventsList List of events records
	*	@return Set<Id> List of attended users for training module
	**/
	@testVisible
	private static Set<Id> getAttendedUsers(List<Event> eventsList){
		Set<Id> userIds = new Set<Id>();
		for(Event event : eventsList){
			if(event.Attended__c) {
				userIds.add(event.OwnerId);
			}
		}
		return userIds;
	}

	/**
	*	@description : Method to mark attendance 
	*	@param trainingModuleId Id of the training module
	*	@param selectedUsers Comma separated list of selected users
	* 	@return void
	**/
	@AuraEnabled
	public static void markAttendance(Id trainingModuleId, String selectedUsers){

        //Check user has sufficient access to Query Event Data
        Boolean queryAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										Event.sObjectType.getDescribe().getName(), 
										new Set<String>{	Event.OwnerId.getDescribe().getName(),
															Event.XLComp__Attended__c.getDescribe().getName(),
															Event.WhatId.getDescribe().getName()
														}, 
										XLC.SchemaHelper.DatabaseAction.QUERY_DATA
									);
        Boolean updateAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										Event.sObjectType.getDescribe().getName(), 
										new Set<String>{Event.XLComp__Attended__c.getDescribe().getName()}, 
										XLC.SchemaHelper.DatabaseAction.UPDATE_DATA
									);
        
        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessEvents || !updateAccessEvents){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }

		try{
			Set<String> usersIds = (Set<String>)JSON.deserialize(selectedUsers,Set<String>.class);
			List<Event> trainingEventsList = [SELECT Id, OwnerId, Attended__c FROM Event WHERE WhatId =: trainingModuleId LIMIT 20000];
			for(Event event : trainingEventsList){
				event.Attended__c = usersIds.contains(event.OwnerId);
			}
			if(!trainingEventsList.isEmpty()) {
				update trainingEventsList;
			}
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
	}
}
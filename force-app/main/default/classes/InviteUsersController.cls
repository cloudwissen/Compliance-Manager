/**
*	@description : Apex class to get the list of non-attendee users for a training course
**/
public with sharing class InviteUsersController {
	
	@testVisible
	private static final String CUSTOM_PERMISSION_TO_CHECK = 'Compliance_Access_Training';
	@testVisible
	private static final String TRAINING_RECORD_TYPE_NAME = 'Training';

	/**
	*	@description : Method to save events for each user for all the training modules in a training course
	*	@param trainingCourseId Id of the training course
	*	@param selectedUsers List of selected users
	*	@return void
	**/
	@AuraEnabled
	public static Map<String,String> saveUsers(Id trainingCourseId, String records){
		List<Event> eventsToCreate = new List<Event>();

		//Check user has sufficient access to Query Training Module and Event Data
        Boolean queryAccessTrainingModule = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
												Training_Module__c.sObjectType.getDescribe().getName(),  
												new Set<String>{
																	Training_Module__c.XLComp__Start_Date_Time__c.getDescribe().getName(),
																	Training_Module__c.XLComp__End_Date_Time__c.getDescribe().getName(), 
																	Training_Module__c.XLComp__Training_Course__c.getDescribe().getName()
																}, 
												XLC.SchemaHelper.DatabaseAction.QUERY_DATA
											);
		Boolean queryAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										Event.sObjectType.getDescribe().getName(),
										new Set<String>{	Event.OwnerId.getDescribe().getName(),
															Event.WhatId.getDescribe().getName()
														}, 
										XLC.SchemaHelper.DatabaseAction.QUERY_DATA
									);
        //Check user has sufficient access to Insert Event Data
        Boolean insertAccessEvents = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										Event.sObjectType.getDescribe().getName(),
										new Set<String>{	Event.OwnerId.getDescribe().getName(),
															Event.WhatId.getDescribe().getName(),
															Event.Subject.getDescribe().getName(),
															Event.EndDateTime.getDescribe().getName(),
															Event.StartDateTime.getDescribe().getName(),
															Event.RecordTypeId.getDescribe().getName()
														}, 
										XLC.SchemaHelper.DatabaseAction.INSERT_DATA
									);

        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessTrainingModule || !queryAccessEvents || !insertAccessEvents){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }

		try{
			
			Id trainingRecordTypeId = Event.SObjectType.getDescribe().getRecordTypeInfosByName().containsKey(TRAINING_RECORD_TYPE_NAME) ? Event.SObjectType.getDescribe().getRecordTypeInfosByName().get(TRAINING_RECORD_TYPE_NAME).getRecordTypeId() : null;
			List<SelectSObjectRecordsHelper.Record> recordsList = (List<SelectSObjectRecordsHelper.Record>)JSON.deserialize(records,List<SelectSObjectRecordsHelper.Record>.class);
			Map<Id, Training_Module__c> trainingModulesMap = new Map<Id, Training_Module__c>([SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c,
																	(SELECT OwnerId, WhatId FROM Events)
																		FROM Training_Module__c WHERE Training_Course__c =: trainingCourseId LIMIT 50000]);
			Map<Id, Set<Id>> trainingModulesByUsersMap = getTrainingModulesByUsersMap(trainingModulesMap.values());
			Set<Id> alreadyAddedUserId = new Set<Id>();
			Set<Id> newUsersList = new Set<Id>();
			Set<Id> userIds = SelectSObjectRecordsHelper.getRelatedUserIds(recordsList);
			Map<Id, User> usersMap = new Map<Id, User>(SelectSObjectRecordsHelper.getUsersWithCustomPermission(userIds,CUSTOM_PERMISSION_TO_CHECK));
			for(String userId : usersMap.keySet()){
				for(Id moduleId : trainingModulesMap.keySet()){
					if(!trainingModulesByUsersMap.containsKey(moduleId) || (trainingModulesByUsersMap.containsKey(moduleId) && !trainingModulesByUsersMap.get(moduleId).contains(userId))){
						eventsToCreate.add(new Event(OwnerId=userId,WhatId=moduleId,Subject=trainingModulesMap.get(moduleId).Name,EndDateTime=trainingModulesMap.get(moduleId).End_Date_Time__c,StartDateTime=trainingModulesMap.get(moduleId).Start_Date_Time__c,RecordTypeId=trainingRecordTypeId));
						newUsersList.add(userId);
					}else if(trainingModulesByUsersMap.containsKey(moduleId) && trainingModulesByUsersMap.get(moduleId).contains(userId)){
						alreadyAddedUserId.add(userId);
					}
				}	
			}
			Integer successNumber = 0;
			Integer failureNumber = 0;
			if(!eventsToCreate.isEmpty()) {
				Database.SaveResult[] srList = Database.insert(eventsToCreate, false);
				// Iterate through each returned result
				for (Database.SaveResult sr : srList) {
					if (sr.isSuccess()) {
						successNumber++;
					}
					else {
						failureNumber++;
					}
				}
			}
			Map<String,String> typeStringToMessageMap = new Map<String,String>();
			if(trainingModulesMap.size() == 0){
				typeStringToMessageMap.put('type', 'warning');
				typeStringToMessageMap.put('message',System.Label.Training_Module_Not_Available);
			}else if(successNumber != 0 && failureNumber == 0 && alreadyAddedUserId.size() == 0){
				typeStringToMessageMap.put('type', 'success');
				typeStringToMessageMap.put('message', String.format(System.Label.Invite_Participants_Success_Message,new List<String>{String.valueOf(newUsersList.size())}));
			}else if(successNumber != 0 && alreadyAddedUserId.size() > 0){
				typeStringToMessageMap.put('type', 'warning');
				typeStringToMessageMap.put('message', System.Label.Invite_Participants_Warning_Message);
			}else if(failureNumber == 0 && successNumber == 0 && alreadyAddedUserId.size()>0){
				typeStringToMessageMap.put('type', 'info');
				typeStringToMessageMap.put('message', String.format(System.Label.Participants_Already_Invited_Message,new List<String>{String.valueOf(alreadyAddedUserId.size())}));
			} else{
				typeStringToMessageMap.put('type', 'error');
				typeStringToMessageMap.put('message', String.format(System.Label.Invite_Participants_Error_Message,new List<String>{String.valueOf(newUsersList.size())}));
			}

			return typeStringToMessageMap;
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	*	@description : Method to check Training Course has training modules. Returns true if training course has module(s).
	*	@param trainingCourseId Id of the training course
	*	@return Boolean
	**/
	@AuraEnabled
	public static String getTrainingInfo(Id trainingCourseId){
		Map<String, Object> objectsMap = new Map<String, Object>();

		//Check user has sufficient access to Query Training Module Data
        Boolean queryAccessTrainingModule = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
												Training_Module__c.sObjectType.getDescribe().getName(), 
												new Set<String>{
																	Training_Module__c.XLComp__Start_Date_Time__c.getDescribe().getName(),
																	Training_Module__c.XLComp__End_Date_Time__c.getDescribe().getName()
																}, 
												XLC.SchemaHelper.DatabaseAction.QUERY_DATA
											);
        
        //Throw exception if the user doesn't have sufficient access
        if(!queryAccessTrainingModule){
            throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
        }

		try{
			List<Training_Module__c> trainingModule = [SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c FROM Training_Module__c WHERE Training_Course__c =: trainingCourseId LIMIT 1];
			objectsMap.put('isvalid',trainingModule.size() > 0);
			objectsMap.put('userIds',SelectSObjectRecordsHelper.getUsersWithoutCustomPermission(CUSTOM_PERMISSION_TO_CHECK));
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
		return JSON.serialize(objectsMap);
	}
	
	/**
	*	@description : Method to construct the map of training modules by users
	*	@param trainingModulesList List of training module records
	*	@return Map<Id, Set<Id>> Map of training modules by users
	**/
	@testVisible
	private static Map<Id, Set<Id>> getTrainingModulesByUsersMap(List<Training_Module__c> trainingModulesList){
		Map<Id, Set<Id>> trainingModulesByUsersMap = new Map<Id, Set<Id>>();
		for(Training_Module__c trainingModule : trainingModulesList){
			for(Event event : trainingModule.Events){
				if(trainingModulesByUsersMap.containsKey(event.WhatId)){
					trainingModulesByUsersMap.get(event.WhatId).add(event.OwnerId);
				}else{
					trainingModulesByUsersMap.put(event.WhatId,new Set<Id>{event.OwnerId});
				}
			}
		}
		return trainingModulesByUsersMap;
	}
}
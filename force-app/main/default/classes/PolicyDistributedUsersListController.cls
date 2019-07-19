/**
* @description Apex class to the get the list of users received the given policy
**/
public with sharing class PolicyDistributedUsersListController {

	@testVisible
	private static List<Schema.SObjectField> sObjectFieldsList;
	
	/**
	* @description Method to get the list of notified
	* @param policyId Id of the policy
	* @param fieldSetName API name of the field set to display the columns
	* @return Map<String, Object> Map of datatable column info and actual data
	**/
	@AuraEnabled
	public static Map<String, Object> getUsersList(Id policyId, String fieldSetName){
		Map<String, Object> objectsMap = new Map<String, Object>();
		
		if(policyId != null){
			List<String> fieldsList = new List<String>{'Name'};
			if(!String.isBlank(fieldSetName)){
				List<String> fieldNames = XLC.SchemaHelper.getFieldNamesFromFieldSet(Policy_Notification__c.sObjectType.getDescribe().getName(),fieldSetName);
				fieldsList = (fieldsList.isEmpty() ? fieldsList : fieldNames);
			}
			if(sObjectFieldsList == null){
				sObjectFieldsList = new List<Schema.SObjectField>();
			}

			for(String fd : fieldsList) {
				String objectName = Policy_Notification__c.sObjectType.getDescribe().getName();
				if(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().containsKey(fd)){
					sObjectFieldsList.add(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fd));
				}
			}
		}

		if(policyId != null && !sObjectFieldsList.isEmpty()){

			//Check user has sufficient access to Query Policy Version and Policy Notification Data
			Boolean queryAccessPolicyVersion = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
													Policy_Version__c.sObjectType.getDescribe().getName(), 
													new Set<String>{	Policy_Version__c.XLComp__Policy__c.getDescribe().getName(),
																		'CreatedDate'
																	}, 
													XLC.SchemaHelper.DatabaseAction.QUERY_DATA
												);
			Boolean queryAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
														Policy_Notification__c.sObjectType.getDescribe().getName(), 
														new Set<String>(getFields()),
														XLC.SchemaHelper.DatabaseAction.QUERY_DATA
													);
			
			//Throw exception if the user doesn't have sufficient access
			if(!queryAccessPolicyVersion || !queryAccessPolicyNotification){
				throw new AuraHandledException(Label.XLC.Insufficient_Privileges); 
			}

			// get the lastest policy version from current policy
            List<Policy_Version__c> policyVersionsList = [SELECT Id FROM Policy_Version__c WHERE Policy__c =: policyId ORDER BY CreatedDate DESC LIMIT 1];
            if(!policyVersionsList.isEmpty()){
                objectsMap.put('data',getNotifiedUsers(policyVersionsList[0].Id));
                objectsMap.put('columns',getColumns());
            }
		}

		objectsMap.put('transientMessageFieldLabel',Policy_Notification__c.Transient_Message__c.getDescribe().getLabel());
		return objectsMap;
	}

	/**
	* @description Method to get the list of notified users 
	* @param policyVersionId lastest policy version id for a given policy
	* @return List<sObject> List of notified users
	**/
    @TestVisible
	private static List<sObject> getNotifiedUsers(Id policyVersionId){
		if(policyVersionId == null){ return new List<SObject>(); }

		String soqlQuery = 'SELECT '+String.join(getFields(),',')+' FROM '+Policy_Notification__c.sObjectType.getDescribe().getName()+
								' WHERE '+Policy_Notification__c.Policy_Version__c.getDescribe().getName()+' = \''+policyVersionId+'\''+
									' LIMIT 50000';
		return (List<sObject>)Database.query(soqlQuery);
	}


	/**
	* @description Method to get the list of data table fields
	* @return List<XLC.DataTableField > List of datatable column info
	**/
	public static List<XLC.DataTableField> getColumns(){
		List<XLC.DataTableField> datatableFieldsList = new List<XLC.DataTableField>();
		for(Schema.SObjectField sObjectField : sObjectFieldsList){
			String fieldDataType = String.valueOf(sObjectField.getDescribe().getType()).toLowerCase();
			datatableFieldsList.add(new XLC.DataTableField(sObjectField.getDescribe().getLabel(),sObjectField.getDescribe().getName(),fieldDataType,true));
		}
		return datatableFieldsList;
	}

	/**
	* @description Method to get the list of fields from field set member
	* @return List<String> List of fields from fieldset.
	**/
    @TestVisible
	private static List<String> getFields(){
		List<String> fieldsList = new List<String>();
		for(Schema.SObjectField sObjectField : sObjectFieldsList){
			fieldsList.add(sObjectField.getDescribe().getName());
		}
		return fieldsList;
	}

	/**
	* @description Method to notify the selected users
	* @param recordIds List of selected record ids
	* @param message Custom message to send it to users
	* @return Map<String, String> Map contains message to be displayed after notification
	**/
    @AuraEnabled
	public static Map<String,String> sendNotifications(String recordIds, String message){
		Map<String,String> typeStringToMessageMap = new Map<String,String>();
		if(!String.isBlank(recordIds)){
			List<Id> policyNotifiedUserIds = (List<Id>)JSON.deserialize(recordIds,List<Id>.class);
			if(!policyNotifiedUserIds.isEmpty()){

				//Check user has sufficient access to Query Policy Notification Data and Update Policy Notification Data
				Boolean queryAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
															Policy_Notification__c.sObjectType.getDescribe().getName(),
															new Set<String>{	Policy_Notification__c.XLComp__Send_Notification__c.getDescribe().getName(),
																				Policy_Notification__c.XLComp__Policy_Version__c.getDescribe().getName(),
																				Policy_Notification__c.XLComp__Transient_Message__c.getDescribe().getName()
																			}, 
															XLC.SchemaHelper.DatabaseAction.QUERY_DATA
														);
				Boolean updateAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
															Policy_Notification__c.sObjectType.getDescribe().getName(),
															new Set<String>{	Policy_Notification__c.XLComp__Send_Notification__c.getDescribe().getName(),
																				Policy_Notification__c.XLComp__Transient_Message__c.getDescribe().getName()
																			}, 
															XLC.SchemaHelper.DatabaseAction.UPDATE_DATA
														);
				
				//Throw exception if the user doesn't have sufficient access
				if(!queryAccessPolicyNotification || !updateAccessPolicyNotification){
					throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
				}

				List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Send_Notification__c, Policy_Version__c, Transient_Message__c FROM Policy_Notification__c WHERE Id IN: policyNotifiedUserIds LIMIT 50000];
				for(Policy_Notification__c policyNotification : policyNotificationsList){
					policyNotification.Send_Notification__c = true;
					policyNotification.Transient_Message__c = message;
				}
				try{
					if(!policyNotificationsList.isEmpty()) {
						update policyNotificationsList;
						typeStringToMessageMap.put('type','success');
						typeStringToMessageMap.put('message',String.format(System.Label.Policy_Notification_Success_Message, new List<String>{String.valueOf(policyNotificationsList.size())}));
					}
				}catch(Exception ex){
					throw new AuraHandledException(ex.getMessage());
				}
			}
		}
		return typeStringToMessageMap;
	}

	/**
	* @description Method to delete policy notification record
	* @param policyNotificationId Id of the policy notification record to delete
	* @param Map<String,String> Map contains message to be displayed as a toast and user id
	**/
    @AuraEnabled
	public static Map<String,String> removeNotifiedUser(Id policyNotificationId){
		Map<String, String> infoMap = new Map<String,String>();
		
		if(policyNotificationId != null){

			//Check user has sufficient access to Query Policy Notification Data and Delete Policy Notification Data
			Boolean queryAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
														Policy_Notification__c.sObjectType.getDescribe().getName(), 
														new Set<String>{'OwnerId'}, 
														XLC.SchemaHelper.DatabaseAction.QUERY_DATA
													);
			Boolean deleteAccessPolicyNotification = Policy_Notification__c.sObjectType.getDescribe().isDeletable();
			
			//Throw exception if the user doesn't have sufficient access
			if(!queryAccessPolicyNotification || !deleteAccessPolicyNotification){
				throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
			}

			List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Owner.Name, OwnerId FROM Policy_Notification__c WHERE Id =: policyNotificationId LIMIT 1];
			if(!policyNotificationsList.isEmpty()){
				infoMap.put('message',String.format(System.Label.Confirm_Policy_User_Removed, new List<String>{policyNotificationsList[0].Owner.Name}));
				infoMap.put('userId',policyNotificationsList[0].OwnerId);
				delete policyNotificationsList;
			} 
		}
		return infoMap;
	}
}
/**
* @description Apex class manages the policy distribution 
**/
public with sharing class PolicyDistributionController{

	@testVisible
	private static final String CUSTOM_PERMISSION_TO_CHECK = 'Compliance_Policy_Distribution';

	/**
	* @description Method to get transient message field label
	* @param policyId Id of the policy
	* @return String Transient Message field label
	**/
	@AuraEnabled
	public static String getPolicyInfo(Id policyId){
		Map<String,Object> objectsMap = new Map<String,Object>{'policy'=>null};

		//Check user has sufficient access to Query Policy and Policy Version Data
		Boolean queryAccessPolicy = grc__Policy__c.sObjectType.getDescribe().isAccessible();
		
		Boolean queryAccessPolicyVersion = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
												Policy_Version__c.sObjectType.getDescribe().getName(), 
												new Set<String>{Policy_Version__c.XLComp__Version__c.getDescribe().getName()}, 
												XLC.SchemaHelper.DatabaseAction.QUERY_DATA
											);
		
		//Throw exception if the user doesn't have sufficient access
		if(!queryAccessPolicy || !queryAccessPolicyVersion){
			throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
		}

		// fetch policy 
		List<grc__Policy__c> policiesList = [SELECT Id, Name, (SELECT Version__c FROM Policy_Versions__r ORDER BY Version__c DESC LIMIT 1)
												FROM grc__Policy__c WHERE Id =: policyId LIMIT 1];
		if(! policiesList.isEmpty()) {
			objectsMap.put('policy', JSON.serialize(policiesList[0]));
		}
		objectsMap.put('transientMessageFieldLabel',Policy_Notification__c.Transient_Message__c.getDescribe().getLabel());
		objectsMap.put('userIds',getUserIdsToExclude(policyId));
		return JSON.serialize(objectsMap);
	}


	/**
	* @description Method to get the list of users ids to exclude from search
	* @param policyId Id of the policy record
	* @return Set<Id> List of user ids to exlcude
	**/
	@testVisible
	private static Set<Id> getUserIdsToExclude(Id policyId){
		Set<Id> userIdsToExclude = new Set<Id>();
		userIdsToExclude.addAll(SelectSObjectRecordsHelper.getUsersWithoutCustomPermission(CUSTOM_PERMISSION_TO_CHECK));
		userIdsToExclude.addAll(getNotifiedUsers(policyId));
		return userIdsToExclude;
	}

	/**
	* @description Method to get notified users from a policy
	* @param policyId Id of the policy record
	* @return Set<Id> List of notified users from policy
	**/
	@testVisible
	private static Set<Id> getNotifiedUsers(Id policyId){
		Set<Id> notifiedUsers = new Set<Id>();
		if(policyId != null){
			List<Policy_Version__c> policyVersionsList = [SELECT Id FROM Policy_Version__c WHERE Policy__c =: policyId ORDER BY CreatedDate DESC LIMIT 1];
			if(!policyVersionsList.isEmpty()){
				notifiedUsers.addAll(PolicyDistributionHelper.getPolicyNotifications(policyVersionsList[0].Id));
			}
		}
		return notifiedUsers;
	}

	/**
	* @description Method to distribute policy to selected users
	* @param policyId Id of the policy record
	* @param records List of selected records
	* @param message Custom message to send it to users
	* @return Map<String, String> Map contains message to be displayed after distribution
	**/
	@AuraEnabled
	public static Map<String,String> distributePolicy(Id policyId, String records, String message){

		//Check user has sufficient access to Query Policy, Policy Version and Policy Notification Data and has access to insert Policy Notifications
		Boolean queryAccessPolicy = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
										grc__Policy__c.sObjectType.getDescribe().getName(), 
										new Set<String>(), 
										XLC.SchemaHelper.DatabaseAction.QUERY_DATA
									);
		Boolean queryAccessPolicyVersion = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
												Policy_Version__c.sObjectType.getDescribe().getName(), 
												new Set<String>{	Policy_Version__c.XLComp__Policy__c.getDescribe().getName(),
																	'CreatedDate'
																}, 
												XLC.SchemaHelper.DatabaseAction.QUERY_DATA
											);
		Boolean queryAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
													Policy_Notification__c.sObjectType.getDescribe().getName(), 
													new Set<String>{	Policy_Notification__c.OwnerId.getDescribe().getName(),
																		Policy_Notification__c.XLComp__Policy_Version__c.getDescribe().getName()
																	}, 
													XLC.SchemaHelper.DatabaseAction.QUERY_DATA
												);
		Boolean insertAccessPolicyNotification = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
													Policy_Notification__c.sObjectType.getDescribe().getName(), 
													new Set<String>{	Policy_Notification__c.OwnerId.getDescribe().getName(),
																		Policy_Notification__c.XLComp__Policy_Version__c.getDescribe().getName(),
																		Policy_Notification__c.XLComp__Send_Notification__c.getDescribe().getName(),
																		Policy_Notification__c.XLComp__Transient_Message__c.getDescribe().getName()
																	}, 
													XLC.SchemaHelper.DatabaseAction.INSERT_DATA
												);

		//Throw exception if the user doesn't have sufficient access
		if(!queryAccessPolicy || !queryAccessPolicyVersion || !queryAccessPolicyNotification || !insertAccessPolicyNotification){
			throw new AuraHandledException(Label.XLC.Insufficient_Privileges); 
		}

		try{
			if(policyId != null && !String.isBlank(records)){
				List<SelectSObjectRecordsHelper.Record> recordsList = (List<SelectSObjectRecordsHelper.Record>)JSON.deserialize(records,List<SelectSObjectRecordsHelper.Record>.class);
				List<Policy_Version__c> policyVersionsList = [SELECT Id FROM Policy_Version__c WHERE Policy__c =: policyId ORDER BY CreatedDate DESC LIMIT 1];
				Map<String,String> typeStringToMessageMap = new Map<String,String>();	
				Set<Id> userIds = new Set<Id>();
				List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>();
				// check policy distribution list is not empty
				if(!policyVersionsList.isEmpty()){
                   	userIds = SelectSObjectRecordsHelper.getRelatedUserIds(recordsList);
					Map<Id, User> usersMap = new Map<Id, User>(SelectSObjectRecordsHelper.getUsersWithCustomPermission(userIds,CUSTOM_PERMISSION_TO_CHECK));
					// create policy distribution users list and policy shares 
					PolicyDistributionHelper.createPolicyShares(policyId,usersMap.keySet());
					policyNotificationsList = PolicyDistributionHelper.createPolicyNotifications(policyVersionsList[0].Id,usersMap.keySet(),message);
				}
				if(userIds.size() == 0) {
					typeStringToMessageMap.put('type','info');
					typeStringToMessageMap.put('message', System.Label.No_Users_To_Distribute);
				} else if(!policyNotificationsList.isEmpty()) {
					insert policyNotificationsList;
					typeStringToMessageMap.put('type','success');
					typeStringToMessageMap.put('message',String.format(System.Label.Policy_Distribution_Success_Message, new List<String>{String.valueOf(policyNotificationsList.size())}));
				} else {
					typeStringToMessageMap.put('type','info');
					typeStringToMessageMap.put('message', System.Label.Policy_Already_Distributed_Message);
				}
				return typeStringToMessageMap;
			}
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
		return null;
	}
}
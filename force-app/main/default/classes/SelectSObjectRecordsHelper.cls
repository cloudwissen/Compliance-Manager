/**
* @description Helper class for SelectSObjectRecordsController
**/
public with sharing class SelectSObjectRecordsHelper {
	
	@testVisible
	private static final String BUSINESS_UNIT_SHARING_GROUP_NAME_FIELD = 'risk__sharing_group_name__c';
	/**
	* @description Method to check Risk__Sharing_Group_Name__c is available on Business Unit.
	* @return 	  Boolean which returns true or false based on the check if the field is present
	**/
	public static Boolean isSharingGroupFieldAvailable() {
		return grc__Business_Unit__c.sObjectType.getDescribe().fields.getMap().keySet().contains(BUSINESS_UNIT_SHARING_GROUP_NAME_FIELD);
	}


	/**
	* @description Method to get the document record by developer name
	* @return Document Business unit icon document record
	**/
	public static Document getDocumentByDeveloperName(String developerName){
		List<Document> documentsList = [SELECT Id FROM Document WHERE DeveloperName =: developerName LIMIT 1];
		return !documentsList.isEmpty() ? documentsList[0] : null;
	}

	/**
	* @description Method to get the list of users without custom permission
	* @description customPermissionName Name of the custom permission to check
	* @return Set<Id> List of user ids not having the custom permission
	**/
	public static Set<Id> getUsersWithoutCustomPermission(String customPermissionName) {
		Set<Id> permissionSetIds = new Set<Id>();
		// query setup entity access 
		for(SetupEntityAccess entityAccess : [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName =: customPermissionName)]){
			permissionSetIds.add(entityAccess.ParentId);
		}
		return new Map<Id,User>([SELECT Id, Name FROM User WHERE Id NOT IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN: permissionSetIds) LIMIT 30000]).keySet();
	}

	/**
	* @description Method to get the users with given custom permission
	* @param userIds Set of user ids
	* @param customPermissionToCheck Custom permission to check against given users
	* @return List<User> List of users with custom permission
	**/
	public static List<User> getUsersWithCustomPermission(Set<Id> userIds, String customPermissionToCheck){
		Set<Id> permissionSetIds = new Set<Id>();
		// query setup entity access 
		for(SetupEntityAccess entityAccess : [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName =: customPermissionToCheck)]){
			permissionSetIds.add(entityAccess.ParentId);
		}
		// query permission sets 
		return permissionSetIds.isEmpty() ? new List<User>() : [SELECT Id, Name FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN: permissionSetIds) AND Id IN: userIds ORDER BY Name LIMIT 30000];	
	}

	/**
	* @description Method to get the list of business unit public group names
	* @return Set<String> List of business unit sharing group names
	**/
	public static Set<String> getBusinessUnitPublicGroupNames(Set<Id> businessUnitIds){
		Set<String> businessUnitPublicGroupNamesList = new Set<String>();
		if(isSharingGroupFieldAvailable()) {
			//Using Dynamic SOQL to avoid adding dependency on Risk Manager
			List<grc__business_unit__c> businessUnits = Database.query('SELECT Risk__Sharing_Group_Name__c FROM grc__business_unit__c WHERE Id IN: businessUnitIds');
		
			for(grc__Business_Unit__c businessUnit : businessUnits){
				businessUnitPublicGroupNamesList.add((String)businessUnit.get('Risk__Sharing_Group_Name__c')+'-Xactium-R');
				businessUnitPublicGroupNamesList.add((String)businessUnit.get('Risk__Sharing_Group_Name__c')+'-Xactium-R/W');
			}
		}
		return businessUnitPublicGroupNamesList;
	}

	/**
	* @description Method to create the map of sobject name and its list of ids
	* @param records List of records
	* @return Map<String, Set<Id> Map of sobject name and its list of ids
	**/
	public static Map<String, Set<Id>> getsObjectByRecordIdsMap(List<Record> records){
		Map<String, Set<Id>> sObjectByRecordIdsMap = new Map<String, Set<Id>>();
		for(Record record : records){
			String sObjectName = getsObjectNameFromId((Id)record.Id);
			if(sObjectByRecordIdsMap.containsKey(sObjectName)){
				sObjectByRecordIdsMap.get(sObjectName).add((Id)record.Id);
			}else sObjectByRecordIdsMap.put(sObjectName,new Set<Id>{(Id)record.Id});
		}
		return sObjectByRecordIdsMap;
	}

	/**
	* @description Method to retrieve related user ids for BU Groups, Public Groups and Roles.
	* @param List<Record> list of Record wrapper instances
	* @return Set<Id> - Set of related user Ids
	**/
	public static Set<Id> getRelatedUserIds(List<Record> recordsList) {
		Set<Id> userIds = new Set<Id>();
		Map<String, Set<Id>> sObjectByRecordIdsMap = getsObjectByRecordIdsMap(recordsList);
		if(sObjectByRecordIdsMap.keySet().contains('user')){
			userIds.addAll(sObjectByRecordIdsMap.get('user')); 
		}
		if(sObjectByRecordIdsMap.keySet().contains('grc__business_unit__c')){
			Set<String> businessUnitPublicGroupNamesList = getBusinessUnitPublicGroupNames(sObjectByRecordIdsMap.get('grc__business_unit__c'));
			for(GroupMember groupMember : [SELECT UserOrGroupId FROM  GroupMember WHERE Group.Name IN: businessUnitPublicGroupNamesList]){
				if(isUserType(groupMember.UserOrGroupId)) {
					userIds.add(groupMember.UserOrGroupId);
				}
			}
		}
		if(sObjectByRecordIdsMap.keySet().contains('group')){
			for(GroupMember groupMember : [SELECT UserOrGroupId FROM  GroupMember WHERE GroupId IN: sObjectByRecordIdsMap.get('group')]){
				if(isUserType(groupMember.UserOrGroupId)) {
					userIds.add(groupMember.UserOrGroupId);
				}
			}
		}
		if(sObjectByRecordIdsMap.keySet().contains('userrole')){
			Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, FullPhotoUrl FROM User WHERE UserRoleId IN: sObjectByRecordIdsMap.get('userrole')]);
			userIds.addAll(usersMap.keySet());
		}
		return userIds;
	}

	/**
	* @description Method to get check Id type is user Id type.
	* @param recordId Id of the record.
	* @return Boolean true if record id type is user.
	**/
	private static Boolean isUserType(Id recordId) {
		if(recordId.getSobjectType() == Schema.User.SObjectType) {
			return true;
		}
		return false;
	}

	/**
	* @description Method to get sobject name from the record Id
	* @param recordId Id of the record
	* @return String sObject name of the record
	**/
	public static String getsObjectNameFromId(Id recordId){
		return recordId.getSobjectType().getDescribe().getName().toLowerCase();
	}

	/**
	* @description Record Wrapper
	**/
	public class Record{
		public String Id;
		public String Name;
	}
}
/**
* @description Policy Version Helper
**/
public with sharing class PolicyVersionHelper {
	
	/**
	* @description Method to create policy notification record for each policy shared user
	* @param policyVersionsList List of policy version records
	*/
	public static void createPolicyNotifications(List<Policy_Version__c> policyVersionsList){
		List<Policy_Notification__c> policyNotificationsToCreate = new List<Policy_Notification__c>();
		Set<Id> policyIds = getPolicyIds(policyVersionsList);
		Map<Id, grc__Policy__c> policiesMap = new Map<Id, grc__Policy__c>([SELECT Id, (SELECT UserOrGroupId FROM Shares WHERE RowCause =: PolicyDistributionHelper.POLICY_APEX_SHARING_REASON) FROM grc__Policy__c]);
		for(Policy_Version__c policyVersion : policyVersionsList){
			if(policiesMap.containsKey(policyVersion.Policy__c)){
				for(grc__Policy__Share policyShare : policiesMap.get(policyVersion.Policy__c).Shares){
					policyNotificationsToCreate.add(new Policy_Notification__c(Policy_Version__c=policyVersion.Id,OwnerId=policyShare.UserOrGroupId));
				}
			}
		}
		try{
			if(!policyNotificationsToCreate.isEmpty()) insert policyNotificationsToCreate;
		}catch(Exception ex){
			throw new PolicyDistributionException(ex.getMessage());
		}
	}

	/**
	* @description Method to delete content docuemnts and remove content document id from policies
	* @param policyVersionsList List of policy version records
	*/
	public static void deleteContentDocuments(List<Policy_Version__c> policyVersionsList){
		List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
		Set<Id> policyIds = getPolicyIds(policyVersionsList);
		Map<Id, grc__Policy__c> policiesMap = new Map<Id, grc__Policy__c>([SELECT Id, Content_Document_Id__c, (SELECT Id FROM Policy_Versions__r LIMIT 1) FROM grc__Policy__c WHERE Id IN: policyIds
																				AND Content_Document_Id__c != null]);
		// delete content document and update policies
		for(grc__Policy__c policy : policiesMap.values()){
			if(policy.Policy_Versions__r.isEmpty()){
				contentDocumentsToDelete.add(new ContentDocument(Id=policy.Content_Document_Id__c));
				policy.Content_Document_Id__c = null;
			}
		}
		try{
			if(!contentDocumentsToDelete.isEmpty()) {
				if(Schema.sObjectType.ContentDocument.isDeletable()) {
					delete contentDocumentsToDelete;
				} else {
					throw new PolicyDistributionException(System.Label.Error_Unable_To_Delete_ContentDocument);
				}
				update policiesMap.values();
			}
		}catch(Exception ex){
			throw new PolicyDistributionException(ex.getMessage());
		}
	}

	/**
	* @description Method to get policy ids from policy version
	* @param policyVersionsList List of policy version records
	* @return Set<Id> Set of policy ids
	*/
	@testVisible
	private static Set<Id> getPolicyIds(List<Policy_Version__c> policyVersionsList){
		Set<Id> policyIds = new Set<Id>();
		for(Policy_Version__c policyVersion : policyVersionsList){
			policyIds.add(policyVersion.Policy__c);
		}
		return policyIds; 
	}
}

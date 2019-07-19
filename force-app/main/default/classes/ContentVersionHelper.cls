/**
* @description Trigger helper for content version
**/
public with sharing class ContentVersionHelper {

	/**
	* @description Method to populate the map of content document ids by content version ids
	* @param contentVersionsList List of content version records
	* @return Map<Id, ContentVersion> map of content document ids by content version records
	*/
	public static Map<Id, ContentVersion> fetchContentDocumentIdByContentVersionMap(List<ContentVersion> contentVersionsList){
		Map<Id, ContentVersion> contentDocumentByContentVersionMap = new Map<Id, ContentVersion>();
		for(ContentVersion contentVersion : contentVersionsList){
			contentDocumentByContentVersionMap.put(contentVersion.ContentDocumentId,contentVersion);
		}
		return contentDocumentByContentVersionMap;
	}
    
    /**
	* @description Method to get linked entity ids from content documents links
	* @param sObjectTypesList List of linked sobject types to look for
	* @param contentDocumentIds List of content document ids
	* @return Set<Id> List of linked entity ids
	*/
	public static Set<Id> getLinkedEntityIds(Set<String> sObjectTypesList, Set<Id> contentDocumentIds){
		Set<Id> linkedEntityIds = new Set<Id>();
		// get the content documents 
		List<ContentDocumentLink> contentDocumentLinksList = [SELECT ContentDocumentId, LinkedEntityId, LinkedEntity.Type FROM ContentDocumentLink 
																	WHERE ContentDocumentId IN: contentDocumentIds LIMIT 50000];
		for(ContentDocumentLink contentDocumentLink : contentDocumentLinksList){
			if(sObjectTypesList.contains(contentDocumentLink.LinkedEntity.Type)) linkedEntityIds.add(contentDocumentLink.LinkedEntityId);
		}	
		return linkedEntityIds;
	}


    /**
	* @description Method to populate the map of policy ids to lastet content version
	* @param policyIds List of policy ids
	* @param contentDocumentByContentVersionMap map of content document ids by content version records
	* @return Map<Id, Integer> map of policy ids by latest content version
	*/
	public static Map<Id,Integer> getPolicyVersionsMap(Set<Id> policyIds,Map<Id, ContentVersion> contentDocumentByContentVersionMap){
		Map<Id, Integer> policyByVersionMap = new Map<Id, Integer>();
		Map<Id, Id> contentDocumentByPoliciesMap = getContentDocumentIdsFromPolicies(policyIds);
		for(Id contentDocumentId : contentDocumentByPoliciesMap.keySet()){
			if(contentDocumentByContentVersionMap.containsKey(contentDocumentId)){
				policyByVersionMap.put(contentDocumentByPoliciesMap.get(contentDocumentId),Integer.valueOf(contentDocumentByContentVersionMap.get(contentDocumentId).VersionNumber));
			}
		}
		return policyByVersionMap;
	}


	/**
	* @description Method to get content document ids from policies
	* @param policyIds List of policy ids
	* @return Map<Id, Id> map of content document ids by policy ids
	*/
	@testVisible
	private static Map<Id,Id> getContentDocumentIdsFromPolicies(Set<Id> policyIds){
		Map<Id, Id> contentDocumentByPoliciesMap = new Map<Id, Id>();
		for(grc__Policy__c policy : [SELECT Id, Content_Document_Id__c FROM grc__Policy__c WHERE Content_Document_Id__c != null AND Id IN: policyIds LIMIT 20000]){
			contentDocumentByPoliciesMap.put(policy.Content_Document_Id__c,policy.Id);
		}
		return contentDocumentByPoliciesMap;
	}

	/**
	* @description Method to create policy version 
	* @param policyByVersionMapmap of policy ids by latest content version
	*/
	public static void createPolicyVersion(Map<Id, Integer> policyByVersionMap){
		List<Policy_Version__c> policyVersionsList = new List<Policy_Version__c>();
		for(Id policyId : policyByVersionMap.keySet()){
			policyVersionsList.add(new Policy_Version__c(Policy__c=policyId,Version__c=policyByVersionMap.get(policyId)));
		}
		try{
			if(!policyVersionsList.isEmpty()) insert policyVersionsList;
		}catch(Exception ex){
			throw new PolicyDistributionException(ex.getMessage());
		}
	}
}

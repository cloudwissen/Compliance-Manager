/**
* @description Trigger handler for content version
**/
public with sharing class ContentVersionTriggerHandler extends TriggerHandler{
	
	/**
	* @description Function to handle the after insert trigger event
	*/
	public override void afterInsert(){
		Map<Id, ContentVersion> contentDocumentByContentVersionMap = ContentVersionHelper.fetchContentDocumentIdByContentVersionMap((List<ContentVersion>)trigger.new);
		Set<Id> policyIds = ContentVersionHelper.getLinkedEntityIds(new Set<String>{grc__Policy__c.sObjectType.getDescribe().getName()},contentDocumentByContentVersionMap.keySet());
		Map<Id, Integer> policyByVersionMap = ContentVersionHelper.getPolicyVersionsMap(policyIds,contentDocumentByContentVersionMap);
		ContentVersionHelper.createPolicyVersion(policyByVersionMap);
	}
}
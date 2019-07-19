/**
* @description Trigger handler for policy
**/
public with sharing class PolicyTriggerHandler extends TriggerHandler{
	
	/**
	* @description Function to handle the after update trigger event
	*/
	public override void afterUpdate(){
		Set<Id> changedContentDocumentPolicies = PolicyHelper.getChangedDocumentIdPolicies(Trigger.oldMap,Trigger.new);
		//validate removing content document id from policy
		if(!changedContentDocumentPolicies.isEmpty()){
			PolicyHelper.validatePolicyDocumentIds(Trigger.oldMap,Trigger.new,changedContentDocumentPolicies); 
			PolicyHelper.createPolicyVersion(Trigger.new,changedContentDocumentPolicies);
			Map<Id, contentDocumentLink> linkedEntityIdByContentDocumentLinkMap = PolicyHelper.getContentDocumentLinks(new Set<String>{grc__Policy__c.sObjectType.getDescribe().getName()});
			PolicyHelper.updateContentDocumentShareType(trigger.newMap,linkedEntityIdByContentDocumentLinkMap);
		}
		PolicyHelper.updatePolicyOwnersOnPolicyNotificationShares((List<grc__Policy__c>)trigger.new,(Map<Id,grc__Policy__c>)trigger.oldMap);
	}
}

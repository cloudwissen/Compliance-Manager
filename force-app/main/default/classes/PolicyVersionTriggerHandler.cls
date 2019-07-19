/**
* @description Trigger handler for policy version
**/
public with sharing class PolicyVersionTriggerHandler extends TriggerHandler{

	/**
	* @description Function to handle the after insert trigger event
	*/
	public override void afterInsert(){
		PolicyVersionHelper.createPolicyNotifications((List<Policy_Version__c>)trigger.new);
	}

	/**
	* @description Function to handle the after delete trigger event
	*/
	public override void afterDelete(){
		PolicyVersionHelper.deleteContentDocuments((List<Policy_Version__c>)trigger.old);
	}
}

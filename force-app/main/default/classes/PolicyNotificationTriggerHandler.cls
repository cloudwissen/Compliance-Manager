/**
* @description Trigger handler for policy notification
**/
public with sharing class PolicyNotificationTriggerHandler extends TriggerHandler{

	/**
	* @description Function to handle the after insert trigger event
	*/
	public override void afterInsert(){
		Map<Id,List<Policy_Notification__c>> policyNotificationsByPolicyOwnerIdMap = PolicyNotificationHelper.getPolicyNotificationsByPolicyOwnerId((List<Policy_Notification__c>)trigger.new);
		PolicyNotificationHelper.createPolicyNotificationSharesForPolicyOwners(policyNotificationsByPolicyOwnerIdMap);
	}
}

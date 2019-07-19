/**
* @description Helper class for policy distribution 
**/
public without sharing class PolicyDistributionHelper {

    private static final String POLICY_DEFAULT_ACCESS_LEVEL = 'Read';
    public static final String POLICY_APEX_SHARING_REASON = Schema.grc__Policy__Share.rowCause.XLComp__Policy_Viewer__c;
    
    /**
	* @description Method to create policy share records
	* @param policyId Id of the policy
    * @param userIds Set of user ids
	**/
	public static void createPolicyShares(Id policyId,Set<Id> userIds){
		List<grc__Policy__Share> policySharesList = new List<grc__Policy__Share>();
		Set<Id> policySharedUsers = getPolicySharedUsers(policyId);
        for(Id userId : userIds){
			if(!policySharedUsers.contains(userId)){
				policySharesList.add(new grc__Policy__Share(UserOrGroupId=userId,RowCause=POLICY_APEX_SHARING_REASON,AccessLevel=POLICY_DEFAULT_ACCESS_LEVEL,ParentId=policyId));
			}
        }
        insert policySharesList;
	}

    /**
	* @description Method to create policy share records
	* @param latestPolicyVersionId Lastest policy version id
    * @param userIds Set of user ids
	* @return List<Policy_Notification__c> list of policy notifications created for lastest policy version
	**/
	public static List<Policy_Notification__c> createPolicyNotifications(Id latestPolicyVersionId,Set<Id> userIds,String message){
		List<Policy_Notification__c> policyNotificationsList = new List<Policy_Notification__c>();
        Set<Id> policyNotifiedUsers = getPolicyNotifications(latestPolicyVersionId);
        for(Id userId : userIds){
            if(!policyNotifiedUsers.contains(userId)){
                policyNotificationsList.add(new Policy_Notification__c(Policy_Version__c=latestPolicyVersionId,OwnerId=userId,Send_Notification__c=true,Transient_Message__c=message));
            }
        }
        return policyNotificationsList;
	}

    /**
	* @description Method to get the list of policy distributed users
	* @param lastestPolicyVersionId Id of the latest policy version
	* @return Set<Id> List of policy distributed users
	**/
	public static Set<Id> getPolicyNotifications(Id lastestPolicyVersionId){
		Set<Id> policyNotifiedUsers = new Set<Id>();
		// fetch policy notified users 
		for(Policy_Notification__c policyNotification : [SELECT OwnerId FROM Policy_Notification__c WHERE Policy_Version__c =: lastestPolicyVersionId LIMIT 50000]){
			policyNotifiedUsers.add(policyNotification.OwnerId);
		}
		return policyNotifiedUsers;
	}

	/**
	* @description Method to get the list of policy shared users
	* @param policyId Id of the policy
	* @return Set<Id> List of policy shared users
	**/
	@testVisible
	private static Set<Id> getPolicySharedUsers(Id policyId){
		Set<Id> userIds = new Set<Id>();
		for(grc__Policy__Share policyShare : [SELECT UserOrGroupId FROM grc__Policy__Share WHERE ParentId =: policyId AND RowCause =: POLICY_APEX_SHARING_REASON]){
			if(policyShare.UserOrGroupId.getSObjectType().getDescribe().getName() == User.sObjectType.getDescribe().getName()){
				userIds.add(policyShare.UserOrGroupId);
			}
		}
		return userIds;
	}
}

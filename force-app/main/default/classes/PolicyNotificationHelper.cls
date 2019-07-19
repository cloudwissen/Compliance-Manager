/**
* @description Helper for policy notification
**/
public without sharing class PolicyNotificationHelper {

    public static final String POLICY_OWNER_APEX_SHARING_REASON = Schema.Policy_Notification__Share.rowCause.XLComp__Policy_Owner__c;
    private static final String POLICY_NOTIFICATION_DEFAULT_ACCESS_LEVEL = 'Read';

    /**
    * @description Method to used to get the policy owner
    * @param policyNotificationsList List of policy notification records
    * @return Map<Id,Policy_Notification__c> Map of policy notifications by policy owner
    */
    public static Map<Id,List<Policy_Notification__c>> getPolicyNotificationsByPolicyOwnerId(List<Policy_Notification__c> policyNotificationsList){
        Map<Id,List<Policy_Notification__c>> policyNotificationsByPolicyOwnerIdMap = new Map<Id,List<Policy_Notification__c>>();
        Set<Id> policyVersionIds = new Set<Id>();
        for(Policy_Notification__c policyNotification : policyNotificationsList){
            if(policyNotification.Policy_Version__c != null){
                policyVersionIds.add(policyNotification.Policy_Version__c);
            }
        }   
        // get policy versions
        if(!policyVersionIds.isEmpty()){
            Map<Id, Policy_Version__c> policyVersionsMap = new  Map<Id, Policy_Version__c>([SELECT Id, Policy__r.OwnerId FROM Policy_Version__c WHERE Id IN: policyVersionIds LIMIT 50000]);
            for(Policy_Notification__c policyNotification : policyNotificationsList){
                if(policyNotification.Policy_Version__c != null && policyVersionsMap.containsKey(policyNotification.Policy_Version__c)){
                    if(policyNotificationsByPolicyOwnerIdMap.containsKey(policyVersionsMap.get(policyNotification.Policy_Version__c).Policy__r.OwnerId)){
                        policyNotificationsByPolicyOwnerIdMap.get(policyVersionsMap.get(policyNotification.Policy_Version__c).Policy__r.OwnerId).add(policyNotification);
                    }else{
                        policyNotificationsByPolicyOwnerIdMap.put(policyVersionsMap.get(policyNotification.Policy_Version__c).Policy__r.OwnerId,new List<Policy_Notification__c>{policyNotification});
                    }
                }
            }   
        }
        return policyNotificationsByPolicyOwnerIdMap;
    }

    /**
    * @description Method to create policy notification share record for policy owner
    * @param policyNotificationsByPolicyOwnerIdMap Map of policy notifications by policy owner
    **/
    public static void createPolicyNotificationSharesForPolicyOwners(Map<Id,List<Policy_Notification__c>> policyNotificationsByPolicyOwnerIdMap){
        List<Policy_Notification__Share> policyNotificationSharesList = new List<Policy_Notification__Share>();
        for(Id policyOwnerId : policyNotificationsByPolicyOwnerIdMap.keySet()){
            for(Policy_Notification__c policyNotification : policyNotificationsByPolicyOwnerIdMap.get(policyOwnerId)){
                policyNotificationSharesList.add(new Policy_Notification__Share(UserOrGroupId=policyOwnerId,RowCause=POLICY_OWNER_APEX_SHARING_REASON,AccessLevel=POLICY_NOTIFICATION_DEFAULT_ACCESS_LEVEL,ParentId=policyNotification.Id));
            }
        }
        try{
            if(!policyNotificationSharesList.isEmpty()) insert policyNotificationSharesList;
        }catch(Exception ex){
            throw new PolicyDistributionException(ex.getMessage());
        }
    }
}

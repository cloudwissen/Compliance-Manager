/**
 * @description Policy Helper class
 **/
public with sharing class PolicyHelper {

    public static Boolean isValid = true;
    
    private static String contentDocumentField = Schema.grc__Policy__c.fields.Content_Document_Id__c.getDescribe().getName();
    @TestVisible
    private static Set < Id > contentDocumentIds = new Set < Id > ();

    /**
     * @description Method to filter out the policies only with content document Id changes
     * @param         oldPoliciesMap - Old map instances of policies
     * @param         newPolicies - New list instances of policies
     * @return         Map < Id, grc__Policy__c > Map of policyId with policy,for which the content document Id changed
     */
    public static Set<Id> getChangedDocumentIdPolicies(Map < Id, sObject > oldPoliciesMap, List < sObject > newPolicies) {
        Set < Id > policyIds = new Set < Id > ();
        List < grc__Policy__c > changedPolicies = new List < grc__Policy__c > ();
        for (sObject newPolicy: newPolicies) {
            sObject oldPolicy = oldPoliciesMap.get(newPolicy.Id);
            if (oldPolicy.get(contentDocumentField) != newPolicy.get(contentDocumentField)) {
                policyIds.add(newPolicy.Id);
                if((Id)newPolicy.get(contentDocumentField) != null){
                    contentDocumentIds.add((Id)newPolicy.get(contentDocumentField));
                }
           }
        }
        return policyIds;
    }
    /**
     * @description Method to validate the policy document id set to blank or not
     * @param         oldPoliciesMap - Old map instances of policies
     * @param         newPolicies - New list instances of policies
     * @param         changedDocumentIdPolicies - Map of policyId with policy,for which the content document Id changed
     */
    public static void validatePolicyDocumentIds(Map <Id,sObject> oldPoliciesMap,List <sObject> newPolicies, Set<Id> changedContentDocumentPolicies) {
        Map<Id, grc__Policy__c> policiesMap = new Map<Id, grc__Policy__c>([SELECT Id, (SELECT Id FROM Policy_Versions__r LIMIT 1) FROM grc__Policy__c WHERE Id IN: changedContentDocumentPolicies]);
        for (sObject newPolicy: newPolicies) {
            if(changedContentDocumentPolicies.contains(newPolicy.Id) && policiesMap.containsKey(newPolicy.Id) && !policiesMap.get(newPolicy.Id).Policy_Versions__r.isEmpty()){
                //if the policy document id set to blank
                if (oldPoliciesMap.get(newPolicy.Id).get(contentDocumentField) != null && (String) newPolicy.get(contentDocumentField) == null) {
                    newPolicy.addError(System.Label.Content_Document_Id_Deletion_Error);
                }
            }
        }
    }
    /**
     * @description Method to get Content Document With Versions
     * @return         Map < Id, ContentDocument >  - Map instance of Content Documents
     */
    public static Map < Id, ContentDocument > getContentDocumentWithVersions() {
        if (contentDocumentIds.size() > 0) {
            Map < Id, ContentDocument > contentDocuments = new Map < Id, ContentDocument > (
                [SELECT Id, (SELECT VersionNumber FROM ContentVersions ORDER BY VersionNumber DESC LIMIT 1)
                    From ContentDocument WHERE Id IN: contentDocumentIds LIMIT 50000
                ]);

            return contentDocuments;
        }
        return null;
    }
    /**
     * @description Method to create policy version
     * @param         docVersions  - Map instance of Content Documents
     * @param        changedDocumentIdPolicies - Map of policyId with policy,for which the content document Id changed
     */
     public static void createPolicyVersion(List<sObject> policiesList, Set<Id> changedContentDocumentPolicies) {
        Map < Id, ContentDocument > contentDocumentsMap = getContentDocumentWithVersions();
        Map < Id, Integer > policyByVersionMap = new Map < Id, Integer > ();
        for (sObject policy : policiesList) {
            if (changedContentDocumentPolicies.contains(policy.Id) && policy.get(contentDocumentField) != null) {
                Integer versionNo;
                if (contentDocumentsMap.containsKey((Id)policy.get(contentDocumentField))) {
                    if (contentDocumentsMap.get((Id)policy.get(contentDocumentField)).ContentVersions.size() > 0) {
                         versionNo = integer.valueof(contentDocumentsMap.get((Id)policy.get(contentDocumentField)).ContentVersions[0].VersionNumber);
                    }
                }
                policyByVersionMap.put(policy.Id, versionNo);
            } 
        }
        ContentVersionHelper.createPolicyVersion(policyByVersionMap);
    }
    /**
     * @description Method to populate the map of linked entity ids by content document links
     * @param sObjectTypesList List of linked sobject types to look for
     * @return Map<Id, Id> map of link entity ids by content document links
     */
    public static Map < Id, contentDocumentLink > getContentDocumentLinks(Set < String > sObjectTypesList) {
        if (contentDocumentIds.size() > 0) {
            Map < Id, contentDocumentLink > linkedEntityIdByContentDocumentLinkMap = new Map < Id, contentDocumentLink > ();
            // get the content documents 
            List < ContentDocumentLink > contentDocumentLinksList = [SELECT ContentDocumentId, LinkedEntityId, LinkedEntity.Type FROM ContentDocumentLink
                WHERE ContentDocumentId IN: contentDocumentIds LIMIT 50000
            ];
            for (ContentDocumentLink contentDocumentLink: contentDocumentLinksList) {
                if (sObjectTypesList.contains(contentDocumentLink.LinkedEntity.Type)) {
                    linkedEntityIdByContentDocumentLinkMap.put(contentDocumentLink.LinkedEntityId, contentDocumentLink);
                }
            }
            return linkedEntityIdByContentDocumentLinkMap;
        }
        return null;
    }

    /**
     * @description Method to update content document share type
     * @param contentVersionMap Map of content version id by content version records
     * @param linkedEntityIdByContentDocumentLinkMap Map of linked entity ids by content document Links
     */
     public static void updateContentDocumentShareType(Map < Id, sObject > policyMap, Map < Id, contentDocumentLink > linkedEntityIdByContentDocumentLinkMap) {
        if (linkedEntityIdByContentDocumentLinkMap != null && linkedEntityIdByContentDocumentLinkMap.size() > 0) {
            // loop through link entity ids 
            for (Id policyId: policyMap.keySet()) {
                if(linkedEntityIdByContentDocumentLinkMap.containsKey(policyId)){
                   linkedEntityIdByContentDocumentLinkMap.get(policyId).ShareType = 'I'; 
                } 
            }
            try {
                update linkedEntityIdByContentDocumentLinkMap.values();
            } catch (Exception ex) {
                throw new PolicyContentDocumentException(ex.getMessage());
            }
        }
    }

    /**
    * @description Method to create policy notification share record for policy owner
    * @param policyId Id of the policy
    * @param userIds Set of user ids
    **/
    public static void updatePolicyOwnersOnPolicyNotificationShares(List<grc__Policy__c> policiesList, Map<Id, grc__Policy__c> oldPoliciesMap){
        Map<Id, Id> policyByNewOwnerMap = new Map<Id, Id>();
        for(grc__Policy__c policy : policiesList){
            if(oldPoliciesMap != null && oldPoliciesMap.containsKey(policy.Id) && policy.OwnerId != oldPoliciesMap.get(policy.Id).OwnerId){
                policyByNewOwnerMap.put(policy.Id, policy.OwnerId);
            }
        }
        // check if owner is changed
        if(!policyByNewOwnerMap.isEmpty()){
            List<Policy_Notification__Share> policyNotificationSharesToDelete = new List<Policy_Notification__Share>();
            Map<Id,List<Policy_Notification__c>> policyNotificationsByPolicyOwnerIdMap = new Map<Id,List<Policy_Notification__c>>();
            List<Policy_Notification__c> policyNotificationsList = [SELECT Id, Policy_Version__r.Policy__c, 
                                                                        (SELECT Id FROM Shares WHERE RowCause =: PolicyNotificationHelper.POLICY_OWNER_APEX_SHARING_REASON) 
                                                                            FROM Policy_Notification__c WHERE Policy_Version__r.Policy__c IN: policyByNewOwnerMap.keySet()
                                                                                AND Policy_Version__r.Policy__c != null LIMIT 50000];
           for(Policy_Notification__c policyNotification : policyNotificationsList){
                if(!policyNotification.Shares.isEmpty()){
                    policyNotificationSharesToDelete.addAll(policyNotification.Shares);
                }
               if(policyByNewOwnerMap.containsKey(policyNotification.Policy_Version__r.Policy__c)){
                    if(policyNotificationsByPolicyOwnerIdMap.containsKey(policyByNewOwnerMap.get(policyNotification.Policy_Version__r.Policy__c))){
                        policyNotificationsByPolicyOwnerIdMap.get(policyByNewOwnerMap.get(policyNotification.Policy_Version__r.Policy__c)).add(policyNotification);
                    }else{
                        policyNotificationsByPolicyOwnerIdMap.put(policyByNewOwnerMap.get(policyNotification.Policy_Version__r.Policy__c),new List<Policy_Notification__c>{policyNotification});
                    }
                }
            }

            try{
                if(!policyNotificationSharesToDelete.isEmpty()) delete policyNotificationSharesToDelete;
                if(!policyNotificationsByPolicyOwnerIdMap.isEmpty()) PolicyNotificationHelper.createPolicyNotificationSharesForPolicyOwners(policyNotificationsByPolicyOwnerIdMap);
            }catch(Exception ex){
                throw new PolicyDistributionException(ex.getMessage());
            }
        }
    } 
}

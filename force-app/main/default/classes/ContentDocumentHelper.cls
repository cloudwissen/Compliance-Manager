/**
* @description Provide helper methods for Content Document
**/
public with sharing class ContentDocumentHelper {

    /**
    * @description Method to validate the content documents before deletion
    * @param       contentDocuments List of content document records
    */
    public static void validateDocumentDeletion(Map<Id,sobject> contentDocumentsMap){
        Map<Id, Id> policyIdByContentDocumentIdMap = new Map<Id, Id>();
        Set<Id> contentDocumentIds = contentDocumentsMap.keySet();
        List<ContentDocumentLink> contentDocumentLinks = [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink 
                                                                   WHERE ContentDocumentId IN:contentDocumentIds LIMIT 50000];
        for(ContentDocumentLink cdl : contentDocumentLinks){
            policyIdByContentDocumentIdMap.put(cdl.LinkedEntityId,cdl.ContentDocumentId);
        }
        List<grc__Policy__c> policies = [SELECT Id,Content_Document_Id__c,(SELECT Id FROM Policy_Versions__r LIMIT 1) FROM grc__policy__c WHERE Id IN:policyIdByContentDocumentIdMap.keySet()];   
        for(grc__Policy__c policy : policies){
            if(policy.Content_Document_Id__c == policyIdByContentDocumentIdMap.get(policy.Id) && policy.Policy_Versions__r.size() > 0 ){
                if(contentDocumentsMap.containsKey(policy.Content_Document_Id__c)){
                    contentDocumentsMap.get(policy.Content_Document_Id__c).addError(System.Label.Policy_Document_Deletion_Error);
                }
            }
        }
    }
}

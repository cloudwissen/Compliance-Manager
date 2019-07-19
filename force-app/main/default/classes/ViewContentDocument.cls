/**
* @description Apex class used to fetch the content document ID from Policy
**/
public with sharing class ViewContentDocument {
    
    private static final String NEW_DOCUMENT = 'New';
    private static final String INVALID_DOCUMENT = 'Invalid';
    
    /**
	* @description Method to fetch the content document ID from Policy
    * @param       policyId -  Id of the policy 
	* @return      returnValue - String return value (ContentDocumentID,New,Invalid)
	**/
    @AuraEnabled
    public static String getContentDocumentId(Id policyId) {

        //Check user has sufficient access to Query Policy Data
		Boolean queryAccessPolicy = XLC.SchemaHelper.validateUserAccesibilityForDatabaseAction(
                                        grc__Policy__c.sObjectType.getDescribe().getName(), 
                                        new Set<String>{grc__Policy__c.XLComp__Content_Document_Id__c.getDescribe().getName()}, 
                                        XLC.SchemaHelper.DatabaseAction.QUERY_DATA
                                    );

		//Throw exception if the user doesn't have sufficient access
		if(!queryAccessPolicy){
			throw new AuraHandledException(Label.XLC.Insufficient_Privileges);
		}

        List < grc__Policy__c > policy = [SELECT Content_Document_Id__c, (SELECT ContentDocumentID FROM ContentDocumentLinks LIMIT 50000) FROM grc__Policy__c WHERE Id =: policyId];
        String returnValue;
        try {
            if (policy.size() > 0) {
                if (String.isEmpty(policy[0].Content_Document_Id__c)) {
                        returnValue = NEW_DOCUMENT ;
                }else{
                    if (policy[0].ContentDocumentLinks.size() > 0) {
                        List < ContentDocumentLink > contentDocuments = policy[0].ContentDocumentLinks;
                        for (integer i = 0; i < contentDocuments.size(); i++) {
                                if (policy[0].Content_Document_Id__c == contentDocuments[i].ContentDocumentID) {
                                    returnValue = contentDocuments[i].ContentDocumentID;
                                    break;
                                } else {
                                    returnValue = INVALID_DOCUMENT;
                                }
                            }
                    }
                }
            }
        } catch (Exception e) {
            returnValue = INVALID_DOCUMENT;
        }
        return returnValue;
    }
}
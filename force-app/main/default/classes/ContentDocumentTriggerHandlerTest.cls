/**
 * @description Test Class for ContentDocumentTriggerHandler Trigger
 **/
@isTest(SeeAllData = false)
private with sharing class ContentDocumentTriggerHandlerTest {
    /**
     * @description Method to create policy document
     * @return      grc__Policy__c
     **/
    static grc__Policy__c createPolicyDocument() {
        grc__Policy__c policy = new grc__Policy__c(Name = 'P1');
        insert policy;
        List<ContentDocumentLink> cdl = createContentDocument(policy.Id);
        policy.XLComp__Content_Document_Id__c = cdl[0].ContentDocumentId;
        update policy;
        createPolicyversion(policy); 
        return policy;
    }
    /**
     * @description Method to delete policy document
     * @return      grc__Policy__c
     **/
    static grc__Policy__c deletePolicyDocument() {
        grc__Policy__c policy = createPolicyDocument();
        ContentDocument cd = [SELECT Id from ContentDocument WHERE Id=:policy.XLComp__Content_Document_Id__c];
        delete cd;
        return policy;
    }
    /**
     * @description Method to create policy version
     **/
    static void createPolicyversion(grc__Policy__c policy) {
        Policy_Version__c pv = new Policy_Version__c(Policy__c=policy.Id,Version__c=1);
        insert pv;
    }    
    /**
     * @description Method to create Non policy document
     * @return      List<ContentDocumentLink>
     **/
    static List<ContentDocumentLink> createNonPolicyDocument() {
        grc__Policy__c policy = new grc__Policy__c(Name = 'P2');
        insert policy;
        List<ContentDocumentLink> cdl = createContentDocument(policy.Id);
        return cdl;
    }
    /**
     * @description Method to delete Non policy document
     * @return      ContentDocument
     **/
    static ContentDocument deleteNonPolicyDocument() {
        List<ContentDocumentLink> cdl= createNonPolicyDocument();
        ContentDocument cd = [SELECT Id,IsDeleted from ContentDocument WHERE Id=:cdl[0].ContentDocumentId];
        delete cd;
        return cd;
    }
    /**
     * @description Method to create policy content documents
     * @return      List of ContentDocumentLink
     **/
    static List<ContentDocumentLink> createContentDocument(Id policyId) {
        // create content documents 
        List<ContentVersion> contentVersionsList = new List<ContentVersion>{new ContentVersion(Title='Google.com',VersionData=Blob.valueOf('Test Content'),IsMajorVersion=true,PathOnClient='Penguins.jpg')};
        insert contentVersionsList;
         // get content document id
        contentVersionsList = [SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = :contentVersionsList[0].Id LIMIT 1];
        // create content document links 
        List<ContentDocumentLink> contentDocumentLinksList = new List<ContentDocumentLink>{new ContentDocumentLink(LinkedEntityId=policyId,ContentDocumentId=contentVersionsList[0].ContentDocumentId,ShareType='V',Visibility='AllUsers')};
        insert contentDocumentLinksList;
        return contentDocumentLinksList;
    }
    /**
     * @description Method to test delete Policy Document
     **/
    @isTest static void testDeletePolicyDocument() {
        try{
            grc__Policy__c policy = deletePolicyDocument();
        }catch(exception ex){
             System.assert(ex.getMessage().contains('Please delete all policy versions to delete policy document.'),ex.getMessage());
        }       
    }
    /**
     * @description Method to test delete Non Policy Document
     **/
    @isTest static void testDeleteNonPolicyDocument() {
        ContentDocument cd = deleteNonPolicyDocument();
        List<ContentDocumentLink> cdl = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId=:cd.Id];
        System.assertEquals(0,cdl.size(),'Non Policy Document has been deleted');
    }   
}
/**
 * @description Test Class for ViewContentDocument Trigger
 **/
@isTest(SeeAllData = false)
private with sharing class ViewContentDocumentTest {
    /**
     * @description Method to create Policy without Document Id
     * @return      grc__Policy__c
     **/
    static grc__Policy__c policyWithoutDocumentId() {
        grc__Policy__c policy = new grc__Policy__c(Name = 'P1');
        insert policy;
        return policy;
    }
    /**
     * @description Method to update Policy with valid Document Id
     * @return      grc__Policy__c
     **/
    static grc__Policy__c updatePolicyDocumentId() {
        grc__Policy__c policy = new grc__Policy__c(Name = 'P1');
        insert policy;
        List<ContentDocumentLink> cdl = createContentDocument(policy.Id);
        policy.Content_Document_Id__c = cdl[0].ContentDocumentId;
        update policy;
        return policy;
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
     * @description Method to test View Upload Document
     **/
    @isTest static void viewUploadDocument() {
        grc__Policy__c policy = policyWithoutDocumentId();
        String returnValue = ViewContentDocument.getContentDocumentId(policy.Id);
        System.assertEquals('New',returnValue,'No Document is present and component should show upload component');    
        
    }
    /**
     * @description Method to test View Content Document
     **/
    @isTest static void viewContentDocument() {
        grc__Policy__c policy = UpdatePolicyDocumentId();
        String returnValue = ViewContentDocument.getContentDocumentId(policy.Id);
        System.assertEquals(policy.XLComp__Content_Document_Id__c,returnValue,'Document is present and Id has been returned');        
        
    }   
}
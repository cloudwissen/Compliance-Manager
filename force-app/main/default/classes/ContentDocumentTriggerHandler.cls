/**
* @description Trigger handler for content document
**/
public with sharing class ContentDocumentTriggerHandler extends TriggerHandler{
    /**
    * @description Function to handle the after insert trigger event
    */
    public override void beforeDelete(){
        ContentDocumentHelper.validateDocumentDeletion(trigger.oldMap);
    }
}

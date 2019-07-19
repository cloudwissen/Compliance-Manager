({
    /**
	 * @description Method called on the initialisation of the component.
	 **/
	doInit : function(component, event, helper) {
		helper.doInit(component, event, helper);	
	},
	/**
	 * @description Method called on the successful upload of the document.
	 **/
	handleUploadFinished: function(component, event, helper) {
		var uploadedFiles = event.getParam("files");
		for(var i = 0 ; i < uploadedFiles.length;i++){
			component.set("v._simpleNewPolicy.XLComp__Content_Document_Id__c",uploadedFiles[i].documentId);
		}
		helper.handleSave(component, event, helper);
	}
})
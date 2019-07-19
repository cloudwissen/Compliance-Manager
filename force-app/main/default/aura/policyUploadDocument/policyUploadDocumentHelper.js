({
    /**
	 * @description Method called on the initialisation of the component.
	 * @param       component - The component passed into the helper method. 
	 * @param       event - event fired to invoke this method. 
	 * @param       helper - helper js file instance to call the getContentDocumentId method.
	 **/
	doInit: function (component, event, helper) {
		if (!$A.util.isEmpty(component.get("v.recordId"))) {
			component.find("policyRecordCreator").reloadRecord();
			helper.getContentDocumentId(component);
		}
	},
	/**
	 * @description Populates the document id to the policy record.
	 * @param       component - The component passed into the helper method.
	 **/
	getContentDocumentId: function (component) {
		var getContentDocumentIdPromise = this.getContentDocumentIdPromise(component);
		getContentDocumentIdPromise.then(
			$A.getCallback(function (result) {
                if (!$A.util.isEmpty(result)) {
					if (result == "Invalid") {
						component.set("v._isInvalidDocument",true);
					}
					if (result != "New" && result != "Invalid") {
						component.set("v._documentId", result);
					}
				}
				else {
					component.set("v._isInvalidDocument",true);
				}
				component.set("v._isCallBackCompleted", true);
			})
		);
	},
	/**
	 * @description Method called on successful upload of document
	 * @param       component - The component passed into the helper method. 
	 * @param       event - event fired to invoke this method. 
	 * @param       helper - helper js file instance to call the getContentDocumentId method.
	 **/
	handleSave: function (component, event, helper) {
		component.find("policyRecordCreator").saveRecord(function (saveResult) {
			if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
				// record is saved successfully
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"message": $A.get("$Label.c.Policy_Upload_Success_Message"),
					"type": "success"
				});
				resultsToast.fire();
				helper.getContentDocumentId(component, helper);
				$A.get('e.force:refreshView').fire();
			} else if (saveResult.state === "INCOMPLETE") {
				// handle the incomplete state
				console.error(saveResult.error);
			} else if (saveResult.state === "ERROR") {
				// handle the error state
				$A.get("e.force:showToast").setParams({"message": $A.get("$Label.c.Error_Unable_To_Update_ContentDocumentId"),"type":"error"}).fire();
			} else {
				console.error(saveResult.error);
			}
		});

	},
	/**
	 * @description Method to get the cells for the heatmap by creating a promise.
	 * @param       component - The component passed into the helper method.
	 * @return		promiseServerSideCall - Service side promise.
	 **/
	getContentDocumentIdPromise: function (component) {
		var action = component.get("c.getContentDocumentId");
		action.setParams({
			policyId: component.get("v.recordId"),
		});
		return this.promiseServerSideCall(component, action);
	},
	/**
	 * @description Helper method which takes in action and creates promise around it
	 * @param       component - The component passed into the helper method.
	 * @param       action - action for which callback is set and promise is created around.
	 **/
	promiseServerSideCall: function (component, action) {
		return new Promise(function (resolve, reject) {
			action.setCallback(this, function (response) {
				var state = response.getState();
				var state = response.getState();
				if (state === "SUCCESS") {
					resolve(response.getReturnValue());
				} else if (state === "ERROR") {
					var errors = response.getError();
					var errorMessages = [];
					if (errors) {
						for (var i = 0; i < errors.length; i++) {
							if (errors[i] && errors[i].message) {
								errorMessages.push(errors[i].message);
							}
						}
					} else {
						errorMessages.push($A.get("$Label.XLC.Unknown_Error"));
					}
					if (!$A.util.isEmpty(errorMessages)) {
						component.set("v.errorMessages", errorMessages);
					}
					console.error(errorMessages);
				}
			})
			$A.enqueueAction(action);
		});
	},
})
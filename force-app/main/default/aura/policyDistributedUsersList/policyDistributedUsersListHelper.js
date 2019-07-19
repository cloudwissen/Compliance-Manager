({
	/**
	* @description Helper method which takes in action and creates promise around it
	* @param	   action - action for which callback is set and promise is created around.
	**/
	promiseServerSideCall : function(action) {
		return new Promise(function(resolve, reject) {
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					resolve(response.getReturnValue());
				}
				else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
						if (errors[0] && errors[0].message) {
							reject(Error(errors[0].message));
						}
					}
					else {
						reject(Error($A.get("$Label.XLC.Unknown_Error")));
					}
				}
			});
			$A.enqueueAction(action);
		});
	},
	
	/**
	* @description Helper method get the list of policy distributed users
	* @param component - To get the attributes from the component's DOM.
	**/
	fetchPolicyDistributedUsers : function(component,event) {
		var action = component.get("c.getUsersList");
		action.setParams({
			policyId : component.get("v.recordId"),
			fieldSetName : component.get("v.fieldSetName")
		});
		return this.promiseServerSideCall(action);
	},
	
	/**
	* @description Helper method get policy sent users list
	* @param component - To get the attributes from the component's DOM.
	**/
	fetchUsersList : function(component,event) {
		var policyDistributedUsersPromise = this.fetchPolicyDistributedUsers(component);
		policyDistributedUsersPromise.then(
			$A.getCallback(function(result){
				if(!$A.util.isEmpty(result) && !$A.util.isEmpty(result.columns) && $A.util.isEmpty(component.get("v._columns"))) {
					var columnsList = result.columns;
					columnsList.push({'fieldName':'delete','type':'button','initialWidth':6,'typeAttributes':{'iconName':'utility:close','variant':'base','iconPosition':'right','title':$A.get("$Label.c.Delete")}});
					component.set("v._columns",columnsList);
				}
				if(!$A.util.isEmpty(result)) component.set("v._data",result.data);
				component.set("v._transientMessageFieldLabel",result.transientMessageFieldLabel);
			})
		).catch(
			$A.getCallback(function(error){
				var toastError = $A.get("e.force:showToast");
				toastError.setParams({
					"type": "error",
					"message": error
				});
				toastError.fire();
			})
		);
	},
	
	/**
	* @description Helper method to sort the table data
	* @param component - To get the attributes from the component's DOM.
	**/
	sortData : function (component, fieldName, sortDirection) {
		var data = component.get("v._data");
		var reverse = sortDirection !== 'asc';		
		//sorts the rows based on the column header that's clicked
		data.sort(this.sortBy(fieldName, reverse))
		component.set("v._data", data);
	},
	
	/**
	* @description Helper method to sort the table data by given field
	* @param component - To get the attributes from the component's DOM.
	**/
	sortBy : function (field, reverse, primer) {
		var key = primer ?
			function(x) {return primer(x[field])} :
			function(x) {return x[field]};
		//checks if the two rows should switch places
		reverse = !reverse ? 1 : -1;
		return function (a, b) {
			return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
		}
	},
	
	/**
	* @description Helper method to display modal to get the custom message from user
	* @param component - The component to which the controller belongs.
	**/
	showModal : function(component) {
		$A.createComponents([
			["aura:html",{"tag":"div","body":$A.get("$Label.c.Send_Message"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
			["lightning:textarea",{"value":component.getReference("v._message"),"label":component.get("v._transientMessageFieldLabel")}],
			["lightning:button",{"variant":"brand","label":$A.get("$Label.c.Confirm"),onclick:component.getReference("c.notifyUsers")}]
		],
		function(components, status, errorMessage){
			if (status === "SUCCESS") {
				component.find('overlayLib').showCustomModal({
				header:components[0],
				body:components[1],
				footer:components[2],
				showCloseButton: true
				}).then(function(overlay){
					// we need to set the modal instance in an attribute to call its methods
					component.set("v.overlayPanel",[overlay]);
				});
			}else if(status === "ERROR"){
				console.error(errorMessage);
			}
		});
	},
	
	/**
	* @description Helper method to used to notify users
	* @param component - The component to which the controller belongs.
	**/
	sendNotifications : function(component,event) {
		var action = component.get("c.sendNotifications");
		action.setParams({
			recordIds : JSON.stringify(component.get("v._selectedRows")),
			message : component.get("v._message")
		});
		
		var notifyUsersPromise = this.promiseServerSideCall(action);
		notifyUsersPromise.then(
				$A.getCallback(function(result){
					component.set("v._message",'');
					var overlayPanel = component.get("v.overlayPanel");
					if(!$A.util.isEmpty(overlayPanel)) {
						overlayPanel[0].close(); 
					}
					component.set("v._selectedRows",[]);
					
					// show toast
					$A.get("e.force:showToast").setParams({
						"type" : result.type,
						"message": result.message
					}).fire();
				})
			).catch(
				$A.getCallback(function(error){
                    if(!$A.util.isEmpty(error)){
                        var errorMessage = $A.get("e.force:showToast");
                        errorMessage.setParams({
                            "type" : "error",
                            "message": error.message
                        });
                        errorMessage.fire();
                    }
				}
			)
		);
	},

	/**
	* @description Helper method to get the selected rows from the lightning datatable
	* @param component - The component to which the controller belongs.
	* @param event - The event initiated the action.
	**/
	getSelectedRows : function(component,event) {
		var recordIds = [];
		event.getParam('selectedRows').forEach(function(item){
			recordIds.push(item.Id);
		});
		component.set("v._selectedRows",recordIds);
	},

	/**
	* @description Method remove the notified user
	* @param component - The component to which the controller belongs.
	* @param event - The event initiated the action.
	**/
	deletePolicyNotification : function(component,event,helper){
		var row = event.getParam('row');
		if(!$A.util.isEmpty(row)){
			var action = component.get("c.removeNotifiedUser");
			action.setParams({
				policyNotificationId : row.Id
			});
			
			this.promiseServerSideCall(action).then(
				$A.getCallback(function(result){
					helper.fetchUsersList(component,event);
					// fire remove Notified User event
					$A.get("e.XLComp:removeNotifiedUserEvent").setParams({
						"scope" : { "recordId" : component.get("v.recordId")},
						"userId" : result.userId
					}).fire();
					
					$A.get("e.force:showToast").setParams({
						"type": "success",
						"message": result.message
					}).fire();
				})
			).catch(
				$A.getCallback(function(error){
					console.error(error);
				})
			); 
		}
	},
})

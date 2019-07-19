({
	/**
	* @description Method called on the initialisation of the component.
	**/
	fetchUsers : function(component, event, helper) {
		helper.fetchUsersList(component, event);
	},

	/**
	* @description Client-side controller called by the onsort event handler
	**/
	updateColumnSorting: function (component, event, helper) {
		var fieldName = event.getParam('fieldName');
		var sortDirection = event.getParam('sortDirection');
		// assign the latest attribute with the sorted column fieldName and sorted direction
		component.set("v._sortedBy", fieldName);
		component.set("v._sortedDirection", sortDirection);
		helper.sortData(component, fieldName, sortDirection);
	},

	/**
	* @description Method to get the selected rows from the datatable
	**/
	handleOnRowSelection : function(component,event,helper){
		helper.getSelectedRows(component,event);
	},

	/**
	* @description Method to get the selected rows from the datatable
	**/
	handleRowAction : function(component,event,helper){
		helper.deletePolicyNotification(component,event,helper);
	},
	
	/**
	* @description Method draw the modal in the component to get the message from the user
	**/
	handleShowModal : function(component,event,helper){
		helper.showModal(component,event);
	},
	
	/**
	* @description Method to notify the selected users
	**/
	notifyUsers : function(component,event,helper){
		helper.sendNotifications(component,event);
	},
})

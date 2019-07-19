({
	/**
	* @description Helper method which takes in action and creates promise around it
	* @param   action - action for which callback is set and promise is created around.
	**/
	promiseServerSideCall : function(action) {
		return new Promise(function(resolve, reject) {
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					resolve(response.getReturnValue());
				} else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
						if (errors[0] && errors[0].message) {
							reject(Error(errors[0].message));
						}
					} else {
						reject(Error($A.get("$Label.XLC.Unknown_Error")));
					}
				}
			});
			$A.enqueueAction(action);
		});
	},

	/**
	* @description Helper method to get list of invited users from the controller
	* @param	  component - The component to which the controller belongs. 
	**/
	fetchsObjectRecords : function(component){
		$A.util.toggleClass(component.find("spinner"),"slds-hide");
		var action = component.get("c.getUsers");
		action.setParams({
			trainingModuleId : component.get("v.recordId")
		});
		var recordsPromise = this.promiseServerSideCall(action);
		recordsPromise.then(
			$A.getCallback(function(result){
					$A.util.toggleClass(component.find("spinner"),"slds-hide");
					component.set("v._records",result.data);
					component.set("v._displayList",result.data);
					component.set("v._columns",result.columns);
					component.set("v._userLabelPlural",result.labelPlural);
					// simulate a trip to the server
					// cannot set both display list and selected ids in the same instance
					// NEEDS REVISITING - DO THIS IN AFTER RENDER
					setTimeout($A.getCallback(function () {
						component.set("v._selectedIds",result.selectedIds);
						component.set("v._tempSelectedIds", result.selectedIds);
					}));
				})
			).catch(
				$A.getCallback(function(error){
					$A.util.toggleClass(component.find("spinner"),"slds-hide");
			})
		);
	},

	/**
	* @description Helper method used to update selected ids  
	* @param	  component - The component to which the controller belongs. 
	* @param	  event — The event that the action is handling.
	**/
	updateSelectedIds : function(component,event){
		var selectedIds = component.get("v._selectedIds");
		var currentSelectedIds = this.getIdsList(event.getParam("selectedRows"));
		var displayListIds = this.getIdsList(component.get("v._displayList"));
		displayListIds.forEach(function(recordId){
			if(selectedIds.indexOf(recordId) === -1 && currentSelectedIds.indexOf(recordId) > -1){
				selectedIds.push(recordId);
			}else if(selectedIds.indexOf(recordId) > -1 && currentSelectedIds.indexOf(recordId) === -1){
				var itemIndex = selectedIds.indexOf(recordId);
				selectedIds.splice(itemIndex,1);
				selectedIds = selectedIds;
			}
		});
		component.set("v._selectedIds",selectedIds);
		component.set("v._tempSelectedIds", selectedIds);
		component.set("v._rowSelection", true);
	},

	/**
	* @description Helper method to get the list of ids from the records
	* @param itemsList - List of records
	**/
	getIdsList : function(itemsList){
		var idsList = [];
		itemsList.forEach(function(item){
			idsList.push(item.Id);
		});
		return idsList;
	},

	/**
	* @description Helper method to search the records list based on the given search string
	* @param component - The component to which the controller belongs.
	* @param event — The event that the action is handling.
	**/
	search : function(component,event){
		component.set("v._selectedIds", []);
		var filterItems = event.getSource().get("v.filterItems");
		if(!$A.util.isEmpty(filterItems)){
			var searchInput = filterItems[0].value;
			if(!$A.util.isEmpty(searchInput)){
				var records = component.get("v._records");
				var filteredRecords = records.filter(function(item){
					return item[event.getSource().get("v.searchFields")[0].name].toLowerCase().includes(searchInput.toLowerCase()) > 0;
				});
				component.set("v._displayList",filteredRecords);
			}
		}else if($A.util.isEmpty(filterItems) || $A.util.isEmpty(filterItems[0].value)){
			component.set("v._displayList",component.get("v._records"));
		}
		// simulate a trip to the server
		// cannot set both display list and selected ids in the same instance
		setTimeout($A.getCallback(function () {
			component.set("v._selectedIds", component.get("v._tempSelectedIds"));
		}));
	},

	/**
	* @description Helper method to create event for the selected user for each training module
	* @param component - The component to which the controller belongs.
	**/
	markAttendance : function(component){
		$A.util.toggleClass(component.find("spinner"),"slds-hide");
		var action = component.get("c.markAttendance");
		action.setParams({
			trainingModuleId : component.get("v.recordId"),
			selectedUsers : JSON.stringify(component.get("v._selectedIds"))
		});
		var saveUsersPromise = this.promiseServerSideCall(action);
		saveUsersPromise.then(
			$A.getCallback(function(result){
					$A.util.toggleClass(component.find("spinner"),"slds-hide");
					$A.get("e.force:showToast")
						.setParams({
							"message": $A.get('$Label.c.Attendance_Recorded_Successfully'),
							"type" : "success"
						})
					.fire();
					component.set("v._rowSelection", false);
				})
			).catch(
				$A.getCallback(function(error){
					$A.util.toggleClass(component.find("spinner"),"slds-hide");
                    if(!$A.util.isEmpty(error)){
                        var errorMessage = $A.get("e.force:showToast");
                        errorMessage.setParams({
                            "type" : "error",
                            "message": error.message
                        });
                        errorMessage.fire();
                    }
			})
		);
	},

	/**
	* @description Helper method to sort the table data
	* @param component - To get the attributes from the component's DOM.
	* @param event — The event that the action is handling.
	**/
	sortData : function (component,event) {
		var fieldName = event.getParam('fieldName');
		var sortDirection = event.getParam('sortDirection');
		// assign the latest attribute with the sorted column fieldName and sorted direction
		component.set("v.sortedBy", fieldName);
		component.set("v.sortedDirection", sortDirection);
		var data = component.get("v._displayList");
		var reverse = sortDirection !== 'asc';
		//sorts the rows based on the column header that's clicked
		data.sort(this.sortBy(fieldName, reverse))
		component.set("v._displayList", data);
	},

	/**
	* @description Helper method to sort the table data by given field
	* @param field - API Name of the field clicked on the table
	* @param reverse sort direction
	**/
	sortBy : function (field,reverse,primer) {
		var key = primer ?
			function(x) {return primer(x[field])} :
			function(x) {return x[field]};
		//checks if the two rows should switch places
		reverse = !reverse ? 1 : -1;
		return function (a, b) {
			return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
		}
	}
})

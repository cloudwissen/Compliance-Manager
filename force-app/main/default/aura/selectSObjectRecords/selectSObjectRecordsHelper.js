({
	/**
	* @description Helper method which takes in action and creates promise around it
	* @param    action - action for which callback is set and promise is created around.
	**/
    promiseServerSideCall: function(action) {
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
                        reject(Error("Unknown_Error"));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },
    
    /**
	* @description Helper method to get the sobjects list from controller
    * @param component - The component to which the controller belongs. 
    * @param event — The event that triggered this action.
    * @param helper — The helper used to provide supporting helper methods.
	**/
    getsObjectInformation: function(component,event,helper) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        var action = component.get("c.getsObjectInfo");
        var sObjectsPromise = this.promiseServerSideCall(action);
        sObjectsPromise.then(
                $A.getCallback(function(result){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
                    component.set("v.sObjectsList",result);
                    helper.setRecordsMap(component);
                    helper.setCurrentsObjectInfo(component);
                })
            ).catch(
                $A.getCallback(function(error){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
            })
        );
    },

    /**
    * @description Helper method to init the records map
    * @param component - The component to which the controller belongs. 
    **/
    setRecordsMap : function(component){
        var sObjectsList = component.get("v.sObjectsList");
        var recordsMap = {};
        sObjectsList.forEach(function(item){
            recordsMap[item.name] = [];
        });
        component.set("v.recordsMap",recordsMap);
        this.updateRecordsList(component);
    },

    /**
    * @description Helper method to update the exclude ids list
    * @param component - The component to which the controller belongs. 
    **/
    setExcludeIds : function(component) {
        var recordIds = component.get("v.excludeIds");
        var sObjectName = component.get("v.sObjectName");
        var recordsList = component.get("v.recordsList");
        recordsList.forEach(function(item){
            recordIds.push(item.Id);
        });
        component.set("v.excludeIds",recordIds);
    },

    /**
    * @description Helper method to add selected records into the records map
    * @param component - The component to which the controller belongs. 
    **/
    addSelectedRecords : function(component){
    	var recordsMap = component.get("v.recordsMap");
        var recordsList = recordsMap[component.get("v.sObjectName")];
        recordsList = recordsList.concat(component.get("v._selectedRecords"));
        recordsMap[component.get("v.sObjectName")] = recordsList;
        component.set("v.recordsMap",recordsMap);
        component.set("v._selectedRecords",[]);
        this.updateRecordsList(component);
    },

    /**
    * @description Helper method to add all the records from the record map to records list
    *			   NOTE : AURA:ITERATION DOESN'T SUPPORT ITERATE OVER A MAP.
    * @param component - The component to which the controller belongs. 
    **/ 
    updateRecordsList : function(component){
    	var recordsMap = component.get("v.recordsMap");
    	var sObjectsList = component.get("v.sObjectsList");
        var recordsList = [];
        sObjectsList.forEach(function(item){
            if(recordsMap.hasOwnProperty(item.name)){
            	recordsList = recordsList.concat(recordsMap[item.name]);
            }
        });
        component.set("v.recordsList",recordsList);
    },

    /**
    * @description Helper method to remove item from the map
    * @param component - The component to which the controller belongs. 
    * @param event — The event that triggered this action.
    **/ 
    removeItem : function(component,event){
        if(event.getParam("data").name === 'delete'){
            var recordsMap = component.get("v.recordsMap");
            var sObjectsList = component.get("v.sObjectsList");
            var sObjectLabel = event.getSource().get("v.sObjectLabel");
            sObjectsList.forEach(function(item,index){
                if(item.label === sObjectLabel){
                    var indexToRemove = 0;
                    var recordsList = recordsMap[item.name];
                    recordsList.forEach(function(item,index){
                        if(item.Id == event.getSource().get("v.record.Id")){
                            indexToRemove = index;
                        }
                    });
                    recordsList.splice(indexToRemove,1);
                    recordsMap[item.name] = recordsList;
                }
            });
            component.set("v.recordsMap",recordsMap);
            this.updateRecordsList(component);
        }
    },

    /**
    * @description Helper method to remove the id from the exclude ids list
    * @param component - The component to which the controller belongs. 
    * @param event — The event that triggered this action.
    **/ 
    removeIdFromExcludeIds : function(component,event){
        if(event.getParam("data").name === 'delete'){
            var excludedIds = component.get("v.excludeIds");
            excludedIds.splice(excludedIds.indexOf(event.getSource().get("v.record.Id")),1);
            component.set("v.excludeIds",excludedIds);
        }
    },

    /**
    * @description Helper method to set the current sobject info
    * @param component - The component to which the controller belongs.
    * @param event — The event that triggered this action.
    **/ 
    setCurrentsObjectInfo : function(component,event){
        var sObjectsList = component.get("v.sObjectsList");
        sObjectsList.forEach(function(item,index){
            if(item.name === component.get("v.sObjectName")){
                component.set("v._sObjectInfo",item);
            }
        });
    },
})
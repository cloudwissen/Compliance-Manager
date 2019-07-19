({
    /**
    * @description Helper method which takes in action and creates promise around it
    * @param   action - action for which callback is set and promise is created around.
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
                        reject(Error($A.get("$Label.c.Unknown_Error")));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },

    /**
    * @description Helper method to validate training course has training module(s).
    * @param component - The component to which the controller belongs.
    **/
    fetchTrainingInfo : function(component){
        //Show Spinner
        $A.util.removeClass(component.find("spinner"),"slds-hide");
        
        var action = component.get("c.getTrainingInfo");
        action.setParams({
            trainingCourseId : component.get("v.recordId")
        });
        
        var trainingInfoPromise = this.promiseServerSideCall(action);
        trainingInfoPromise.then(
        	$A.getCallback(function(result){
                var response = JSON.parse(result);
                if(!response.isvalid){
                    component.set("v.errorMessages", [$A.get("$Label.c.Training_Module_Not_Available")]);
                }
                component.set("v.excludeIds",response.userIds);
            })
        ).catch(
            $A.getCallback(function(error){
                $A.get("e.force:showToast").setParams({
                        "type" : "error",
                        "message": error.message
                }).fire();
            })
        ).finally(
            //Hide Spinner
            function(){
            	$A.util.addClass(component.find("spinner"),"slds-hide");
            }
        );
    },

    /**
    * @description Helper method to create event for the selected user for each training module
    * @param component - The component to which the controller belongs.
    * @param event — The event that the action is handling.
    * @param helper — The component’s helper
    **/
    saveParticipants: function(component,event,helper){
        //Show Spinner
        $A.util.removeClass(component.find("spinner"),"slds-hide");
        
        var action = component.get("c.saveUsers");
        action.setParams({
            trainingCourseId : component.get("v.recordId"),
            records : JSON.stringify(component.get("v.recordsList"))
        });
        
        var saveParticipantsPromise = this.promiseServerSideCall(action);
        saveParticipantsPromise.then(
            $A.getCallback(function(result){
                // remove the selection after save
                helper.setRecordsMap(component);
                // fire add participant event
                $A.get("e.XLComp:addParticipantEvent").fire();
                
                if(result.type === 'success'){
                    component.set("v.errorMessages", []);
                }
                // show toast
                $A.get("e.force:showToast")
                .setParams({
                    "type" : result.type,
                    "message": result.message
                }).fire();
            })
        ).catch(
            $A.getCallback(function(error){
                $A.get("e.force:showToast")
                .setParams({
                    "type" : "error",
                    "message": error.message
                }).fire();
            })
        ).finally(
            //Hide Spinner
            function(){
            	$A.util.addClass(component.find("spinner"),"slds-hide");
            }
        );
    },

    /**
    * @description Helper method to remove the notified user from the exclude ids
    * @param component - The component to which the controller belongs. 
    * @param event - The event initiated the action.
    **/
    removeParticipantFromExlcudeIds: function(component,event) {
        var scope = event.getParam("scope");
        var userId = event.getParam("userId");
        if(!$A.util.isEmpty(scope) && !$A.util.isUndefinedOrNull(userId)){
            if(scope.hasOwnProperty("recordId") && scope.recordId === component.get("v.recordId")){
                var excludeIds = component.get("v.excludeIds");
                excludeIds.splice(excludeIds.indexOf(userId),1);
                component.set("v.excludeIds",excludeIds);
            }
        }
    },
})
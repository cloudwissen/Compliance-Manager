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
                        reject(Error($A.get("$Label.XLC.Unknown_Error")));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },

    /**
    * @description Method to be called when the recordAction event from the recordTileList Component is fired
    * @param       component - The component to which the controller belongs.
    * @param       event - event fired from the XLC:recordTileList Action
    **/
    recordAction: function(component, event){
        if(event.getParam("data").name === 'delete'){
            $A.util.toggleClass(component.find("spinner"),"slds-hide");
            
            var action = component.get("c.deleteEvents");
            action.setParams({
                trainingCourseId : component.get("v.recordId"),
                userId : event.getSource().get("v.record.Id")
            });
            
            var deleteRecordPromise = this.promiseServerSideCall(action);
            deleteRecordPromise.then(
                $A.getCallback(function(result){
                    var recordsList = component.get("v._records");
                    var indexToRemove = 0;
                    
                    recordsList.forEach(function(item,index){
                        if(item.Id === event.getSource().get("v.record.Id")){
                            indexToRemove = index;
                        }
                    });
                    
                    recordsList.splice(indexToRemove,1);
                    component.set("v._records", recordsList);
                    
                    $A.get("e.XLComp:removeParticipantEvent").setParams({
                        "scope" : { "recordId" : component.get("v.recordId")},
                        "userId" : event.getSource().get("v.record.Id")
                    }).fire();
                    
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
                })
            ).catch(
                $A.getCallback(function(error){
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
                })
            );
       }
    },

    /**
    * @description Helper method to get list of invited users from the controller
    * @param      component - The component to which the controller belongs.
    **/
    fetchsObjectRecords: function(component){
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        
        var action = component.get("c.getInvitedUsers");
        action.setParams({
            trainingCourseId : component.get("v.recordId")
        });
        
        var recordsPromise = this.promiseServerSideCall(action);
        recordsPromise.then(
            $A.getCallback(function(result){
                $A.util.toggleClass(component.find("spinner"),"slds-hide");
                component.set("v._records",result);
            })
        ).catch(
            $A.getCallback(function(error){
                $A.util.toggleClass(component.find("spinner"),"slds-hide");
            })
        );
    }
})

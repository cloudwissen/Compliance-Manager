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
                        reject(Error($A.get("$Label.XLC.Unknown_Error")));
                    }
                }
            });
            $A.enqueueAction(action);
        });
    },
    
    /**
    * @description Helper method to get the sobjects list from controller
    * @param component - The component to which the controller belongs. 
    **/
    fetchPolicyInfo: function(component) {
        $A.util.toggleClass(component.find("spinner"),"slds-hide");
        var action = component.get("c.getPolicyInfo");
        action.setParams({
            policyId : component.get("v.recordId")
        });
        var policyInfoPromise = this.promiseServerSideCall(action);
        policyInfoPromise.then(
                $A.getCallback(function(result){
                    var resp = JSON.parse(result);
                    var policy = JSON.parse(resp.policy);
                    if(! $A.util.isEmpty(policy)) {
                        component.set("v._policy", policy);
                    }
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
                    component.set("v._transientMessageFieldLabel",resp.transientMessageFieldLabel);
                    component.set("v.excludeIds",resp.userIds);
                })
            ).catch(
                $A.getCallback(function(error){
                    console.error(error);
                    $A.util.toggleClass(component.find("spinner"),"slds-hide");
            })
        );
    },

    /**
    * @description Helper method to get distribution promise
    * @param component - The component to which the controller belongs. 
    * @param event - The event initiated the action.
    * @param helper - The helper instance to access methods.
    **/
    distributePolicy : function(component,event,helper) {
        var action = component.get("c.distributePolicy");
        action.setParams({
            policyId : component.get("v.recordId"),
            records : JSON.stringify(component.get("v.recordsList")),
            message : component.get("v._message")
        });
        var distributePolicyPromise = this.promiseServerSideCall(action);
        distributePolicyPromise.then(
                $A.getCallback(function(result){
                    var overlayPanel = component.get("v.overlayPanel");
                    if(!$A.util.isEmpty(overlayPanel)) {
                       overlayPanel[0].close(); 
                    } 
                    // remove the selection after save
                    helper.setRecordsMap(component);
                    component.set("v._message",'');
                    // show toast
                    $A.get("e.force:showToast")
                        .setParams({
                            "type" : result.type,
                            "message": result.message
                    }).fire();
                    // fire policy distribution event
                    $A.get("e.XLComp:policyDistributionEvent").fire();
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
            })
        );
    },

    /**
    * @description Helper method to display modal to get the custom message from user
    * @param component - The component to which the controller belongs.
    **/
    showModal: function(component) {
        $A.createComponents([
            ["aura:html",{"tag":"div","body":$A.get("$Label.c.Send_Message"),"HTMLAttributes":{"class":"slds-text-align_center slds-text-title_caps","style":"font-size:1rem;color:#3E3E3C;"}}],
            ["lightning:textarea",{"value":component.getReference("v._message"),"label":component.get("v._transientMessageFieldLabel")}],
            ["lightning:button",{"variant":"brand","label":$A.get("$Label.c.Confirm"),onclick:component.getReference("c.sendPolicy")}]
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
    * @description Helper method to remove the notified user from the exclude ids
    * @param component - The component to which the controller belongs. 
    * @param event - The event initiated the action.
    **/
    removeNotifiedUserFromExlcudeIds: function(component,event) {
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

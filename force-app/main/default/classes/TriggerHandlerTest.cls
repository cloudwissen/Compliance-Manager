@isTest(seealldata=false)
private class TriggerHandlerTest {
	
	/**
	* @description test the getName method returns the trigger handlers class name as a string.
	**/
	@isTest static void testGetName(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		System.assertEquals('MockTriggerHandler',testTriggerHandler.getName(),'The name should match the class name.');
	}
	
	/**
	* @description test the bypass method with the MockTriggerHandler to ensure that the handler
	*			   methods are bypassed as expected.
	**/
	@isTest static void testBypass_AllContexts(){
		TriggerHandler.bypass('MockTriggerHandler');
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_DELETE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_DELETE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_UNDELETE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
	}
	
	/**
	* @description test the bypass method with an empty handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testBypass_EmptyHandlerName(){
		try{
			TriggerHandler.bypass('');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the bypass method with a null handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testBypass_NullHandlerName(){
		try{
			String handlerName;
			TriggerHandler.bypass(handlerName);
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the bypass method with an invalid handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected. Since only a class which
	*			   extends TriggerHandler can be bypassed.
	**/
	@isTest static void testBypass_InvalidHandlerName(){
		try{
			TriggerHandler.bypass('TriggerHandlerException');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the bypass method with the MockTriggerHandler and a single context to ensure
	*			   that the handler methods are bypassed for the given context as expected.
	**/
	@isTest static void testBypass_SingleContext(){
		TriggerHandler.bypass('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT);
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The full testTriggerHandler should not be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The before insert of the testTriggerHandler should be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_UPDATE),'The before update of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_DELETE),'The before delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_INSERT),'The after insert of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UPDATE),'The after update of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_DELETE),'The after delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UNDELETE),'The after undelete of the testTriggerHandler should not be bypassed.');
	}
	
	/**
	* @description test the bypass method with the MockTriggerHandler two contexts to ensure
	*			   that the handler methods are bypassed for the given contexts as expected.
	**/
	@isTest static void testBypass_TwoContexts(){
		Set<TriggerHandler.TriggerContext> contextsForBypass = new Set<TriggerHandler.TriggerContext>{
																			TriggerHandler.TriggerContext.BEFORE_INSERT,
																			TriggerHandler.TriggerContext.BEFORE_UPDATE
																		};
																		
		TriggerHandler.bypass('MockTriggerHandler',contextsForBypass);
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_INSERT);
		testTriggerHandler.run();
		
		System.assertNotEquals(null,testTriggerHandler.triggerContextCalled,'Trigger context method should be called.');
		System.assertEquals('afterInsert',testTriggerHandler.triggerContextCalled,'After Insert Trigger context method should be called.');
		
		
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The full testTriggerHandler should not be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The before insert of the testTriggerHandler should be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_UPDATE),'The before update of the testTriggerHandler should be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_DELETE),'The before delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_INSERT),'The after insert of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UPDATE),'The after update of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_DELETE),'The after delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UNDELETE),'The after undelete of the testTriggerHandler should not be bypassed.');
	}
	
	/**
	* @description test the bypass method with the MockTriggerHandler with additional context for
	*			   bypass to ensure that the handler methods are bypassed for the given contexts as
	*			   expected.
	**/
	@isTest static void testBypass_AdditonalContext(){
		Set<TriggerHandler.TriggerContext> contextsForBypass = new Set<TriggerHandler.TriggerContext>{
																			TriggerHandler.TriggerContext.BEFORE_INSERT,
																			TriggerHandler.TriggerContext.BEFORE_UPDATE
																		};
																		
		TriggerHandler.bypass('MockTriggerHandler',contextsForBypass);
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_INSERT);
		testTriggerHandler.run();
		
		System.assertNotEquals(null,testTriggerHandler.triggerContextCalled,'Trigger context method should be called.');
		System.assertEquals('afterInsert',testTriggerHandler.triggerContextCalled,'After Insert Trigger context method should be called.');
		
		
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The full testTriggerHandler should not be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The before insert of the testTriggerHandler should be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_UPDATE),'The before update of the testTriggerHandler should be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_DELETE),'The before delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_INSERT),'The after insert of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UPDATE),'The after update of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_DELETE),'The after delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UNDELETE),'The after undelete of the testTriggerHandler should not be bypassed.');
		
		//Add new bypass to existing
		TriggerHandler.bypass('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_INSERT);
		
		testTriggerHandler.triggerContextCalled = null; //reset trigger context called to null
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
		
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_UPDATE);
		testTriggerHandler.run();
		
		System.assertNotEquals(null,testTriggerHandler.triggerContextCalled,'Trigger context method should be called.');
		System.assertEquals('afterUpdate',testTriggerHandler.triggerContextCalled,'After Update Trigger context method should be called.');
		
		
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The full testTriggerHandler should not be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The before insert of the testTriggerHandler should be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_UPDATE),'The before update of the testTriggerHandler should be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_DELETE),'The before delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_INSERT),'The after insert of the testTriggerHandler should be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UPDATE),'The after update of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_DELETE),'The after delete of the testTriggerHandler should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.AFTER_UNDELETE),'The after undelete of the testTriggerHandler should not be bypassed.');
		
	}
	
	/**
	* @description test the isBypassed method to ensure we can identify if a trigger handler has
	*			   been bypassed.
	**/
	@isTest static void testIsBypassed(){
		TriggerHandler.bypass('MockTriggerHandler');
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
	}
	
	/**
	* @description test the isBypassed method with an empty handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testIsBypassed_EmptyHandlerName(){
		try{
			TriggerHandler.isBypassed('');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the isBypassed method with a null handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testIsBypassed_NullHandlerName(){
		try{
			String handlerName;
			TriggerHandler.isBypassed(handlerName);
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the isBypassed method with an invalid handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected. Since only a class which
	*			   extends TriggerHandler can be bypassed.
	**/
	@isTest static void testIsBypassed_InvalidHandlerName(){
		try{
			TriggerHandler.isBypassed('TriggerHandlerException');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the clearBypass method with the MockTriggerHandler to ensure that the handler
	*			   methods are cleared from the bypassed list as expected.
	**/
	@isTest static void testClearBypass_AllContexts(){
		TriggerHandler.bypass('MockTriggerHandler');
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should be bypassed.');
		
		TriggerHandler.clearBypass('MockTriggerHandler');
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals('beforeInsert',testTriggerHandler.triggerContextCalled,'The beforeInsert trigger context method should be called.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should not be bypassed.');
	}
	
	/**
	* @description test the clearBypass method with the MockTriggerHandler and a given context to
	*			   ensure that the handler methods for the given context are cleared from the
	*			   bypassed list as expected.
	**/
	@isTest static void testClearBypass_SingleContext(){
		TriggerHandler.bypass('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT);
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The testTriggerHandler beforeInsert context should be bypassed.');
		
		TriggerHandler.clearBypass('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals('beforeInsert',testTriggerHandler.triggerContextCalled,'The beforeInsert trigger context method should be called.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The testTriggerHandler beforeInsert context should not be bypassed.');
	}
	
	/**
	* @description test the clearBypass method with the MockTriggerHandler and given contexts to
	*			   ensure that the handler methods for the given contexts are cleared from the
	*			   bypassed list as expected.
	**/
	@isTest static void testClearBypass_TwoContexts(){
		Set<TriggerHandler.TriggerContext> contextsForBypass = new Set<TriggerHandler.TriggerContext>{
																			TriggerHandler.TriggerContext.BEFORE_INSERT,
																			TriggerHandler.TriggerContext.BEFORE_UPDATE
																		};
		TriggerHandler.bypass('MockTriggerHandler',contextsForBypass);
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',contextsForBypass),'The testTriggerHandler beforeInsert & beforeUpdate contexts should be bypassed.');
		
		TriggerHandler.clearBypass('MockTriggerHandler',contextsForBypass);
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals('beforeInsert',testTriggerHandler.triggerContextCalled,'The beforeInsert trigger context method should be called.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',contextsForBypass),'The testTriggerHandler beforeInsert & beforeUpdate contexts should not be bypassed.');
	}
	
	/**
	* @description test the clearBypass method with the MockTriggerHandler and a given context to
	*			   ensure that when all context are cleared the trigger bypass is cleared.
	**/
	@isTest static void testClearBypass_RemoveAllContexts(){
		TriggerHandler.bypass('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT);
		
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The testTriggerHandler beforeInsert context should be bypassed.');
		
		TriggerHandler.clearBypass('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT);
		
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler',TriggerHandler.TriggerContext.BEFORE_INSERT),'The testTriggerHandler beforeInsert context should not be bypassed.');
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The testTriggerHandler should not be bypassed.');
	}
	
	/**
	* @description test the clearBypass method with an empty handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testClearBypass_EmptyHandlerName(){
		try{
			TriggerHandler.clearBypass('');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the clearBypass method with a null handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testClearBypass_NullHandlerName(){
		try{
			String handlerName;
			TriggerHandler.clearBypass(handlerName);
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the clearBypass method with an invalid handler name to ensure that a
	*			   TriggerHandlerException is thrown as expected. Since only a class which
	*			   extends TriggerHandler can be bypassed.
	**/
	@isTest static void testClearBypass_InvalidHandlerName(){
		try{
			TriggerHandler.clearBypass('TriggerHandlerException');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the clearAllBypasses method with the MockTriggerHandler and TriggerHandler
	*			   to ensure that all the handlers are cleared from the bypassed list as expected.
	**/
	@isTest static void testClearAllBypasses(){
		TriggerHandler.bypass('MockTriggerHandler');
		TriggerHandler.bypass('TriggerHandler');
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'),'The MockTriggerHandler should be bypassed.');
		
		System.assertEquals(true,TriggerHandler.isBypassed('TriggerHandler'),'The TriggerHandler should be bypassed.');
		
		TriggerHandler.clearAllBypasses();
		
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'),'The MockTriggerHandler should not be bypassed.');
		
		System.assertEquals(false,TriggerHandler.isBypassed('TriggerHandler'),'The TriggerHandler should not be bypassed.');
	}
	
	/**
	* @description test the run method with the before insert trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_BeforeInsert(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals('beforeInsert',testTriggerHandler.triggerContextCalled,'The beforeInsert trigger context method should be called.');
	}
	
	/**
	* @description test the run method with the before update trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_BeforeUpdate(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals('beforeUpdate',testTriggerHandler.triggerContextCalled,'The beforeUpdate trigger context method should be called.');
	}
	
	/**
	* @description test the run method with the before delete trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_BeforeDelete(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_DELETE);
		testTriggerHandler.run();
		
		System.assertEquals('beforeDelete',testTriggerHandler.triggerContextCalled,'The beforeDelete trigger context method should be called.');
	}
	
	/**
	* @description test the run method with the after insert trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_AfterInsert(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_INSERT);
		testTriggerHandler.run();
		
		System.assertEquals('afterInsert',testTriggerHandler.triggerContextCalled,'The afterInsert trigger context method should be called.');
	}
	
	/**
	* @description test the run method with the after update trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_AfterUpdate(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_UPDATE);
		testTriggerHandler.run();
		
		System.assertEquals('afterUpdate',testTriggerHandler.triggerContextCalled,'The afterUpdate trigger context method should be called.');
	}
	
	/**
	* @description test the run method with the after delete trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_AfterDelete(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_DELETE);
		testTriggerHandler.run();
		
		System.assertEquals('afterDelete',testTriggerHandler.triggerContextCalled,'The afterDelete trigger context method should be called.');
	}
	
	/**
	* @description test the run method with the after undelete trigger context using the
	*			   MockTriggerHandler to ensure that the correct trigger context method is called.
	**/
	@isTest static void testRun_AfterUndelete(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.AFTER_UNDELETE);
		testTriggerHandler.run();
		
		System.assertEquals('afterUndelete',testTriggerHandler.triggerContextCalled,'The afterUndelete trigger context method should be called.');
	}
	
	/**
	* @description test the run method with no trigger context using the MockTriggerHandler to
	*			   ensure that no trigger context method is called.
	**/
	@isTest static void testRun_NoContext(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		try{
			testTriggerHandler.run();
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}

		System.assertEquals(null,testTriggerHandler.triggerContextCalled,'No trigger context method should be called.');
	}
	
	/**
	* @description test the validateIsTriggerHandler method with the MockTriggerHandler to ensure
	*			   that the handler is recognised as a valid TriggerHandler.
	**/
	@isTest static void testValidateIsTriggerHandler(){
		try{
			TriggerHandler.validateIsTriggerHandler('MockTriggerHandler');
			System.assert(true);
		}catch(TriggerHandlerException ex){
			System.assert(false);
		}catch(Exception ex){
			System.assert(false);
		}
	}
	
	/**
	* @description test the validateIsTriggerHandler method with an empty handler name to ensure
	*			   that a TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testValidateIsTriggerHandler_EmptyHandlerName(){
		try{
			TriggerHandler.validateIsTriggerHandler('');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the validateIsTriggerHandler method with an null handler name to ensure
	*			   that a TriggerHandlerException is thrown as expected.
	**/
	@isTest static void testValidateIsTriggerHandler_NullHandlerName(){
		try{
			String handlerName;
			TriggerHandler.validateIsTriggerHandler(handlerName);
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the validateIsTriggerHandler method with an invalid handler name to ensure
	*			   that a TriggerHandlerException is thrown as expected. Since only a class which
	*			   extends TriggerHandler can be bypassed.
	**/
	@isTest static void testValidateIsTriggerHandler_InvalidHandlerName(){
		try{
			TriggerHandler.validateIsTriggerHandler('TriggerHandlerException');
			System.assert(false);
		}catch(TriggerHandlerException ex){
			System.assert(true);
		}
	}
	
	/**
	* @description test the isValid method using the MockTriggerHandler to ensure that it returns 
	*			   true when the maxRecursion is null and the TriggerHandler is not bypassed.
	**/
	@isTest static void testIsValid_MaxRecursionNullTriggerHandlerNotBypassed(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		System.assertEquals(null,testTriggerHandler.maxRecursion);
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'));
		
		System.assertEquals(true,testTriggerHandler.isValid(),'Should return true when maxRecursion is null and the TriggerHandler is not bypassed');
	}
	
	/**
	* @description test the isValid method using the MockTriggerHandler to ensure that it returns 
	*			   true when the maxRecursion is greater than the recursionCount and the TriggerHandler
	*			   is not bypassed.
	**/
	@isTest static void testIsValid_MaxRecursionNotReachedTriggerHandlerNotBypassed(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.setMaxRecursion(3);
		
		System.assertEquals(3,testTriggerHandler.maxRecursion);
		System.assertEquals(0,testTriggerHandler.recursionCount);
		System.assertEquals(false,TriggerHandler.isBypassed('MockTriggerHandler'));
		
		System.assertEquals(true,testTriggerHandler.isValid(),'Should return true when maxRecursion is greater than the recursionCount and the TriggerHandler is not bypassed');
	}
	
	/**
	* @description test the isValid method using the MockTriggerHandler to ensure that it returns 
	*			   false when the recursionCount has reached maxRecursion.
	**/
	@isTest static void testIsValid_MaxRecursionReached(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		testTriggerHandler.setMaxRecursion(0);
		
		System.assertEquals(0,testTriggerHandler.maxRecursion);
		System.assertEquals(0,testTriggerHandler.recursionCount);
		
		System.assertEquals(false,testTriggerHandler.isValid(),'Should return false when maxRecursion is reached');
	}
	
	/**
	* @description test the isValid method using the MockTriggerHandler to ensure that it returns 
	*			   false when the TriggerHandler is bypassed.
	**/
	@isTest static void testIsValid_TriggerHandlerBypassed(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		TriggerHandler.bypass('MockTriggerHandler');
		
		System.assertEquals(true,TriggerHandler.isBypassed('MockTriggerHandler'));
		
		System.assertEquals(false,testTriggerHandler.isValid(),'Should return false when the TriggerHandler is bypassed');
	}
	
	/**
	* @description test the setTriggerContext method when no trigger has an active context.
	**/
	@isTest static void testSetTriggerContext_NoContext(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext();
		
		System.assertEquals(false,testTriggerHandler.isExecuting,'IsExecuting should be false as there is no active trigger context');
		
		System.assertEquals(null,testTriggerHandler.context,'context should be null as there is no active trigger context');
	}
	
	/**
	* @description test the setTriggerContext method when null is passed as the trigger context.
	**/
	@isTest static void testSetTriggerContext_NullContext(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		
		TriggerHandler.TriggerContext triggerContext;
		testTriggerHandler.setTriggerContext(triggerContext);
		
		System.assertEquals(false,testTriggerHandler.isExecuting,'IsExecuting should be false as there is no active trigger context');
		
		System.assertEquals(null,testTriggerHandler.context,'context should be null as there is no active trigger context');
	}
	
	/**
	* @description test the setTriggerContext method when trigger context is given.
	**/
	@isTest static void testSetTriggerContext_WithContext(){
		MockTriggerHandler testTriggerHandler = new MockTriggerHandler();
		testTriggerHandler.setTriggerContext(TriggerHandler.TriggerContext.BEFORE_INSERT);
		
		System.assertEquals(true,testTriggerHandler.isExecuting,'IsExecuting should be true as there is an active trigger context');
		
		System.assertEquals(TriggerHandler.TriggerContext.BEFORE_INSERT,testTriggerHandler.context,'context should be the same as the contect passed in.');
	}
	
}
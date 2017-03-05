//
//  MaduraSignalKitTests.swift
//  MaduraSignalKitTests
//
//  Created by qiscus on 1/15/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import XCTest
@testable import MaduraSignalKit

class MaduraSignalKitTests: XCTestCase {
    let callerId = "123"
    let calleeId = "789"
    let callSessioId = "ks0ajkansjkdnf93nfdjs"
    var caller: MaduraSignalEngine?
    var callee: MaduraSignalEngine?
    var callerCommand: SignalEngineCommand?
    var calleeCommand: SignalEngineCommand?
    var callerResponse: SignalEngineResponse?
    var calleeResponse: SignalEngineResponse?
    static var callerExp: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        
        print("test setup")
        callerResponse = MockCallerResponse()
        calleeResponse = MockCalleeResponse()
        
        let config = SignalEngineConfig(mqttHost:  "mqtt.qiscus.com", port: 1883)
        caller = MaduraSignalEngine(userId: callerId, signalResponse: callerResponse!, config: config)
        callee = MaduraSignalEngine(userId: calleeId, signalResponse: calleeResponse!, config: config)
        
        //caller?.signalCommand?.connect()
        //callee?.signalCommand?.connect()
        
        callerCommand = caller?.signalCommand
        calleeCommand = callee?.signalCommand
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        print("tear down")
    }
    
    func testCallerShouldConnectedToSignalEngine(){
        let mockCallerResponse = callerResponse as! MockCallerResponse
        mockCallerResponse.expConnectedEvent = expectation(description: "caller connection did succeed")
        
        // WHEN : a caller is connected to signal engine via above setup
        callerCommand?.connect()
        waitForExpectations(timeout: 5, handler: nil)
        
        // THEN : caller status connection is connected
        XCTAssertTrue(mockCallerResponse.stateConnected)
        
    }
    func testCalleShouldConnectedToSignalEngine(){
        // GIVEN : User already initialize the signalling engine
        
        
        //============== CALLER CONNCETION ==================
        // preparing caller expectation
        let mockCalleeResponse = calleeResponse as! MockCalleeResponse
        mockCalleeResponse.expConnectedEvent = expectation(description: "callee connection did succeed")
        
        // WHEN : a caller is connected to signal engine via above setup
        calleeCommand?.connect()
        waitForExpectations(timeout: 5, handler: nil)
        
        // THEN : caller status connection is connected
        XCTAssertTrue(mockCalleeResponse.stateConnected)
       
    }
    func testCallerShouldSubscribedTheirOwnSessionByDefault(){
        buildCallerConnection()
        // GIVEN : Caller already connected to singal engine
        // preparing caller expectation
        let mockCallerResponse = callerResponse as! MockCallerResponse
        mockCallerResponse.expUserSessionSubscribedEvent = expectation(description: "user session did subscribed")
        
        // WHEN : a caller is connected to singal engine, he should subcribe his user session automaticly
        waitForExpectations(timeout: 5, handler: nil)
        
        // THEN : status of user session is subscribed
        XCTAssertTrue(mockCallerResponse.stateUserSessionSubscribed)
    }
    
    
    func testCalleeShouldSubscribedTheirOwnSessionByDefault(){
        buildCalleeConnection()
        // GIVEN : Caller already connected to singal engine
        // preparing callee expectation
        let mockCalleeResponse = calleeResponse as! MockCalleeResponse
        mockCalleeResponse.expUserSessionSubscribedEvent = expectation(description: "user session did subscribed")
        
        // WHEN : a caller is connected to singal engine, he should subcribe his user session automaticly
        waitForExpectations(timeout: 5, handler: nil)
        
        // THEN : status of user session is subscribed
        XCTAssertTrue(mockCalleeResponse.stateUserSessionSubscribed)
    }
    
    func testCallerSubscribeFromCallSession(){
        buildCallerConnection()
        // GIVEN : user has already create a call session
        // preparing callee expectation
        let response = callerResponse as! MockCallerResponse
        response.expCallSessionSubscribedEvent = expectation(description: "caller subscribe from call session")
        
        // WHEN : user subscribe the call session
        
        callerCommand?.subscribe(fromCallSession: callSessioId)
        waitForExpectations(timeout: 5)
        
        // RESULT : status of call session is subscribed
        XCTAssertTrue(response.stateCallSessionSubscribed)
    }
    
    func testCalleeSubscribeFromCallSession(){
        buildCalleeConnection()
        // GIVEN : user has already create a call session
        // preparing callee expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expCallSessionSubscribedEvent = expectation(description: "callee subscribe from call session")
        
        // WHEN : user subscribe the call session
        
        calleeCommand?.subscribe(fromCallSession: callSessioId)
        waitForExpectations(timeout: 5)
        
        // RESULT : status of call session is subscribed
        XCTAssertTrue(response.stateCallSessionSubscribed)
    }
    func testCallerPublishInviationEventToCallee() {
        
        buildCallerConnection()
        buildCalleeConnection()
        
        //============== CALLER SEND INVITATION ==================
        // GIVEN : Both user already connected to their session
        // preparing callee expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expInvitationEvent = expectation(description: "calle get an invitation")
        
        // WHEN : caller send a call invitation
        try! self.callerCommand?.publish(event: .invite, to: self.calleeId, from: self.callerId, message: self.callSessioId)
        
        
        waitForExpectations(timeout: 5)
        // THEN : callee got invitation
        XCTAssertTrue(response.stateInvited)
    }
    
    func testCallePublishReadyEventToCaller(){
        
        buildCallerConnection()
        buildCalleeConnection()
        
        //============== CALLER SEND READY ==================
        // preparing caller expectation
        let response = callerResponse as! MockCallerResponse
        response.expReadyEvent =  expectation(description: "'calle is ready to call!' i replay the invitation")
        
        // GIVEN :  Callee receive an invitation.
        
        // WHEN : when callee receive intivation, He should replay with ready event
        try! self.calleeCommand?.publish(event: .ready, to: self.callerId, from: self.callerId, message: self.callSessioId)
        
        waitForExpectations(timeout: 5)
        
        // THEN : caller should get a waiting message
        XCTAssert(response.stateCalleeIsReady)
    }
    
    func testCalleePublishBussyEventToCaller(){
        
        buildCallerConnection()
        buildCalleeConnection()
        
        //============== CALLER SEND READY ==================
        // preparing caller expectation
        let response = callerResponse as! MockCallerResponse
        response.expBussyEvent =  expectation(description: "'calle is ready to call!' i replay the invitation")
        
        // GIVEN :  Callee receive an invitation.
        
        // WHEN : when callee receive intivation, He should replay with ready event
        try! self.calleeCommand?.publish(event: .bussy, to: self.callerId, from: self.callerId, message: self.callSessioId)
        
        waitForExpectations(timeout: 5)
        
        // THEN : caller should get a waiting message
        XCTAssert(response.stateCalleeIsBussy)
    }
    
    func testCallerPublishDialEventToCallSession(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        
        // preparing for calle expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expDialledEvent =  expectation(description: "calle get a dialling event")
        
        try! callerCommand?.publish(event: .dial, to: callSessioId, from: callerId)
        waitForExpectations(timeout: 5)
        
        XCTAssert(response.stateDialled)
        
    }
    
    func testCallerPublishJoinEventToCallSession(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        
        // preparing for calle expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expJoinedEvent =  expectation(description: "calle get a join event")
        
        try! callerCommand?.publish(event: .join, to: callSessioId, from: callerId)
        waitForExpectations(timeout: 5)
        
        XCTAssert(response.stateJoined)
    }
    
    func testCalleePublishWaitingEventToCallSession(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        
        //GIVEN : i am a calle.
        
        // preparing for calle expectation
        let response = callerResponse as! MockCallerResponse
        response.expWaitedEvent =  expectation(description: "calle waiting to answer or decline")
        
        // WHEN : After reply the invitation with "ready" event, i should publish my waiting state!
        try! calleeCommand?.publish(event: .wait, to: callSessioId, from: callerId)
        waitForExpectations(timeout: 5)
        
        // RESULT : caller should receive waiting event
        XCTAssert(response.stateWaiting)
    }
    
    func testCallePublishRejectEventtoCallSession(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        
        //GIVEN : i am a calle.
        
        // preparing for calle expectation
        let response = callerResponse as! MockCallerResponse
        response.expRejectedEvent =  expectation(description: "calle decline!")
        
        // WHEN : After reply the invitation with "ready" event, i should publish my waiting state!
        try! calleeCommand?.publish(event: .reject, to: callSessioId, from: callerId)
        waitForExpectations(timeout: 5)
        
        // RESULT : caller should receive waiting event
        XCTAssert(response.stateRejected)
    }
    func testCallerPublishCancelEventToCallSession(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        
        // GIVEN : i am caller. i want to cancel my dial
        // preparing for callee expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expCancelledEvent = expectation(description: "caller was cancel the dialling")
        
        // WHEN : caller cancel the dialling
        try! callerCommand?.publish(event: .cancel, to: callSessioId, from: callerId)
        waitForExpectations(timeout: 5)
        
        XCTAssert(response.stateCanceled)
    }
    
    func testCalleePublishAcceptEvent(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        // GIVEN : i am callee. ready to answer the dialling
        // preparing for caller expectation
        let response = callerResponse as! MockCallerResponse
        response.expAcceptedEvent = expectation(description: "callee is answer my calling")
        
        // WHEN : i publish accept event
        try! calleeCommand?.publish(event: .accept, to: callSessioId, from: calleeId)
        waitForExpectations(timeout: 5)
        
        // RESULT : caller should receive accept event
        XCTAssert(response.stateAccepted)
    }
    
    func testCalleePublishJoinEvent(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        // GIVEN : i am callee already join to call engine.
        // preparing for caller expectation
        let response = callerResponse as! MockCallerResponse
        response.expJoinedEvent = expectation(description: "callee is join to conversation now!")
        
        // WHEN : i publish join event
        try! calleeCommand?.publish(event: .join, to: callSessioId, from: calleeId)
        waitForExpectations(timeout: 5)
        
        // RESULT : caller receive join event
        XCTAssert(response.stateJoined)
    }
    
    func testCallerPublishLeaveEvent(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        // GIVEN : i am caller want to close the conversation.
        // preparing for caller expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expLeavedEvent = expectation(description: "caller was close the conversation")
        
        // WHEN : i publish leave event
        try! callerCommand?.publish(event: .leave, to: callSessioId, from: calleeId)
        waitForExpectations(timeout: 5)
        
        // RESULT : caller receive leave event
        XCTAssert(response.stateLeaved)
        
    }
    
    func testCallerPublishHangupEvent(){
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        // GIVEN : i am caller want to close the conversation.
        // preparing for caller expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expHangupEvent = expectation(description: "caller was hangup his phone")
        
        // WHEN : i publish leave event
        try! callerCommand?.publish(event: .hangup, to: callSessioId, from: calleeId)
        waitForExpectations(timeout: 5)
        
        // RESULT : caller receive leave event
        XCTAssert(response.stateHangup)
    }
    
    func testCallerUnsubscribeFromCallSession(){
        
        buildCallerConnection()
        buildCalleeConnection()
        
        callerSubscribeToCallSession()
        calleeSubscribeToCallSession()
        
        // GIVEN : i am caller already leave from conversation and hangup my phone
        // preparing expectation
        let response  = callerResponse as! MockCallerResponse
        response.expCallSessionUnsubscribedEvent =  expectation(description: "\(callSessioId) should unsubscribed")
        
        // WHEN : i unsubscribe the call session
        callerCommand?.unsubscribe(fromCallSession: callSessioId)
        waitForExpectations(timeout: 5)
        // RESULT : 
        XCTAssert(response.stateCallSessionUnsubscribed)
    }
    //==================================================================================//
    //                      HELPER FUNCTION
    //==================================================================================//
   
    private func buildCallerConnection(){
        
        //============== CALLEE CONNCETION ==================
        let mockCallerResponse = callerResponse as! MockCallerResponse
        mockCallerResponse.expConnectedEvent = expectation(description: "caller connection did succeed")
        
        // WHEN : a caller is connected to signal engine via above setup
        callerCommand?.connect()
        waitForExpectations(timeout: 5, handler: nil)
        
        // THEN : caller status connection is connected
        XCTAssertTrue(mockCallerResponse.stateConnected)
    }
    
    private func buildCalleeConnection(){
        
        
        //============== CALLEE CONNCETION ==================
        // preparing callee expectation
        let mockCalleeResponse = calleeResponse as! MockCalleeResponse
        mockCalleeResponse.expConnectedEvent = expectation(description: "callee connection did succeed")
        
        // WHEN : a callee is connected to signal engine via above setup
        calleeCommand?.connect()
        waitForExpectations(timeout: 5, handler: nil)
        
        // THEN : status of connection is connected
        XCTAssertTrue(mockCalleeResponse.stateConnected)
    }
    
    private func calleeSubscribeToCallSession(){
        print("bantuan callee subscribe to call session")
        // GIVEN : user has already create a call session
        // preparing callee expectation
        let response = calleeResponse as! MockCalleeResponse
        response.expCallSessionSubscribedEvent = expectation(description: "callee subscribe from call session")
        
        // WHEN : user subscribe the call session
        
        calleeCommand?.subscribe(fromCallSession: callSessioId)
        waitForExpectations(timeout: 5)
        
        // RESULT : status of call session is subscribed
        XCTAssertTrue(response.stateCallSessionSubscribed)
    }
    private func callerSubscribeToCallSession(){
        // GIVEN : user has already create a call session
        // preparing callee expectation
        let response = callerResponse as! MockCallerResponse
        response.expCallSessionSubscribedEvent = expectation(description: "caller subscribe from call session")
        
        // WHEN : user subscribe the call session
        
        callerCommand?.subscribe(fromCallSession: callSessioId)
        waitForExpectations(timeout: 5)
        
        // RESULT : status of call session is subscribed
        XCTAssertTrue(response.stateCallSessionSubscribed)
    }
}


class MockCallerResponse: SignalEngineResponse{
    
    var expWaitedEvent, expDialledEvent,
    expJoinedEvent, expLeavedEvent, expCancelledEvent, expInvitationEvent,expUserSessionSubscribedEvent,
    expUserSessionUnsubscribbedEvent, expCallSessionSubscribedEvent, expCallSessionUnsubscribedEvent,
    expConnectedEvent,expDisconnectedEvent, expBussyEvent, expReadyEvent,
    expRejectedEvent,expAcceptedEvent,expHangupEvent,expPingpongEvent,expCompletedEvent: XCTestExpectation?
    var stateInvited:Bool = false
    var stateUserSessionSubscribed = false
    var stateUserSessionUnsubscribed = false
    var stateCallSessionSubscribed = false
    var stateCallSessionUnsubscribed = false
    var stateConnected = false
    var stateWaiting = false
    var stateCalleeIsReady = false
    var stateCalleeIsBussy = false
    var stateDialled = false
    var stateRejected = false
    var stateAccepted = false
    var stateHangup = false
    var statePingpong = false
    var stateCompleted = false
    var stateJoined = false
    var stateLeaved = false
    var stateCanceled = false
    
    func calleeDidWaitingAnswer() {
        self.stateWaiting = true
        expWaitedEvent?.fulfill()
    }
    func onReceiveDial() {
        self.stateDialled = true
        expDialledEvent?.fulfill()
    }
    func peopleDidJoin() {
        self.stateJoined = true
        expJoinedEvent?.fulfill()
    }
    func peopleDidLeave() {
        self.stateLeaved = true
        expLeavedEvent?.fulfill()
    }
    func callerDidCancel() {
        self.stateCanceled = true
        expCancelledEvent?.fulfill()
    }
    func onReceiveInvitation(message: String, from:String) {
        self.stateInvited = true
        expInvitationEvent?.fulfill()
    }
    
    func userSessionDidSubscribe(){
        self.stateUserSessionSubscribed = true
        expUserSessionSubscribedEvent?.fulfill()
    }
    func userSessionDidUnsubscribe(){
        self.stateUserSessionUnsubscribed = true
        expUserSessionUnsubscribbedEvent?.fulfill()
    }
    func callSessionDidSubscribe(){
        self.stateCallSessionSubscribed = true
        expCallSessionSubscribedEvent?.fulfill()
    }
    func callSessionDidUnsubscribe(){
        self.stateCallSessionUnsubscribed = true
        expCallSessionUnsubscribedEvent?.fulfill()
    }
    
    func onConnected(){
        print("mock caller on connected")
        self.stateConnected = true
        expConnectedEvent?.fulfill()
    }
    func onDisconnected(){
        print("mock caller on disconnected")
        self.stateConnected = false
        expDisconnectedEvent?.fulfill()
    }
    public func onCalleeIsReady() {
        self.stateCalleeIsReady = true
        expReadyEvent?.fulfill()
    }
    
    public func onCalleeIsBussy() {
        self.stateCalleeIsBussy = true
        expBussyEvent?.fulfill()
    }
    func peopleDidReject(){
        self.stateRejected = true
        expRejectedEvent?.fulfill()
    }
    func peopleDidAnswer(){
        self.stateAccepted = true
        expAcceptedEvent?.fulfill()
    }
    func peopleDidHangup(){
        self.stateHangup = true
        expHangupEvent?.fulfill()
    }
    func peopleDidPing(){
        self.statePingpong = true
        expPingpongEvent?.fulfill()
    }
    
    func onCompleted(){
        self.stateCompleted = true
        expCompletedEvent?.fulfill()
    }
}


class MockCalleeResponse: SignalEngineResponse{
    
    var expWaitedEvent, expDialledEvent,
        expJoinedEvent, expLeavedEvent, expCancelledEvent, expInvitationEvent,expUserSessionSubscribedEvent,
        expUserSessionUnsubscribbedEvent, expCallSessionSubscribedEvent, expCallSessionUnsubscribedEvent,
    expConnectedEvent,expDisconnectedEvent, expBussyEvent, expReadyEvent,
    expRejectedEvent,expAcceptedEvent,expHangupEvent,expPingpongEvent,expCompletedEvent: XCTestExpectation?
    var stateInvited:Bool = false
    var stateUserSessionSubscribed = false
    var stateUserSessionUnsubscribed = false
    var stateCallSessionSubscribed = false
    var stateCallSessionUnsubscribed = false
    var stateConnected = false
    var stateCalleeIsReady = false
    var stateCalleeIsBussy = false
    var stateWaiting = false
    var stateDialled = false
    var stateRejected = false
    var stateAccepted = false
    var stateHangup = false
    var statePingpong = false
    var stateCompleted = false
    var stateJoined = false
    var stateLeaved = false
    var stateCanceled = false
    func calleeDidWaitingAnswer() {
        self.stateWaiting = true
        expWaitedEvent?.fulfill()
    }
    func onReceiveDial() {
        self.stateDialled = true
        expDialledEvent?.fulfill()
    }
    func peopleDidJoin() {
        self.stateJoined = true
        expJoinedEvent?.fulfill()
    }
    func peopleDidLeave() {
        self.stateLeaved = true
        expLeavedEvent?.fulfill()
    }
    func callerDidCancel() {
        self.stateCanceled = true
        expCancelledEvent?.fulfill()
    }
    func onReceiveInvitation(message: String, from:String) {
        self.stateInvited = true
        expInvitationEvent?.fulfill()
    }
    
    func userSessionDidSubscribe(){
        self.stateUserSessionSubscribed = true
        expUserSessionSubscribedEvent?.fulfill()
    }
    func userSessionDidUnsubscribe(){
        self.stateUserSessionUnsubscribed = true
        expUserSessionUnsubscribbedEvent?.fulfill()
    }
    func callSessionDidSubscribe(){
        self.stateCallSessionSubscribed = true
        expCallSessionSubscribedEvent?.fulfill()
    }
    func callSessionDidUnsubscribe(){
        self.stateCallSessionUnsubscribed = true
        expCallSessionUnsubscribedEvent?.fulfill()
    }
    
    func onConnected(){
        print("mock caller on connected")
        self.stateConnected = true
        expConnectedEvent?.fulfill()
    }
    func onDisconnected(){
        print("mock caller on disconnected")
        self.stateConnected = false
        expDisconnectedEvent?.fulfill()
    }
    public func onCalleeIsReady() {
        self.stateCalleeIsReady = true
        expReadyEvent?.fulfill()
    }
    
    public func onCalleeIsBussy() {
        self.stateCalleeIsBussy = true
        expBussyEvent?.fulfill()
    }
    func peopleDidReject(){
        self.stateRejected = true
        expRejectedEvent?.fulfill()
    }
    func peopleDidAnswer(){
        self.stateAccepted = true
        expAcceptedEvent?.fulfill()
    }
    func peopleDidHangup(){
        self.stateHangup = true
        expHangupEvent?.fulfill()
    }
    func peopleDidPing(){
        self.statePingpong = true
        expPingpongEvent?.fulfill()
    }
    
    func onCompleted(){
        self.stateCompleted = true
        expCompletedEvent?.fulfill()
    }
}

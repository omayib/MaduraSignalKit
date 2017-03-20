//
//  SignalEngineResponse.swift
//  MaduraSignalKit
//
//  Created by qiscus on 1/18/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
public protocol SignalEngineResponse{
    func onConnected()
    func onDisconnected()
    func userSessionDidSubscribe()
    func userSessionDidUnsubscribe()
    func callSessionDidSubscribe()
    func callSessionDidUnsubscribe()
    /**
     people initiate call to his friend by publish an invitation event.
     
     
     - parameters: 
        - message: contains `callSessionId`
     
     - returns: void
    */
    func onReceiveInvitation(message:String, from userId:String)
    func onCalleeIsBussy()
    func onCalleeIsReady()
    //call Event
    func onReceiveDial(from userId:String)
    func calleeDidWaitingAnswer()
    func callerDidCancel()
    func peopleDidJoin()
    func peopleDidLeave()
    func peopleDidReject()
    func peopleDidAnswer()
    func peopleDidHangup()
    func peopleDidPing()
    func onCallCompleted()
}

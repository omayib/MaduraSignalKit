//
//  MqttSignalEngine.swift
//  MaduraSignalKit
//
//  Created by qiscus on 1/18/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation
import SwiftMQTT

class MqttSignalEngine: SignalEngineCommand{
    
    private var userSessionInvitationSubscribed: Bool = false
    private var userSessionBussySubscribed: Bool = false
    private var userSessionReadySubscribed: Bool = false
    private var callSessionDialSubscribed: Bool = false
    private var callSessionWaitSubscribed: Bool = false
    private var callSessionAcceptSubscribed: Bool = false
    private var callSessionRejectSubscribed: Bool = false
    private var callSessionJoinSubscribed: Bool = false
    private var callSessionLeaveSubscribed: Bool = false
    private var callSessionHangupSubscribed: Bool = false
    private var callSessionCompleteSubscribed: Bool = false
    private var callSessionCancelSubscribed: Bool = false
    
    internal var signalResponse: SignalEngineResponse?
    private var mqttSession: MQTTSession?
    internal var clientId:String?
    internal var callSessionId:String?
    
    init(signalEngineResponse: SignalEngineResponse, clientId:String, config: SignalEngineConfig) {
        self.signalResponse = signalEngineResponse
        self.clientId = clientId
        // set MQTT Client Configuration
        mqttSession = MQTTSession(host: config.mqttHost, port: UInt16(config.port), clientID: clientId, cleanSession: true, keepAlive: 5, useSSL: false)
        print("init mqtt host \(config.mqttHost)")
        print("init mqtt port \(config.port)")
        mqttSession?.delegate = self
        
    }
    deinit {
        print("mqttsignal engine deinit")
        self.mqttSession = nil
    }
    func connect() {
        print("\(self.clientId!) connecting....")
        //self.mqttSession?.disconnect()
        self.mqttSession?.connect { (succeeded, error) -> Void in
            if succeeded {
                print("\(self.clientId!) Connected!")
                self.signalResponse?.onConnected()
                //after connect should subscribe the user session
                self.subscribe(toUserSession: self.clientId!)
            }else{
                print("connect error \(error)")
                self.signalResponse?.onDisconnected()
            }
        }
    }
    func disconnect() {
        print("DISconnecting....")
        mqttSession?.disconnect()
        self.signalResponse?.onDisconnected()
    }
    func subscribe(toCallSession callSessionId:String){
        
        self.callSessionId = callSessionId
        
        let topicCallDial =  String.init(format:  MqttTopic.dial.rawValue, callSessionId)
        let topicCallWait =  String.init(format:  MqttTopic.wait.rawValue, callSessionId)
        let topicCallCancel =  String.init(format:  MqttTopic.cancel.rawValue, callSessionId)
        let topicCallAccept =  String.init(format:  MqttTopic.accept.rawValue, callSessionId)
        let topicCallReject =  String.init(format:  MqttTopic.reject.rawValue, callSessionId)
        let topicCallJoin =  String.init(format:  MqttTopic.join.rawValue, callSessionId)
        let topicCallLeave =  String.init(format:  MqttTopic.leave.rawValue, callSessionId)
        let topicCallhangup =  String.init(format:  MqttTopic.hangup.rawValue, callSessionId)
        let topicCallComplete =  String.init(format:  MqttTopic.complete.rawValue, callSessionId)
        
        
        var topicsCallSession:[String] = []
        topicsCallSession.append(topicCallWait)
        topicsCallSession.append(topicCallDial)
        topicsCallSession.append(topicCallCancel)
        topicsCallSession.append(topicCallAccept)
        topicsCallSession.append(topicCallReject)
        topicsCallSession.append(topicCallJoin)
        topicsCallSession.append(topicCallLeave)
        topicsCallSession.append(topicCallhangup)
        topicsCallSession.append(topicCallComplete)
        
        for topicCall in topicsCallSession {
            print("subscribe to topic \(topicCall)...")
            mqttSession?.subscribe(to: topicCall, delivering: .atLeastOnce) { (succeeded, error) -> Void in
                if succeeded {
                    print("\(topicCall) Subscribed!")
                    if topicCall == topicCallDial {
                        self.callSessionDialSubscribed = true
                    }else if topicCall == topicCallAccept {
                        self.callSessionAcceptSubscribed = true
                    }else if topicCall == topicCallReject {
                        self.callSessionRejectSubscribed = true
                    }else if topicCall == topicCallJoin {
                        self.callSessionJoinSubscribed = true
                    }else if topicCall == topicCallLeave {
                        self.callSessionLeaveSubscribed = true
                    }else if topicCall == topicCallWait {
                        self.callSessionWaitSubscribed = true
                    }else if topicCall == topicCallhangup {
                        self.callSessionHangupSubscribed = true
                    }else if topicCall == topicCallCancel{
                        self.callSessionCancelSubscribed = true
                    }else{
                        self.callSessionCompleteSubscribed = true
                    }
                    self.updateCallSessionStatus()
                }else{
                    self.callSessionId = nil
                }
            }
        }
    }
    func updateCallSessionStatus(){
        if callSessionCompleteSubscribed && callSessionHangupSubscribed && callSessionWaitSubscribed &&
            callSessionLeaveSubscribed && callSessionJoinSubscribed && callSessionRejectSubscribed &&
            callSessionAcceptSubscribed && callSessionDialSubscribed && callSessionCancelSubscribed{
            signalResponse?.callSessionDidSubscribe()
        }else{
            signalResponse?.callSessionDidUnsubscribe()
        }
    }
    func subscribe(toUserSession userId:String){
        print("preparng subscribe....")
        let topicInvitation =  String.init(format:  MqttTopic.invitation.rawValue, userId)
        let topicBussy = String.init(format: MqttTopic.bussy.rawValue, userId)
        let topicReady = String.init(format: MqttTopic.ready.rawValue, userId)
        
        mqttSession?.subscribe(to: topicInvitation, delivering: .atLeastOnce) { (succeeded, error) -> Void in
            if succeeded {
                print("\(topicInvitation) : Subscribed!")
                self.userSessionInvitationSubscribed = true
                self.updateUserSessionStatus()
            }
        }
        
        mqttSession?.subscribe(to: topicReady, delivering: .atLeastOnce) { (succeeded, error) -> Void in
            if succeeded {
                print("\(topicReady) : Subscribed!")
                self.userSessionReadySubscribed = true
                self.updateUserSessionStatus()
            }
        }
        
        mqttSession?.subscribe(to: topicBussy, delivering: .atLeastOnce) { (succeeded, error) -> Void in
            if succeeded {
                print("\(topicBussy) : Subscribed!")
                self.userSessionBussySubscribed = true
                self.updateUserSessionStatus()
            }
        }
    }
    
    func unsubscribe(fromCallSession callSessionId:String){
        let topicCallWait =  String.init(format:  MqttTopic.wait.rawValue, callSessionId)
        let topicCallDial =  String.init(format:  MqttTopic.dial.rawValue, callSessionId)
        let topicCallCancel =  String.init(format:  MqttTopic.cancel.rawValue, callSessionId)
        let topicCallAccept =  String.init(format:  MqttTopic.accept.rawValue, callSessionId)
        let topicCallReject =  String.init(format:  MqttTopic.reject.rawValue, callSessionId)
        let topicCallJoin =  String.init(format:  MqttTopic.join.rawValue, callSessionId)
        let topicCallLeave =  String.init(format:  MqttTopic.leave.rawValue, callSessionId)
        let topicCallhangup =  String.init(format:  MqttTopic.hangup.rawValue, callSessionId)
        let topicCallComplete =  String.init(format:  MqttTopic.complete.rawValue, callSessionId)
        
        
        var topicsCallSession:[String] = []
        topicsCallSession.append(topicCallDial)
        topicsCallSession.append(topicCallCancel)
        topicsCallSession.append(topicCallAccept)
        topicsCallSession.append(topicCallReject)
        topicsCallSession.append(topicCallJoin)
        topicsCallSession.append(topicCallLeave)
        topicsCallSession.append(topicCallWait)
        topicsCallSession.append(topicCallhangup)
        topicsCallSession.append(topicCallComplete)
        
        print("UNsubscribe to topics \(topicsCallSession)...")
        mqttSession?.unSubscribe(from: topicsCallSession, completion: { (succeeded, error) in
            if succeeded {
                print(" Unsubscribed!")
                self.callSessionId = nil
                self.callSessionDialSubscribed = false
                self.callSessionAcceptSubscribed = false
                self.callSessionRejectSubscribed = false
                self.callSessionJoinSubscribed = false
                self.callSessionLeaveSubscribed = false
                self.callSessionWaitSubscribed = false
                self.callSessionHangupSubscribed = false
                self.callSessionCompleteSubscribed = false
                self.callSessionCancelSubscribed = false
                self.updateCallSessionStatus()
            }
        })
    }
    
    func unsubscribe(fromUserSession myUserId:String){
        let topicInvitation =  String.init(format:  MqttTopic.invitation.rawValue, myUserId)
        let topicPingpong =  String.init(format:  MqttTopic.pingpong.rawValue, myUserId)
        
        
        print("UNsubscribe to topic \(topicInvitation)")
        mqttSession?.unSubscribe(from: topicInvitation, completion: { (succeeded, error) in
            if succeeded {
                print(" Unsubscribed!")
                self.userSessionInvitationSubscribed = false
                self.updateUserSessionStatus()
            }
        })
        
        print("UNsubscribe to topic \(topicPingpong)")
        mqttSession?.unSubscribe(from: topicPingpong, completion: { (succeeded, error) in
            if succeeded {
                print(" Unsubscribed!")
                self.userSessionInvitationSubscribed = false
                self.updateUserSessionStatus()
            }
        })
    }
    public func publish(event userEvent: UserEvent, to userSession: String, message callSessionId: String) throws {
        var message: Data
        var topic: String
        switch userEvent {
        case .invite:
            
            topic =  String.init(format:  MqttTopic.invitation.rawValue, userSession)
            print("publish to topic \(topic)")
            
            let data = ["event" : "invite",
                            "from": clientId!,
                            "call_session_id": callSessionId] as [String : Any]
            print("message to pubslish : \(data)")
            
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            
            break
        case .bussy:
            
            topic =  String.init(format:  MqttTopic.bussy.rawValue, userSession)
            print("publish to topic \(topic)")
            
            let data = ["event" : "bussy",
                        "from": clientId!] as [String : Any]
            print("message to pubslish : \(data)")
            
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .ready:
            
            topic =  String.init(format:  MqttTopic.ready.rawValue, userSession)
            print("publish to topic \(topic)")
            
            let data = ["event" : "ready",
                        "from": clientId!] as [String : Any]
            print("message to pubslish : \(data)")
            
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            
            print("message.. \(message)")
            break
        }
        print("message.. \(mqttSession?.clientID)")
        mqttSession?.publish(message, in: topic, delivering: .atLeastOnce, retain: true, completion: { (succeeded, error) in
            if succeeded {
                print("message in \(topic) : published!")
            }else{
                print("error publish user event: \(error)")
            }
        })
        
    }
    
    public func publish(event callEvent: CallEvent, to callSession: String) throws {
        let message: Data
        let topic:String
        switch callEvent {
        case .dial:
            topic =  String.init(format:  MqttTopic.dial.rawValue, callSession)
            let data =  ["event" : "dial",
                         "from": clientId!] as [String : Any]
            print("\(data) will publish to \(topic)")
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .wait:
            topic =  String.init(format:  MqttTopic.wait.rawValue, callSession)
            let data =  ["event" : "wait",
                         "from": clientId!] as [String : Any]
            print("\(data) will publish to \(topic)")
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .cancel:
            topic =  String.init(format:  MqttTopic.cancel.rawValue, callSession)
            let data =  ["event" : "cancel",
                         "from": clientId!] as [String : Any]
            print("\(data) will publish to \(topic)")
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .join:
            topic =  String.init(format:  MqttTopic.join.rawValue, callSession)
            let data =  ["event" : "join",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .leave:
            topic =  String.init(format:  MqttTopic.leave.rawValue, callSession)
            let data =  ["event" : "leave",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .reject:
            topic =  String.init(format:  MqttTopic.reject.rawValue, callSession)
            let data =  ["event" : "reject",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .accept:
            topic =  String.init(format:  MqttTopic.accept.rawValue, callSession)
            let data =  ["event" : "accept",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .hangup:
            topic =  String.init(format:  MqttTopic.hangup.rawValue, callSession)
            let data =  ["event" : "hangup",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .presence:
            topic =  String.init(format:  MqttTopic.presence.rawValue, callSession)
            let data =  ["event" : "presence",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .complete:
            topic =  String.init(format:  MqttTopic.complete.rawValue, callSession)
            let data =  ["event" : "complete",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .ping:
            topic =  String.init(format:  MqttTopic.pingpong.rawValue, callSession)
            let data =  ["event" : "ping",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        case .pong:
            topic =  String.init(format:  MqttTopic.pingpong.rawValue, callSession)
            let data =  ["event" : "pong",
                         "from": clientId!] as [String : Any]
            message = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            break
        }
        print("publish in topic \(topic)")
        mqttSession?.publish(message, in: topic, delivering: .atLeastOnce, retain: true) { (succeeded, error) -> Void in
            if succeeded {
                print("message in \(topic) : published!")
            }else{
                print("publish error")
            }
        }

        
    }
    private func updateUserSessionStatus(){
        print("updateUserSessionStatus")
        if userSessionBussySubscribed && userSessionReadySubscribed
            && userSessionInvitationSubscribed {
            self.signalResponse?.userSessionDidSubscribe()
        }else{
            self.signalResponse?.userSessionDidUnsubscribe()
        }
    }
    
}

extension MqttSignalEngine: MQTTSessionDelegate{
    public func mqttSocketErrorOccurred(session: MQTTSession) {
    }

    
    func mqttSession(session: MQTTSession, received message: Data, in topic: String) {
        let string = String(data: message, encoding: .utf8)!
        print(string)
    }
    
    func mqttDidDisconnect(session: MQTTSession) {
        print("did disconnect")
        self.signalResponse?.onDisconnected()
    }
    
    func mqttDidReceive(message data: Data, in topic: String, from session: MQTTSession) {
        let stringData = String(data: data, encoding: .utf8)!
        
        //let data = message.data(using: .utf8, allowLossyConversion: false)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        var fromUserId=""
        if let dictionary = json as? [String: Any] {
            if let from = dictionary["from"] as? String {
                fromUserId = from
            }
        }
        if fromUserId == self.clientId {
            return
        }
        
        print("\(clientId!) didreceive from \(topic) with data : \(stringData)")
        
        if topic == ("/\(clientId!)/\(MqttTopic.invitation)") {
            var callSessionId = ""
            if let dictionary = json as? [String: Any] {
                if let callSession = dictionary["call_session_id"] as? String {
                    callSessionId = callSession
                }
            }
            self.signalResponse?.onReceiveInvitation(message: callSessionId, from: fromUserId)
        }else if topic == ("/\(clientId!)/\(MqttTopic.bussy)") {
            self.signalResponse?.onCalleeIsBussy()
        }else if topic == ("/\(clientId!)/\(MqttTopic.ready)") {
            self.signalResponse?.onCalleeIsReady()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.dial)"){
            self.signalResponse?.onReceiveDial(from: fromUserId)
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.wait)"){
            self.signalResponse?.calleeDidWaitingAnswer()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.cancel)"){
            self.signalResponse?.callerDidCancel()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.join)"){
            self.signalResponse?.peopleDidJoin()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.leave)"){
            self.signalResponse?.peopleDidLeave()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.reject)"){
            self.signalResponse?.peopleDidReject()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.accept)"){
            self.signalResponse?.peopleDidAnswer()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.hangup)"){
            self.signalResponse?.peopleDidHangup()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.complete)"){
            self.signalResponse?.onCallCompleted()
        }else if topic == ("call/\(callSessionId!)/\(MqttTopic.pingpong)"){
            if let dictionary = json as? [String: Any] {
                if let eventData = dictionary["event"] as? String {
                    if eventData == "ping"{
                        self.signalResponse?.peopleDidPing()
                    }
                }
            }
        }
    }
    
    
    
}

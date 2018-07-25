//
//  PickEvents.swift
//  MySampleApp
//
//
// Copyright 2018 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.21
//

import Foundation
import UIKit
import AWSDynamoDB

@objcMembers // <-- don't remove this, it will break uploading
class PickEvents: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _userId: String?
    var _creationTime: String?
    var _address: String?
    var _assignedTeamID: String?
    var _creationDate: String?
    var _eventDate: String?
    var _eventTime: String?
    var _latitude: NSNumber?
    var _longitude: NSNumber?
    var _registeredUsers: [String]?
    var _treeMap: [String: String]?
    var _distanceFrom: Int?
    class func dynamoDBTableName() -> String {
        
        return "vancouverfruittreepr-mobilehub-79870386-PickEvents"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {
        
        return "_creationTime"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
            "_userId" : "userId",
            "_creationTime" : "creationTime",
            "_address" : "address",
            "_assignedTeamID" : "assignedTeamID",
            "_creationDate" : "creationDate",
            "_eventDate" : "eventDate",
            "_eventTime" : "eventTime",
            "_latitude" : "latitude",
            "_longitude" : "longitude",
            "_registeredUsers" : "registeredUsers",
            "_treeMap" : "treeMap",
        ]
    }
}

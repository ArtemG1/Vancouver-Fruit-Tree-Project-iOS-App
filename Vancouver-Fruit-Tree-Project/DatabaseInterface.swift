//
//  DatabaseInterface.swift
//  Vancouver-Fruit-Tree-Project
//
//  Created by Cameron Savage on 2018-06-30.
//  Copyright © 2018 Harvest8. All rights reserved.
//
import UIKit
import Foundation
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSAuthCore
import AWSCore
//import AWSS3
//import AWSCognitoIdentityProviderASF

@objcMembers
class DatabaseInterface: NSObject {
    
    //MARK: User Methods
   
    func queryUsers() -> [AWSCognitoIdentityProviderUserType]?{
        var users = [AWSCognitoIdentityProviderUserType]()
        var test = [Dictionary<String, String>]()
        
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,identityPoolId:"us-east-1:418ae064-cd87-4807-9234-412af6afcb20")
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        

        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let Cognito = AWSCognitoIdentityProvider.default()
        var queryComplete = false
        let request = AWSCognitoIdentityProviderListUsersRequest()
        request?.attributesToGet = []
        request?.userPoolId = "us-east-1_LXKwVfwkz"
        Cognito.listUsers(request!).continueOnSuccessWith(block: { (task: AWSTask) -> AnyObject?
        in
        if let error = task.error as NSError? {
            
            print("Amazon DynamoDB Save Error: \(error)")
            queryComplete = true;
            
            return nil
        }
            
            
            if task.result?.users != nil{
            for us in (task.result?.users)!{
                var temp = Dictionary<String,String>()
                temp["user-name"] = us.username
                temp["enabled"] = "\(us.enabled)"
                temp["user-create-date"] = us.username
                temp["status"] = "\(us.userStatus)"
                test.append(temp)
                users.append(us)
                
            }
            }
            
            print(test)
                        return task
            
            
        }).continueOnSuccessWith(block: {(task: AWSTask) -> AnyObject?
            in
            queryComplete = true
            print("Query set to complete")
            
            return task.result
        })
        
        
        
     
        
        
        
        while queryComplete == false {
        
            if queryComplete == true{
                print("query is finished")
                
                queryComplete = false
                
                return users
            }
        }
        return users
        
    }
    
    /// returns hashes for all pick events that a user is signed up for
    ///
    /// - Parameter userId: the user's userID
    /// - Returns: returns a Users() object; hashes can be accessed via the ._pickEvents attribute, which contains a [ [String] ] array. Each [String] element contains 3 elements: the partition hash (userId) and the sort hash (creationTime) of the PickEvent, which can be used to read it, and another element that is either 0 or 1 to mark a volunteer's attendance of an event
    func queryUserInfo(userId: String) -> Users? {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        var received: Users?
        var queryComplete = false
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId";
        queryExpression.expressionAttributeNames = ["#userId": "userId"]
        queryExpression.expressionAttributeValues = [":userId": userId]
        
        //let currentUserID = AWSIdentityManager.default().identityId
        
        //if currentUserID != userId{
           // print("Error: User ID of current user and creator do not match, read denied")
       // }
        
       
        dynamoDBObjectMapper.query(Users.self, expression: queryExpression)
        { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            
            if output != nil {
                for user in output!.items {
                    let userItem = user as? Users
                    //print("\(pickItem!._eventDate!)")
                    received = userItem!
                }
            }
            
            queryComplete = true;
        }
    
        //waits for query to complete before returning
        while queryComplete == false {
            if queryComplete == true{
                print("query is finished")
                queryComplete = false
                return received //received! != nil
            }
        }
        
        return received //so Xcode stops complaining
        
    }
    
    /// Saves a pick event to the user's personal database entry
    ///
    /// - Parameters:
    ///   - pickItem: the PickEvent that the user is signing up for
    ///   - userId: the userId of the user
    func signUpForPickEvent (pickItem: PickEvents, userId: String){
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> signUpForPickEvent...")
        
        let UserItemQuery: Users? = queryUserInfo(userId: userId)
        
        var UserItem: Users = Users()
        
        if UserItemQuery != nil {
            UserItem = UserItemQuery!
        }
        
        else {
            UserItem._userId = userId
        }
        
        //UserItem._userId = AWSIdentityManager.default().identityId
        //UserItem._pickEvents?.append((pickItem._userId!, pickItem._creationTime!, "0"))
        
        if UserItem._pickEvents != nil {
            //UserItem._pickEvents!.append((pickItem, "0"))
            print("There are existing events in the list")
            //check if pick event exists in the array already
            
            let count = UserItem._pickEvents!.count
            print("there are " + String(count) + " items")
            var index: Int?
            var i: Int = 0
            
            while index == nil && count != i {
                
                if pickItem._userId == UserItem._pickEvents![i][0] && pickItem._creationTime == UserItem._pickEvents![i][1]{
                    index = i
                    print("item with matching hash found at index [" + String(index!) + "]")
                }
                
                i += 1
                print("at loop itr #" + String(i))
                
            }
            
            if index != nil {
                
                UserItem._pickEvents![index!] = [pickItem._userId!, pickItem._creationTime!, "0"]
                print("item at index [" + String(index!) + "] was replaced")
                
            }
                
            else {
                UserItem._pickEvents!.append([pickItem._userId!, pickItem._creationTime!, "0"])
                print("new item was appended")
            }
        }
        
        else {
            print("list is empty")
            UserItem._pickEvents = [[pickItem._userId!, pickItem._creationTime!, "0"]]
        }
        
        if UserItem._role == nil {
            UserItem._role = "Volunteer"
        }
        
        //Save a new item
        dynamoDbObjectMapper.save(UserItem, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
        //removeSignUpForPickEvent(pickItem: pickItem, userId: userId)
    }
    
    /// removes a pick event from the user's personal database entry
    ///
    /// - Parameters:
    ///   - pickItem: the PickEvent that the user is signed up for that they are to be removed from
    ///   - userId: the userID of the user
    func removeSignUpForPickEvent (pickItem: PickEvents, userId: String) {
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> removeSignUpForPickEvent...")
        //let ret: Int = 1
        //var queryComplete = false
        
        let UserItem: Users = queryUserInfo(userId: userId)!
        
        if UserItem._pickEvents != nil {
            //UserItem._pickEvents!.append((pickItem, "0"))
            print("There are existing events in the list")
            //check if pick event exists in the array
            
            let count = UserItem._pickEvents!.count
            var index: Int?
            var i: Int = 0
            
            while index == nil || count != i {
                
                if pickItem._userId == UserItem._pickEvents![i][0] && pickItem._creationTime == UserItem._pickEvents![i][1]{
                    index = i
                    print("item with matching hash found at index [" + String(index!) + "]")
                }
                
                i += 1
                print("at loop itr #" + String(i))
                
            }
            
            if index != nil {
                UserItem._pickEvents!.remove(at: index!)
                print("item at index [" + String(index!) + "] was removed")
                
                if UserItem._pickEvents!.count == 0 {
                    UserItem._pickEvents = nil
                }
                
            }
                
            else {
                print("user is not signed up for passed PickEvent")
            }
        }
            
        else {
            print("user is not signed up for any PickEvent")
        }
        
        if UserItem._role == nil {
            UserItem._role = "Volunteer"
        }
        
        //Save a new item
        dynamoDbObjectMapper.save(UserItem, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
        
    }

    
   
    //MARK: Team Methods
    func getUsername() -> String? {
        //to check if user is logged in with Cognito... not sure if this is necessary
        let identityManager = AWSIdentityManager.default()
        let identityProvider = identityManager.credentialsProvider.identityProvider.identityProviderName
        
        if identityProvider == "cognito-identity.amazonaws.com" {
            
            let serviceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: nil)
            let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "7bgr1sfh851ajh0v3t65hq69q3", clientSecret: "9bllitmncjkeb9nnnvb4ei0e6vod746e7pa83hqm39nsvssqh05", poolId: "us-east-1_LXKwVfwkz")
            AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "vancouverfruittreepr_userpool_MOBILEHUB_79870386")
            let pool = AWSCognitoIdentityUserPool(forKey: "vancouverfruittreepr_userpool_MOBILEHUB_79870386")
            
            if let username = pool.currentUser()?.username {
                print("Username Retrieved Successfully: \(username)")
                return username
            } else {
                print("Error getting username from current user - attempt to get user")
                let user = pool.getUser()
        
                let username = user.username
                return username
            }
            
           
            
            

        }
        return nil
    }
    func getEmail() -> String? {
        let identityManager = AWSIdentityManager.default()
        let identityProvider = identityManager.credentialsProvider.identityProvider.identityProviderName
        var responseEmail: String?
        if identityProvider == "cognito-identity.amazonaws.com" {
            
            let serviceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: nil)
            let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "7bgr1sfh851ajh0v3t65hq69q3", clientSecret: "9bllitmncjkeb9nnnvb4ei0e6vod746e7pa83hqm39nsvssqh05", poolId: "us-east-1_LXKwVfwkz")
            AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "vancouverfruittreepr_userpool_MOBILEHUB_79870386")
            let pool = AWSCognitoIdentityUserPool(forKey: "vancouverfruittreepr_userpool_MOBILEHUB_79870386")
            if let userFromPool = pool.currentUser() {
                userFromPool.getDetails().continueOnSuccessWith(block: { (task) -> Any? in
                    DispatchQueue.main.async {
                        
                        if let error = task.error as NSError? {
                            print("Error getting user attributes from Cognito: \(error)")
                        } else {
                            let response = task.result
                            if let userAttributes = response?.userAttributes {
                                print("user attributes found: \(userAttributes)")
                                for attribute in userAttributes {
                                    if attribute.name == "email" {
                                        if let email = attribute.value
                                        {
                                            responseEmail = email
                                        }
                                         else{ print("Email is null")
                                           
                                        }
                                            
                                        
                                        
                                    }
                                } } } } } )
             
            }
    }
        return responseEmail
    }
    func createTeam(teamItem: Team, pickItem: PickEvents ){
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> createPickEvent...")
        // Create data object using data models you downloaded from Mobile Hub
        
        teamItem._teamLeader = "test"
        teamItem._members = ["one" : ["two" : "three"] ]
        teamItem._pickEventHashKey = pickItem._userId
        teamItem._pickEventRangeKey = pickItem._creationTime
        teamItem._teamNumber = "1"
        
        //Save a new item
        dynamoDbObjectMapper.save(teamItem, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
        //let request = AWSCognitoIdentityProvider()
        
        //request.List
        
        //AWSCognitoIdentityProvider.adminAddUser(<#T##AWSCognitoIdentityProvider#>)
        
    }
    
    //MARK: PickEvent Methods
    
    //MARK: create pick event (V1)
    /// Creates and uploads a new pick event to the database
    ///
    /// - Parameters:
    ///   - eventTime: the scheduled time for the event, in 24HR format. Format: "HH/MM/SS". **MUST USE** leading 0s for correct query evaluation. Example: "12:30:05" ; "05:05:30"
    ///   - eventDate: the scheduled date for the event, in YYYY/MM/DD format. **MUST USE** leading 0s for correct query evaluation. Example: "2018/06/03"
    ///   - latitude: the latitude for the location of the event
    ///   - longitude: the longitude for the location of the event
    ///   - teamID: the ID string for the team assigned to the pickEvent
    func createPickEvents(eventTime: String, eventDate: String, latitude: NSNumber, longitude: NSNumber, teamID: String, address: String, treeMap: [String:String]){
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> createPickEvent...")
        // Create data object using data models you downloaded from Mobile Hub
        let pickEventItem: PickEvents = PickEvents()
        let userID = AWSIdentityManager.default().identityId
        pickEventItem._userId = userID
        
        //get time
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        /*  ._creationTime stores a combination of the date and time as
            the sorting hash to guarantee the uniqueness of the primary
            hash
        */
        pickEventItem._creationTime = String(year) + "/" + String(month) + "/" + String(day) + "-" + String(hour) + ":" + String(minutes) + ":" + String(seconds)

        //this isn't a necessary attribute
        pickEventItem._creationDate = String(year) + "/" + String(month) + "/" + String(day)
        
        pickEventItem._eventTime = eventTime
        pickEventItem._eventDate = eventDate
        
        pickEventItem._assignedTeamID = teamID
        
        pickEventItem._latitude = latitude
        pickEventItem._longitude = longitude
        pickEventItem._address = address
        pickEventItem._treeMap = treeMap
        
        //Save a new item
        dynamoDbObjectMapper.save(pickEventItem, completionHandler: {
            (error: Error?) -> Void in

            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
        //let request = AWSCognitoIdentityProvider()
        
        //request.List
        
        //AWSCognitoIdentityProvider.adminAddUser(<#T##AWSCognitoIdentityProvider#>)
    
    }
    
    
    // MARK: create pick event (V2) - same as V1, except strips attributes from
    ///Creates and uploads a new pick event to the database
    ///
    /// - Parameter pickEventItem: event that is to be uploaded, with all relevant parameters except for creationTime, which is set in this function
    func createPickEvents(pickEventItem: PickEvents){
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> createPickEvent...")
        // Create data object using data models you downloaded from Mobile Hub
        
        pickEventItem._userId = AWSIdentityManager.default().identityId
        
        //get time
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        /*  ._creationTime stores a combination of the date and time as
         the sorting hash to guarantee the uniqueness of the primary
         hash
         */
        pickEventItem._creationTime = String(year) + "/" + String(month) + "/" + String(day) + "-" + String(hour) + ":" + String(minutes) + ":" + String(seconds)
        
        //this isn't really a necessary attribute, since creationTime stores both anyway
        pickEventItem._creationDate = String(year) + "/" + String(month) + "/" + String(day)
        
        //Save a new item
        dynamoDbObjectMapper.save(pickEventItem, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was saved.")
        })
        
    }
    
    // MARK: create pick event (V3) - uses primary hash
    ///Call this when wanting to push changes to the database on an existing event
    ///
    /// - Parameter pickEventItem: event that is to be uploaded, with modified attributes, but with _userId and creationTime unmodified
    func modifyPickEventsWithHash(pickEventItem: PickEvents){
        
        let dynamoDbObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> modifyPickEvent...")

        //re-save a new item
        dynamoDbObjectMapper.save(pickEventItem, completionHandler: {
            (error: Error?) -> Void in
            
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("An item was overwritten.")
        })
        
    }
    
    //MARK: Search for pickEvents by date and time
    /// Queries pick events by date and time using FindPick index.
    /// Returns all pick events that are **on** the date AND at or before the time.
    ///
    /// - Parameters:
    ///   - date: Search criteria for Pick Event, format: "YYYY/MM/DD"
    ///             **NOTE** Do not use leading 0s
    ///             **Example** "1970/1/1"
    ///   - time: Search criteria for Pick Event in 24HR format, format: "HH:MM:SS"
    ///             **NOTE** Do not use leading 0s
    /// - Returns: [PickEvents]
    func queryPickEventsByDate(date: String, time: String?) -> [PickEvents] {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        print("in DatabaseInterface -> queryPickEventsByDate")
        var pickArray: [PickEvents] = []
        var queryComplete = false
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = "FindPick"
        queryExpression.keyConditionExpression = "#eventDate = :eventDate AND #eventTime <= :eventTime";
        queryExpression.expressionAttributeNames = ["#eventDate": "eventDate", "#eventTime": "eventTime"]
        queryExpression.expressionAttributeValues = [":eventDate": date, ":eventTime": time!]
        
        dynamoDBObjectMapper.query(PickEvents.self, expression: queryExpression)
        { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            
            if output != nil {
                for pick in output!.items {
                    let pickItem = pick as? PickEvents
                    //print("\(pickItem!._eventDate!)")
                    pickArray.append(pickItem!)

                }
            }
            
            //print("After appeding inside of function: ", pickArray.count)
            queryComplete = true;
        }
        
        while queryComplete == false {
            if queryComplete == true{
                print("query is finished")
                queryComplete = false
                return pickArray
            }
        }
        
        return pickArray
        //print("count outside of inside function:", self._pickArray.count)
        //return self._pickArray
    }
    
    //MARK: Scan table based on date range
    /// Scans the whole table and returns all items that are equal to or earlier than the maxDate parameter
    ///
    /// - Parameters:
    ///   - itemLimit: max number of items returned in the [PickEvents] array
    ///   - maxDate: upper limit date range; **MUST** have leading 0s, be in format YYYY/MM/DD or else string evaluation will be wrong
    /// - Returns: array of PickEvents objects that match scan parameters
    func scanPickEvents(itemLimit: NSNumber, maxDate: String) -> [PickEvents]{
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        let scanExpression = AWSDynamoDBScanExpression()
        var pickArray: [PickEvents] = []
        var queryComplete = false
        
        scanExpression.limit = itemLimit
        scanExpression.indexName = "FindPick"
        scanExpression.filterExpression = "eventDate <= :maxDate"
        //scanExpression.expressionAttributeNames =
        scanExpression.expressionAttributeValues = [":maxDate" : maxDate]
        
        dynamoDBObjectMapper.scan(PickEvents.self, expression: scanExpression)  { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
            if error != nil {
                print("The request failed. Error: \(String(describing: error))")
            }
            
            if output != nil {
                for pick in output!.items {
                    let pickItem = pick as? PickEvents
                    //print("\(pickItem!._eventDate!)")
                    pickArray.append(pickItem!)
                }
            }
            queryComplete = true;
        }
        
        while queryComplete == false {
            if queryComplete == true{
                print("query is finished")
                queryComplete = false
                return pickArray
            }
        }
        
        return pickArray
        

    }
    
    //MARK: Query database for a specific pickEvent using hash criteria
    /// Query database for a specific pickEvent using hash criteria - userId and creationTime
    ///
    /// - Parameters:
    ///   - userId: the userId parameter of the PickEvents object
    ///   - creationTime: the creationTime parameter of the PickEvents object
    /// - Returns: an optional PickEvents? object; if the object is nil, then nothing was found for the submitted criterion or the query timed out
    func readPickEvent(userId: String, creationTime: String) -> PickEvents? {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        var received: PickEvents?
        var queryComplete = false
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId AND #creationTime = :creationTime";
        queryExpression.expressionAttributeNames = ["#userId": "userId", "#creationTime": "creationTime"]
        queryExpression.expressionAttributeValues = [":userId": userId, ":creationTime": creationTime]
        
        let currentUserID = AWSIdentityManager.default().identityId
        
        if currentUserID != userId{
            print("Error: User ID of current user and creator do not match, read denied")
        }
        
        else {
            dynamoDBObjectMapper.query(PickEvents.self, expression: queryExpression)
            { (output: AWSDynamoDBPaginatedOutput?, error: Error?) in
                if error != nil {
                    print("The request failed. Error: \(String(describing: error))")
                }
                
                if output != nil {
                    for pick in output!.items {
                        let pickItem = pick as? PickEvents
                        //print("\(pickItem!._eventDate!)")
                        received = pickItem
                    }
                }
                
                queryComplete = true;
            }
        
            //waits for query to complete before returning
            while queryComplete == false {
                if queryComplete == true{
                    print("query is finished")
                    queryComplete = false
                    return received //received! != nil
                }
            }
        }
        return received //so Xcode stops complaining
    }
    
    //MARK: Delete individual Pick Event
    /// removes a pick event from the database
    ///
    /// - Parameter PickEvents: the PickEvents object that is to be removed from the table
    /// - Returns: 1 for success, 0 for failure
    
    func deletePickEvent(itemToDelete: PickEvents) -> Int {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        var ret: Int = 1
        var queryComplete = false
        
        dynamoDBObjectMapper.remove(itemToDelete, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print(" Amazon DynamoDB Save Error: \(error)")
                ret = 0
                return
            }
            print("An item was deleted.")
            ret = 1
            queryComplete = true
        })
        
        while queryComplete == false {
            if queryComplete == true{
                print("query is finished")
                queryComplete = false
                return ret
            }
        }
        
        return ret
        
    }
    
}


/*
 Previous test cases from ViewController:
 
 TestDBScan
 let DBInterface = DatabaseInterface()
 
 let pickArray = DBInterface.scanPickEvents(itemLimit: 20, maxDate: "2018/07/01")
 
 print(pickArray.count)
 for x in pickArray {
 print(x._eventDate!)
 }
 
 TestDBQueryAndDelete
 let DBInterface = DatabaseInterface()
 let userID = AWSIdentityManager.default().identityId!
 print("User #: " + userID)
 
 let pick = DBInterface.readPickEvent(userId: userID , creationTime: "2018/7/1-14:58:33")
 var unwrappedPick: PickEvents
 if pick != nil{
 unwrappedPick = pick!
 print("userID: " + unwrappedPick._userId!)
 print("creationTime: " + unwrappedPick._creationTime!)
 
 }
 
 let result = DBInterface.deletePickEvent(itemToDelete: pick!)
 
 print("Result of delete: " + String(result))
 
 
 TestDBUpload
 let DBInterface = DatabaseInterface();
 
 DBInterface.createPickEvents(eventTime: "16:45", eventDate:"2018/07/01" , latitude: 4000, longitude: 2000, teamID: "2");
 
 let d1 = "2018/07/29"
 let d2 = "2018/12/02"
 let result  = d1 > d2
 print("Evaluation of " + String(d1) + " > "  + String(d2) + " :" + String(result) )
 
 TestDBFetch
 let DBInterface = DatabaseInterface()
 let userID = AWSIdentityManager.default().identityId!
 print("User #: " + userID)
 
 let pick = DBInterface.readPickEvent(userId: userID , creationTime: "2018/7/1-14:58:33")
 
 if pick != nil{
 let unwrappedPick = pick!
 print("userID: " + unwrappedPick._userId!)
 print("creationTime: " + unwrappedPick._creationTime!)
 
 }
 
 
 

 
*/










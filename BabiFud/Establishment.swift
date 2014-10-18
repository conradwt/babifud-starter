
/*
* Copyright (c) 2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import Foundation
import CloudKit
import MapKit

struct ChangingTableLocation : RawOptionSetType, BooleanType {
  var rawValue: UInt = 0
  var boolValue:Bool {
    get {
      return self.rawValue != 0
    }
  }
  
  init(rawValue: UInt) {
    self.rawValue = rawValue
  }
  
  init(_ rawValue: UInt) {
    self.init(rawValue: rawValue)
  }
  
  init(nilLiteral: ()) {
    self.rawValue = 0
  }
  
  func toRaw() -> UInt { return self.rawValue }
  static func convertFromNilLiteral() -> ChangingTableLocation { return .None }
  static func fromRaw(raw: UInt) -> ChangingTableLocation? { return self(raw) }
  static func fromMask(raw: UInt) -> ChangingTableLocation { return self(raw) }
  static var allZeros: ChangingTableLocation { return self(0) }
  
  static var None: ChangingTableLocation   { return self(0) }      //0
  static var Mens: ChangingTableLocation   { return self(1 << 0) } //1
  static var Womens: ChangingTableLocation { return self(1 << 1) } //2
  static var Family: ChangingTableLocation { return self(1 << 2) } //4
  
  func images() -> [UIImage] {
    var images = [UIImage]()
    if self & .Mens {
      images.append(UIImage(named: "man")!)
    }
    if self & .Womens {
      images.append(UIImage(named: "woman")!)
    }
    
    return images
  }
}

func == (lhs: ChangingTableLocation, rhs: ChangingTableLocation) -> Bool     { return lhs.rawValue == rhs.rawValue }
func | (lhs: ChangingTableLocation, rhs: ChangingTableLocation) -> ChangingTableLocation { return ChangingTableLocation(lhs.rawValue | rhs.rawValue) }
func & (lhs: ChangingTableLocation, rhs: ChangingTableLocation) -> ChangingTableLocation { return ChangingTableLocation(lhs.rawValue & rhs.rawValue) }
func ^ (lhs: ChangingTableLocation, rhs: ChangingTableLocation) -> ChangingTableLocation { return ChangingTableLocation(lhs.rawValue ^ rhs.rawValue) }

struct SeatingType : RawOptionSetType, BooleanType {
  var rawValue: UInt = 0
  var boolValue:Bool {
    get {
      return self.rawValue != 0
    }
  }
  
  init(rawValue: UInt) {
    self.rawValue = rawValue
  }
  
  init(_ rawValue: UInt) {
    self.init(rawValue: rawValue)
  }
  
  init(nilLiteral: ()) {
    self.rawValue = 0
  }
  
  
  func toRaw() -> UInt { return self.rawValue }
  static func convertFromNilLiteral() -> SeatingType { return .None}
  static func fromRaw(raw: UInt) -> SeatingType? { return self(raw) }
  static func fromMask(raw: UInt) -> SeatingType { return self(raw) }
  static var allZeros: SeatingType { return self(rawValue: 0) }
  
  static var None:    SeatingType   { return self(rawValue: 0) }      //0
  static var Booster: SeatingType   { return self(rawValue: 1 << 0) } //1
  static var HighChair: SeatingType { return self(rawValue: 1 << 1) } //2
  
  func images() -> [UIImage] {
    var images = [UIImage]()
    if self & .Booster {
      images.append(UIImage(named: "booster")!)
    }
    if self & .HighChair {
      images.append(UIImage(named: "highchair")!)
    }
    
    return images
  }
}

func == (lhs: SeatingType, rhs: SeatingType) -> Bool     { return lhs.rawValue == rhs.rawValue }
func | (lhs: SeatingType, rhs: SeatingType) -> SeatingType { return SeatingType(lhs.rawValue | rhs.rawValue) }
func & (lhs: SeatingType, rhs: SeatingType) -> SeatingType { return SeatingType(lhs.rawValue & rhs.rawValue) }
func ^ (lhs: SeatingType, rhs: SeatingType) -> SeatingType { return SeatingType(lhs.rawValue ^ rhs.rawValue) }

class Establishment : NSObject, MKAnnotation {
  
  var record : CKRecord!
  var name : String!
  var location : CLLocation!
  weak var database : CKDatabase!
  
  var assetCount = 0
  
  var healthyChoice : Bool {
    get {
      return record.objectForKey("HealthyOption").boolValue
    }
  }
  
  var kidsMenu: Bool {
    get {
      return record.objectForKey("KidsMenu").boolValue
    }
  }
  
  init(record : CKRecord, database: CKDatabase) {
    self.record = record
    self.database = database
    
    self.name = record.objectForKey("Name") as String!
    self.location = record.objectForKey("Location") as CLLocation!
  }
  
  func fetchRating(completion: (rating: Double, isUser: Bool) -> ()) {
    Model.sharedInstance().userInfo.userID() { userRecord, error in
      self.fetchRating(userRecord, completion: completion)
    }
  }
  
  func fetchRating(userRecord: CKRecordID!, completion: (rating: Double, isUser: Bool) -> ()) {
    //REPLACE THIS STUB
    completion(rating: 0, isUser: false)
  }
  
  func fetchNote(completion: (note: String!) -> ()) {
    Model.sharedInstance().fetchNote(self) { note, error in
      completion(note: note)
    }
  }
  
  func fetchPhotos(completion:(assets: [CKRecord]!)->()) {
    let predicate = NSPredicate(format: "Establishment == %@", record)
    let query = CKQuery(recordType: "EstablishmentPhoto", predicate: predicate);
    //Intermediate Extension Point - with cursors
    database.performQuery(query, inZoneWithID: nil) { results, error in
      if error == nil {
        self.assetCount = results.count
      }
      completion(assets: results as [CKRecord]!)
    }
  }
  
  func changingTable() -> ChangingTableLocation {
    let changingTable = record?.objectForKey("ChangingTable") as NSNumber!
    var val:UInt = 0;
    if let changingTableNum = changingTable {
      val = changingTableNum.unsignedLongValue
    }
    return ChangingTableLocation(rawValue: val)
  }
  
  func seatingType() -> SeatingType {
    let seatingType = record?.objectForKey("SeatingType") as NSNumber!
    var val:UInt = 0;
    if let seatingTypeNum = seatingType {
      val = seatingTypeNum.unsignedLongValue
    }
    return SeatingType(rawValue: val)
  }
  
  func loadCoverPhoto(completion:(photo: UIImage!) -> ()) {
    // 1
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ) ) {
      var image: UIImage!
      // 2
      let coverPhoto = self.record.objectForKey("CoverPhoto") as CKAsset!
      if let asset = coverPhoto {
        // 3
        if let url = asset.fileURL {
          let imageData = NSData(contentsOfFile: url.path!)
          // 4
          image = UIImage(data: imageData!)
        }
      }
      // 5
      completion(photo: image)
    }
  }
  
  //MARK: - map annotation
  
  var coordinate : CLLocationCoordinate2D {
    get {
      return location.coordinate
    }
  }
  var title : String! {
    get {
      return name
    }
  }
  
  
}
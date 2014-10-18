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

import UIKit
import CoreLocation

class MasterViewController: UITableViewController, ModelDelegate, CLLocationManagerDelegate {
  
  var detailViewController: DetailViewController? = nil
  var locationManager: CLLocationManager!
  
   let model: Model = Model.sharedInstance()
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      self.clearsSelectionOnViewWillAppear = false
      self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = controllers[controllers.endIndex-1].topViewController as? DetailViewController
    }
    
    setupLocationManager()
    
    model.delegate = self;
    model.delegate = self;
    model.refresh()

    //setup a refresh control
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(model, action: "refresh", forControlEvents: .ValueChanged)
  }
  
  // #pragma mark - Segues
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      let indexPath = self.tableView.indexPathForSelectedRow()!
      let object = Model.sharedInstance().items[indexPath.row]
      ((segue.destinationViewController as UINavigationController).topViewController as DetailViewController).detailItem = object
    }
  }
  
  // #pragma mark - Table View
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Model.sharedInstance().items.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as EstablishmentCell
    
    let object = Model.sharedInstance().items[indexPath.row]
    cell.titleLabel.text = object.name

    object.fetchRating { (rating: Double, isUser: Bool) in
      dispatch_async(dispatch_get_main_queue()) {
        cell.starRating.rating = Float(rating)
        cell.starRating.emptyColor = isUser ? UIColor.yellowColor() : UIColor.whiteColor()
        cell.starRating.solidColor = isUser ? UIColor.yellowColor() : UIColor.whiteColor()
      }
    }
    
    var badges = NSMutableArray()
    badges.addObjectsFromArray(object.changingTable().images())
    badges.addObjectsFromArray(object.seatingType().images())
    cell.badgeView.setBadges(badges)
    
    object.loadCoverPhoto { image in
      dispatch_async(dispatch_get_main_queue()) {
        cell.coverPhotoView.image = image
      }
    }

    return cell
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      let object = Model.sharedInstance().items[indexPath.row]
      self.detailViewController!.detailItem = object
    }
  }
  
  //#pragma mark model delegate
  
  func modelUpdated() {
    refreshControl?.endRefreshing()
    tableView.reloadData()
  }
  
  func errorUpdating(error: NSError) {
    let message = error.localizedDescription
    let alert = UIAlertView(title: "Error Loading Establishments",
      message: message, delegate: nil, cancelButtonTitle: "OK")
    alert.show()
  }
  
  //#pragma mark location stuff & delegate
  
  func setupLocationManager() {
    locationManager = CLLocationManager()
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager.distanceFilter = 500.0 //0.5km
    locationManager.delegate = self
    
    CLLocationManager.authorizationStatus()
  }
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)  {
    switch status {
    case .NotDetermined:
      manager.requestWhenInUseAuthorization()
    case .AuthorizedWhenInUse:
      manager.startUpdatingLocation()
    default:
      //do nothing
      println("Other status")
    }
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    if let loc = locations?.last as? CLLocation {
      model.fetchEstablishments(loc, radiusInMeters: 3000)
    }
  }
}


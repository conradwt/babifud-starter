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
import UIWidgets
import CloudKit

class DetailViewController: UITableViewController, UISplitViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  var masterPopoverController: UIPopoverController? = nil
  
  
  @IBOutlet var coverView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var starRating: StarRatingControl!
  @IBOutlet var kidsMenuButton: CheckedButton!
  @IBOutlet var healthyChoiceButton: CheckedButton!
  @IBOutlet var womensRoomButton: UIButton!
  @IBOutlet var mensRoomButton: UIButton!
  @IBOutlet var boosterButton: UIButton!
  @IBOutlet var highchairButton: UIButton!
  @IBOutlet var addPhotoButton: UIButton!
  @IBOutlet var photoScrollView: UIScrollView!
  @IBOutlet var noteTextView: UITextView!
  
  var detailItem: Establishment! {
  didSet {
    if self.masterPopoverController != nil {
      self.masterPopoverController!.dismissPopoverAnimated(true)
    }
  }
  }
  
  func configureView() {
    // Update the user interface for the detail item.
    if let detail: Establishment = self.detailItem {
      title = detail.name
      detail.loadCoverPhoto() { image in
        dispatch_async(dispatch_get_main_queue()) {
          self.coverView.image = image
        }
      }

      titleLabel.text = detail.name

      starRating.maxRating = 5
      starRating.enabled = false
      Model.sharedInstance().userInfo.loggedInToICloud() {
        accountStatus, error in
        let enabled = accountStatus == .Available || accountStatus == .CouldNotDetermine
        self.starRating.enabled = enabled
        self.healthyChoiceButton.enabled = enabled
        self.kidsMenuButton.enabled = enabled
        self.mensRoomButton.enabled = enabled
        self.womensRoomButton.enabled = enabled
        self.boosterButton.enabled = enabled
        self.highchairButton.enabled = enabled
        self.addPhotoButton.enabled = enabled
      }
      self.kidsMenuButton.checked = detailItem.kidsMenu
      self.healthyChoiceButton.checked = detailItem.healthyChoice
      self.womensRoomButton.selected = (detailItem.changingTable() & ChangingTableLocation.Womens).boolValue
      self.mensRoomButton.selected = (detailItem.changingTable() & ChangingTableLocation.Mens).boolValue
      self.highchairButton.selected = (detailItem.seatingType() & SeatingType.HighChair).boolValue
      self.boosterButton.selected = (detailItem.seatingType() & SeatingType.Booster).boolValue
      
      detail.fetchRating() { rating, isUser in
        dispatch_async(dispatch_get_main_queue()) {
          self.starRating.maxRating = 5
          self.starRating.rating = Float(rating)
          self.starRating.setNeedsDisplay()
          
          self.starRating.emptyColor = isUser ? UIColor.yellowColor() : UIColor.whiteColor()
          self.starRating.solidColor = isUser ? UIColor.yellowColor() : UIColor.whiteColor()
        }
      }
      
      detail.fetchPhotos() { assets in
        if assets != nil {
          var x = 10
          for record in assets {
            if let asset = record.objectForKey("Photo") as? CKAsset {
              let image: UIImage? = UIImage(contentsOfFile: asset.fileURL.path!)
              if image != nil {
                let imView = UIImageView(image: image)
                imView.frame = CGRect(x: x, y: 0, width: 60, height: 60)
                imView.clipsToBounds = true
                imView.layer.cornerRadius = 8
                x += 70
                
                imView.layer.borderWidth = 0.0
                
                //if the user has discovered the photo poster, color the photo with a green border
                if let photoUserRef = record.objectForKey("User") as? CKReference {
                  let photoUserId = photoUserRef.recordID
                  let contactList = Model.sharedInstance().userInfo.contacts
                  let contacts = contactList.filter {$0.userRecordID == photoUserId}
                  if contacts.count > 0 {
                    imView.layer.borderWidth = 1.0
                    imView.layer.borderColor = UIColor.greenColor().CGColor
                  }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                  self.photoScrollView.addSubview(imView)
                }
              }
            }
          }
        }
      }
      
      detail.fetchNote() { note in
        println("note \(note)")
        if let noteText = note {
          dispatch_async(dispatch_get_main_queue()) {
            self.noteTextView.text = noteText
          }
        }
      }
    }
  }
  
  func saveRating(rating: NSNumber) {
    //replace this stub method
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    coverView.clipsToBounds = true
    coverView.layer.cornerRadius = 10.0
   
    //add star rating block here
  }
  
  override func viewWillAppear(animated: Bool)  {
    super.viewWillAppear(animated)
    configureView()
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    if segue.identifier == "EditNote" {
      let noteController = segue.destinationViewController as NotesViewController
      noteController.establishment = self.detailItem
    }
  }
  
  // #pragma mark - Split view
  
  func splitViewController(splitController: UISplitViewController, willHideViewController viewController: UIViewController, withBarButtonItem barButtonItem: UIBarButtonItem, forPopoverController popoverController: UIPopoverController) {
    barButtonItem.title = NSLocalizedString("Places", comment: "Places")
    self.navigationItem.setLeftBarButtonItem(barButtonItem, animated: true)
    self.masterPopoverController = popoverController
  }
  
  func splitViewController(splitController: UISplitViewController, willShowViewController viewController: UIViewController, invalidatingBarButtonItem barButtonItem: UIBarButtonItem) {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    self.navigationItem.setLeftBarButtonItem(nil, animated: true)
    self.masterPopoverController = nil
  }
  func splitViewController(splitController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
    return true
  }
  
  // #pragma mark - Image Picking
  
  @IBAction func addPhoto(sender: AnyObject) {
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.sourceType = .SavedPhotosAlbum
    self.presentViewController(imagePicker, animated: true, completion: nil)
  }
  
  func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
    dismissViewControllerAnimated(true, completion: nil)
    if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
        self.addPhotoToEstablishment(selectedImage)
      }
    }
  }

  func generateFileURL() -> NSURL {
    let fileManager = NSFileManager.defaultManager()
    let fileArray: NSArray = fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
    let fileURL = fileArray.lastObject?.URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension("jpg")
    
    if let filePath = fileArray.lastObject?.path {
      if !fileManager.fileExistsAtPath(filePath!) {
        fileManager.createDirectoryAtPath(filePath!, withIntermediateDirectories: true, attributes: nil, error: nil)
      }
    }

    return fileURL!
  }
  
  func addNewPhotoToScrollView(photo:UIImage) {
    let newImView = UIImageView(image: photo)
    let offset = Double(self.detailItem.assetCount) * 70.0 + 10.0
    var frame: CGRect = CGRect(x: offset, y: 0, width: 60, height: 60)
    newImView.frame = frame
    newImView.clipsToBounds = true
    newImView.layer.cornerRadius = 8
    dispatch_async(dispatch_get_main_queue()) {
      self.photoScrollView.addSubview(newImView)
      self.photoScrollView.contentSize = CGSize(width: CGRectGetMaxX(frame), height: CGRectGetHeight(frame));
    }
  }
  
  func addPhotoToEstablishment(photo: UIImage) {
    //replace this stub
  }
  
}



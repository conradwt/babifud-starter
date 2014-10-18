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
import CloudKit

class NotesCell : UITableViewCell {
  @IBOutlet var thumbImageView: UIImageView! {
  didSet {
    thumbImageView.clipsToBounds = true
    thumbImageView.layer.cornerRadius = 6
   }
  }
  
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var notesLabel: UILabel!
  
}

class NotesTableViewController: UITableViewController {
  
  var notes : NSArray! = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    Model.sharedInstance().fetchNotes { (notes : NSArray!, error : NSError!) in
      if error == nil {
        self.notes = notes;
        dispatch_async(dispatch_get_main_queue()) {
          self.tableView.reloadData()
        }
      }
    }
  }
  
  // #pragma mark - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return notes.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) as NotesCell
    
    let record:CKRecord = notes[indexPath.row] as CKRecord
    cell.notesLabel.text = record.objectForKey("Note") as? String
    
    let establishmentRef = record.objectForKey("Establishment") as CKReference
    if let establishment = Model.sharedInstance().establishment(establishmentRef) {
      cell.titleLabel.text = establishment.name
      establishment.loadCoverPhoto() { photo in
        dispatch_async(dispatch_get_main_queue()) {
          cell.thumbImageView.image = photo
        }
      }
    } else {
      cell.thumbImageView.image = nil;
      cell.titleLabel.text = "???"
    }

    return cell
  }
  
}

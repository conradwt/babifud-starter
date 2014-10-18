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

class SettingsViewController: UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Settings"
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    updateLogin()
  }
  
  func updateLogin() {
    let ip = NSIndexPath(forRow: 0, inSection: 0)
    let cell = self.tableView.cellForRowAtIndexPath(ip)! as UITableViewCell
    
    Model.sharedInstance().userInfo.loggedInToICloud { //1
      accountStatus, error in
      var text  = "Not logged in to iCloud" //2
    
      if accountStatus == .Available { //3
        text = "Logged in to iCloud"
        Model.sharedInstance().userInfo.userInfo() { //4
          userInfo, error in
      
          if userInfo != nil {
            dispatch_async(dispatch_get_main_queue()) {
              let nameText = "Logged in as \(userInfo.firstName) \(userInfo.lastName)" //5
              cell.textLabel.text = nameText
            }
          }
        }
      }
      
      dispatch_async(dispatch_get_main_queue()) {
        cell.textLabel.text = text
        let enableSwitch = accountStatus == .Available //6
        self.tableView.reloadData()
      }
    }
  }

}

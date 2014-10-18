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

class NotesViewController: UIViewController {

  @IBOutlet var textView: UITextView!
  var establishment : Establishment!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillShowNotification, object: nil)
  }
  
  
  func keyboardWillShow(note: NSNotification){
    let userInfo : NSDictionary = note.userInfo!
    let keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue!
    let keyboardFrame = keyboardFrameValue.CGRectValue() as CGRect
    var contentInsets = textView.contentInset
    contentInsets.bottom = keyboardFrame.height
    
    textView.contentInset = contentInsets
    textView.scrollIndicatorInsets = contentInsets
  }
  
  func keyboardWillHide(note: NSNotification){
    var contentInsets = textView.contentInset
    contentInsets.bottom = 0.0
    textView.contentInset = contentInsets
    textView.scrollIndicatorInsets = contentInsets
  }

  @IBAction func save(sender: AnyObject) {
    let noteText = textView.text
    Model.sharedInstance().addNote(noteText, establishment: establishment) {
      error in
      if error != nil {
        UIAlertView(title: "Error saving note",
          message: error.localizedDescription,
          delegate: nil,
          cancelButtonTitle: "OK").show()
      } else {
        let viewControllers = self.navigationController?.viewControllers
        let detailController = viewControllers![0] as DetailViewController
        detailController.noteTextView.text = noteText
        self.navigationController?.popViewControllerAnimated(true)
      }
    }
  }
}

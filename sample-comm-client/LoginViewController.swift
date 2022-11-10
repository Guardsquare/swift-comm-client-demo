//
//  ViewController.swift
//  sample-comm-client
//
//  Created by Anton Baranenko on 01/06/2022.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class LoginViewController: UIViewController {
    let db = Firestore.firestore()
    var user_id: String?
    var user: UserInfo?
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: UIBarButtonItem.Style.done, target: self, action: #selector(loginClick))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginSuccessful" {
            let destination = segue.destination as! ThreadTableViewController
            destination.user_id = self.user_id
            destination.user = self.user
        }
    }
    
    @IBAction func aliceClick(_ sender: Any) {
        self.userNameField.text = "alice-test@guardsquare.com"
        self.passwordField.text = "123456"
        self.loginClick()
    }
    
    @IBAction func bobClick(_ sender: Any) {
        self.userNameField.text = "bob-test@guardsquare.com"
        self.passwordField.text = "123456"
        self.loginClick()
    }
    
    @IBAction func loginClick() {
        Auth.auth().signIn(withEmail: self.userNameField!.text ?? "", password: self.passwordField!.text ?? "") { [weak self] authResult, error in
          guard let strongSelf = self else { return }
            if error != nil {
                // Show error message
                let alert = UIAlertController(title: "Could not log in", message: "We could not log you in, please check your connection and password", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                strongSelf.present(alert, animated: true, completion: nil)
            }
            else {
                // Get the user detailed data
                let userRef = strongSelf.db.collection("users").document((authResult?.user.uid)!)
                
                userRef.getDocument(as: UserInfo.self) { (result) in
                    switch (result) {
                    case .success(let user):
                        strongSelf.user_id = authResult?.user.uid
                        strongSelf.user = user
                        strongSelf.performSegue(withIdentifier: "loginSuccessful", sender: strongSelf)
                    case .failure(let error):
                        let alert = UIAlertController(title: "Could not log in", message: "You are not registered in the system, please contact an administrator.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        strongSelf.present(alert, animated: true, completion: nil)
                        print(error)
                    }
                }
            }
        }
    }
    
}


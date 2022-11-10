//
//  ThreadTableViewController.swift
//  sample-comm-client
//
//  Created by Anton Baranenko on 17/06/2022.
//

import UIKit
import FirebaseFirestore

class ThreadTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    var user: UserInfo?
    var user_id: String?
    var threads: [ChatThread] = []

    @IBOutlet weak var userLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userLabel.text = "Welcome, \(self.user!.name)"
        self.threads = []
        
        db.collection("users").order(by: "name").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let t = ChatThread(user_id: document.documentID, name: document.data()["name"] as! String)
                    if document.documentID != self.user_id {
                        self.threads.append(t)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.threads.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thread = self.threads[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatThreadCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = thread.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedThread = self.threads[indexPath.row]
        
        if let viewController = storyboard?.instantiateViewController(identifier: "ChatViewController") as? ChatViewController {
            viewController.user_id = self.user_id;
            viewController.user = self.user;
            viewController.thread = selectedThread;
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

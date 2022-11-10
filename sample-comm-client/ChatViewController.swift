//
//  AuthViewController.swift
//  sample-comm-client
//
//  Created by Anton Baranenko on 03/06/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

public struct Sender: SenderType {
    public let senderId: String
    public let displayName: String
}

class ChatViewController: MessagesViewController {
    let db = Firestore.firestore()
    
    var user_id: String?
    var user: UserInfo?
    var thread: ChatThread?
    var chat_id: String?
    
    var sender_me: Sender?
    var sender_them: Sender?
    
    lazy var messages: [Message] = [
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messages = []
        
        // Do any additional setup after loading the view.
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self

        guard let user_id = self.user_id, let user = self.user, let thread = self.thread
        else { return }
        
        self.sender_me = Sender(senderId: user_id, displayName: user.name)
        self.sender_them = Sender(senderId: thread.user_id, displayName: thread.name)
        
        self.chat_id = thread.getThreadObjectId(my_user_id: user_id)
        db.collection("chats").document(self.chat_id!).setData([ "name": self.chat_id ?? "Chat" ], merge: true) {
            err in
            if err != nil {
                // Could not create the chat
                let alert = UIAlertController(title: "Could not start the chat", message: "We could not create a chat thread, please check all details and try again", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else {
                self.db.collection("chats").document(self.chat_id!).collection("thread").order(by: "date")
                    .addSnapshotListener { querySnapshot, error in
                        guard let snapshot = querySnapshot else {
                            print("Error fetching snapshots: \(error!)")
                            return
                        }
                        
                        snapshot.documentChanges.forEach { diff in
                            if (diff.type == .added) {
                                let m = Message(firebaseDocument: diff.document, sender_me: self.sender_me!, sender_them: self.sender_them!)
                                self.insertMessage(m)
                                print("New message: \(diff.document.data())")
                            }
                            if (diff.type == .modified) {
                                print("Modified message: \(diff.document.data())")
                                self.modifyMessage(diff.document)
                            }
                            if (diff.type == .removed) {
                                print("Removed message: \(diff.document.data())")
                            }
                        }
                    }

            }
        }
    }
    
    func insertMessage(_ message: Message) {
        messages.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messages.count - 1])
            if messages.count >= 2 {
                messagesCollectionView.reloadSections([messages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
        
        if message.selfDestruct {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5000), execute: {
                self.destroyMessage(message.messageId)
            })
        }
        
        if message.sender.senderId != self.user_id {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000), execute: {
                self.markAsRead(message.messageId)
            })
        }
        
        if (message.sender.senderId == self.user_id) && (self.thread?.user_id == UserInfo.bot_user_id) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000), execute: {
                switch (message.kind) {
                    case .text(let text):
                        self.botResponse(text)
                    default: break
                }
            })
        }
    }
    
    func modifyMessage(_ document: QueryDocumentSnapshot) {
        guard let index = self.messages.firstIndex(where: { document.documentID == $0.messageId }) else { return }
        self.messages[index].kind = .text(document.data()["text"] as? String ?? "")
        self.messages[index].read = document.data()["read"] as? Bool ?? false
        self.messagesCollectionView.reloadSections([index])
    }
    
    func destroyMessage(_ messageId: String) {
        db.collection("chats").document(self.chat_id!).collection("thread").document(messageId).setData([ "text": "Self-destructed" ], merge: true) {err in
            if let err = err {
                print("Could not self-destruct \(err)")
                return
            }
        }
    }
    
    func markAsRead(_ messageId: String) {
        db.collection("chats").document(self.chat_id!).collection("thread").document(messageId).setData([ "read": true ], merge: true) {err in
            if let err = err {
                print("Could not mark message as read \(err)")
                return
            }
        }
    }
    
    func botResponse(_ text: String) {
        var response: String
        
        if text.contains("secret") {
            response = "secret: test 123"
        }
        else {
            response = "Responding to " + text
        }
        
        db.collection("chats").document(self.chat_id!).collection("thread").addDocument(data: [
            "sender": UserInfo.bot_user_id,
            "date": Timestamp.init(),
            "text": response
        ])
    }
    
    func sendMessage(text: String, completion: @escaping (Error?) -> Void) {
        db.collection("chats").document(self.chat_id!).collection("thread").addDocument(data: [
            "sender": self.sender_me!.senderId,
            "date": Timestamp.init(),
            "text": text
        ]) {
            err in
            completion(err)
        }
    }
    
    func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
      avatarView.isHidden = true
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if let msg = message as? Message {
            if msg.read && self.isFromCurrentSender(message: message) {
                return CGFloat(20);
            }
        }
        return CGFloat(0);
    }
}


extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return self.sender_me!
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if let msg = message as? Message {
            if msg.read && self.isFromCurrentSender(message: message) {
                return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            }
        }
        return nil
    }
}


extension ChatViewController: InputBarAccessoryViewDelegate {
    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }

    func processInputBar(_ inputBar: InputBarAccessoryView) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let components = inputBar.inputTextView.components
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        
        var lockCount = components.count
        for component in components {
            if let str = component as? String {
                self.sendMessage(text: str) {
                    err in
                    lockCount -= 1
                    if lockCount == 0 {
                        inputBar.sendButton.stopAnimating()
                        inputBar.inputTextView.placeholder = "Aa"
                    }
                }
            }
            else {
                lockCount -= 1
            }
        }
    }
    
}

//
//  ChatModels.swift
//  sample-comm-client
//
//  Created by Anton Baranenko on 17/06/2022.
//

import Foundation
import MessageKit
import FirebaseFirestore


public struct UserInfo: Codable {
    static let bot_user_id = "_chat_bot"
    var name: String
}

public struct ChatThread {
    var user_id: String
    var name: String
    
    func getThreadObjectId(my_user_id: String) -> String {
        if self.user_id < my_user_id {
            return "\(self.user_id):\(my_user_id)"
        }
        else {
            return "\(my_user_id):\(self.user_id)"
        }
    }
}

public struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    public var selfDestruct: Bool = false
    public var read: Bool = false
    
    init(firebaseDocument document: QueryDocumentSnapshot, sender_me: Sender, sender_them: Sender) {
        let me: Bool = (document.data()["sender"] as! String) == sender_me.senderId
        let them: Bool = (document.data()["sender"] as! String) == sender_them.senderId
        
        if (me || them) {
            if (me) { self.sender = sender_me } else { self.sender = sender_them }
        }
        else {
            self.sender = Sender(senderId: "dummy", displayName: "Unknown sender")
        }
        
        self.messageId = document.documentID
        let messageText = document["text"] as! String
        self.kind = MessageKind.text(messageText)
        self.selfDestruct = them && messageText.lowercased().starts(with: "secret:")
        let ts: Timestamp = document["date"] as! Timestamp
        self.sentDate = ts.dateValue()
        self.read = document["read"] as? Bool ?? false
    }
}

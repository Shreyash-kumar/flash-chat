import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireStore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  // void getMessages() async  {
  //  final mssg =  await _fireStore.collection('messages').get();
  //  for(var mssg in mssg.docs) {
  //    print(mssg.data());
  //  }
  // }

  void messagesStream() async {
    await for (var snapShots in _fireStore.collection('messages').snapshots()) {
      for (var snapShots in snapShots.docs) {
        print(snapShots.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                messagesStream();
                _auth.signOut();
                Navigator.pop(context);
              },
            ),
          ],
          title: Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessagesStream(),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () {
                        messageTextController.clear();
                        _fireStore.collection('messages').add({
                          'Text': messageText,
                          'Sender': loggedInUser.email,
                        });
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      builder: (context, snapShot) {
        if (snapShot.hasData) {
          final messages = snapShot.data.docs;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messagesText = message['Text'];
            final messagesSender = message['Sender'];

            final currentUser = loggedInUser.email;

            if (currentUser == messagesSender) {}

            final messageBubble = MessageBubble(
                Sender: messagesSender,
                text: messagesText,
                isMe: currentUser == messagesSender);
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children: messageBubbles,
            ),
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.Sender, this.text, this.isMe});

  final String Sender, text;
  bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe? CrossAxisAlignment.end: CrossAxisAlignment.start,
        children: [
          Text(
            Sender,
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.white70,
            ),
          ),
          Material(
            borderRadius: isMe? BorderRadius.only(
               topLeft: Radius.circular(25.0) ,
              bottomLeft: Radius.circular(25.0),
              bottomRight: Radius.circular(25.0),
            ): BorderRadius.only(
              topRight: Radius.circular(25.0) ,
              bottomLeft: Radius.circular(25.0),
              bottomRight: Radius.circular(25.0),
            ),
            elevation: 10.0,
            color: isMe? Colors.lightBlueAccent: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.0,
                  color: isMe? Colors.white: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

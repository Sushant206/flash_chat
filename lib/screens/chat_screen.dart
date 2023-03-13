import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'Chat';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String message;
  @override
  void initState() {
    super.initState();
    getcurrentuser();
  }

  void getcurrentuser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void getmessages() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var x in snapshot.docs) {
        print(x.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                getmessages();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            messageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'sender': loggedInUser.email,
                        'text': message,
                      });
                      //Implement send functionality.
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
    );
  }
}

class messageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.docs.reversed;
        List<messageBubble> messageWidget = [];
        for (var message in messages) {
          final messageText = message.get('text');
          final messageSender = message.get('sender');
          final current = loggedInUser.email;
          final x = messageBubble(
            text: messageText,
            sender: messageSender,
            isme: current == messageSender,
          );
          messageWidget.add(x);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageWidget,
          ),
        );
      },
    );
  }
}

class messageBubble extends StatelessWidget {
  messageBubble({this.text, this.sender, this.isme});
  final String text;
  final String sender;
  final bool isme;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
          crossAxisAlignment:
              isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              sender,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Material(
              borderRadius: isme
                  ? BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30))
                  : BorderRadius.only(
                      topRight: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30)),
              elevation: 7,
              color: isme ? Colors.lightBlueAccent : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  text,
                  style: TextStyle(
                      fontSize: 20,
                      color: isme ? Colors.white : Colors.black54),
                ),
              ),
            ),
          ]),
    );
  }
}

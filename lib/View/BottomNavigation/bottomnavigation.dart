import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskova_drivers/View/ChatPage/chatpage.dart';
import 'package:taskova_drivers/View/Community/community_page.dart';
import 'package:taskova_drivers/View/Homepage/homepage.dart';
import 'package:taskova_drivers/View/Language/language_provider.dart';
import 'package:taskova_drivers/View/Profile/profilepage.dart';


class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
      late AppLanguage appLanguage;

  // List of pages/screens
  
 void initState() {
    super.initState();
        appLanguage = Provider.of<AppLanguage>(context, listen: false);

  }
  final List<Widget> _pages = [
    const HomePage(),
    const Chatpage(),
    const CommunityPage(),
    const ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items:  [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: appLanguage.get('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat),
            label: appLanguage.get('Chat'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: appLanguage.get('Community'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label:  appLanguage.get('Profile'),
          ),
        ],
      ),
    );
  }
}
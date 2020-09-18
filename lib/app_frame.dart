import 'package:after_layout/after_layout.dart';
import 'package:custed2/core/hotfix.dart';
import 'package:custed2/core/tty/executer.dart';
import 'package:custed2/core/update.dart';
import 'package:custed2/core/util/build_mode.dart';
import 'package:custed2/locator.dart';
import 'package:custed2/ui/grade_tab/grade_legacy.dart';
import 'package:custed2/ui/home_tab/home_tab.dart';
import 'package:custed2/ui/schedule_tab/schedule_tab.dart';
import 'package:custed2/ui/theme.dart';
import 'package:custed2/ui/user_tab/user_tab.dart';
import 'package:custed2/ui/widgets/bottom_navbar.dart';
import 'package:custed2/ui/widgets/snakebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppFrame extends StatefulWidget {
  @override
  _AppFrameState createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> with AfterLayoutMixin<AppFrame> {
  int _selectIndex = 0;
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool isShowNavigator = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
            child: Scaffold(
          body: SizedBox.expand(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: [
                HomeTab(),
                GradeReportLegacy(),
                ScheduleTab(),
                UserTab(),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottom(context),
        )),
        Snakebar(),
      ],
    );
  }

  List<NavigationItem> items = [
    NavigationItem(Icon(Icons.home), Text('主页'), Colors.deepPurpleAccent),
    NavigationItem(Icon(Icons.leaderboard), Text('成绩'), Colors.pinkAccent),
    NavigationItem(Icon(Icons.calendar_today), Text('课表'), Colors.amberAccent),
    NavigationItem(Icon(Icons.settings), Text('设置'), Colors.cyanAccent)
  ];

  Widget _buildItem(NavigationItem item, bool isSelected) {
    bool isDarkMode = isDark(context);
    return AnimatedContainer(
      duration: Duration(milliseconds: 377),
      curve: Curves.fastOutSlowIn,
      height: 50,
      width: isSelected ? 95 : 50,
      padding: isSelected ? EdgeInsets.only(left: 16, right: 16) : null,
      decoration: isSelected
          ? BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.all(Radius.circular(50)))
          : null,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconTheme(
                data: IconThemeData(
                    size: 24, color: isDarkMode ? Colors.white : Colors.black),
                child: item.icon,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: isSelected
                    ? DefaultTextStyle.merge(
                        child: item.title,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black))
                    : null,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 8),
      //decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          var itemIndex = items.indexOf(item);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectIndex = itemIndex;
                _pageController.animateToPage(itemIndex,
                    duration: Duration(milliseconds: 377),
                    curve: Curves.easeInOutCubic);
              });
            },
            child: _buildItem(item, _selectIndex == itemIndex),
          );
        }).toList(),
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (BuildMode.isDebug) {
      print('Debug mode detected, create interface by default.');
      locator<TTYExecuter>().execute('(debug)', context, quiet: true);
    }

    // call updateCheck to ensure navigator exists in context
    updateCheck(context);

    doHotfix(context);
  }
}

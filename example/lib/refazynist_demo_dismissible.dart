/*
 *
 * Dismissible Example | Refazynist is a Refreshable, Lazy and Animated List
 * Writen by Murat TAMCI aka THEMT.CO | http://themt.co
 * 2021/06/04
 *
 */

import 'package:flutter/material.dart';
import 'package:refazynist/refazynist.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Refazynist Dismissible Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RefazynistDismissibleDemo(title: 'Refazynist Dismissible Demo'),
    );
  }
}

class RefazynistDismissibleDemo extends StatefulWidget {
  RefazynistDismissibleDemo({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _RefazynistDismissibleDemoState createState() => _RefazynistDismissibleDemoState();
}

class _RefazynistDismissibleDemoState extends State<RefazynistDismissibleDemo> {

  GlobalKey<RefazynistState> refazynistKey = GlobalKey();

  int lazyCount = 5; // It's for lazy loading limit
  String sharedPreferencesName = 'dismissible_demo'; // It's for cache. Storing in Shared Preferences

  @override
  Widget build(BuildContext bContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Refazynist(
          key: refazynistKey,
          sharedPreferencesName: sharedPreferencesName,

          onInit: () async {
            return <dynamic>['Init item 1', 'Init item 2'];
          },

          emptyBuilder: (ewContext) {
            return Stack(
              children: <Widget>[
                ListView(),
                Center(
                  child: Wrap(
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: Colors.black26,
                          ),
                          Text ('Empty'),

                          Padding(padding: EdgeInsets.only(top: 20)),

                          ElevatedButton(
                            child: Text ('Create New'),

                            onPressed: () {
                              refazynistKey.currentState!.insertItem(0, 'Created item');
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          },

          //
          // Refazynist: It's for refresh

          onRefresh: () async {
            lazyCount = 5; // reset lazy loading...

            await Future.delayed(Duration(seconds: 2)); // Fake internet delay

            return <dynamic>['Refresh item 0', 'Refresh item 1', 'Refresh item 2'];
          },

          //
          // Refazynist: It's for lazy load

          onLazy: () async {
            List<dynamic> lazyList = <dynamic>[];

            if (lazyCount > 0) {
              lazyCount--;
              lazyList.add ('Lazy item ' + (refazynistKey.currentState!.length() + 0).toString());
              lazyList.add ('Lazy item ' + (refazynistKey.currentState!.length() + 1).toString());
            }

            await Future.delayed(Duration(seconds: 1)); // Fake internet delay

            return lazyList;
          },

          //
          // Refazynist: itemBuilder

          itemBuilder: (item, ibContext, index, animation, type) {
            return Dismissible(
                key: Key(item),
                background: Container(
                  color: Theme.of(context).primaryColor,
                  child: Icon(Icons.delete_outline, color: Colors.white,),
                ),
                onDismissed: (_) {
                  refazynistKey.currentState!.removeItem(index, disappear: true);
                  setState(() {

                  });
                },
                child: FadeTransition(
                  opacity: animation,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 30),
                    child: Row(
                      children: [
                        Expanded(child: Text ('$item')),
                        ElevatedButton(
                            onPressed: () {
                              refazynistKey.currentState!.removeItem(index);
                            },
                            child: Icon(Icons.delete_outline)
                        )
                      ],
                    ),
                  ),
                )
            );

          },

          //
          // Refazynist: removed ItemBuilder (need for Flutter's Animated List)

          removedItemBuilder: (item, ibContext, index, animation, type) {
            return FadeTransition(
              opacity: animation,
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 30),
                child: Row(
                  children: [
                    Expanded(child: Text ('$item')),
                    ElevatedButton(
                        onPressed: () {
                          refazynistKey.currentState!.removeItem(index);
                        },
                        child: Icon(Icons.delete_outline)
                    )
                  ],
                ),
              ),
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (sbsContext) {
              return ListView(
                children: [
                  ListTile(
                    title: Text('Add item to top'),
                    onTap: () {
                      refazynistKey.currentState!.insertItem(0, 'Added item ${refazynistKey.currentState!.length()}');
                    },
                  ),

                  ListTile(
                    title: Text('Remove item from top'),
                    onTap: () {
                      refazynistKey.currentState!.removeItem(0);
                    },
                  ),

                  ListTile(
                    title: Text('Clear The List'),
                    onTap: () {
                      refazynistKey.currentState!.clear();
                    },
                  ),

                  ListTile(
                    title: Text('Show Shared Preferences'),
                    onTap: () async {
                      SharedPreferences _prefs = await SharedPreferences.getInstance();

                      String? spString = _prefs.getString(sharedPreferencesName);

                      print ('Shared Preferences: $spString');

                      showModalBottomSheet(
                        context: sbsContext,
                        builder: (sbsContext2) {
                          return TextField(
                            maxLines: 15,
                            decoration: InputDecoration.collapsed(hintText: spString),
                          );
                        },
                      );
                    },
                  ),

                  ListTile(
                    title: Text('Clear Shared Preferences'),
                    onTap: () async {
                      SharedPreferences _prefs = await SharedPreferences.getInstance();

                      _prefs.setString(sharedPreferencesName, '');
                    },
                  )
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

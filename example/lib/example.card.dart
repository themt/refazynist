/*
 *
 * Card Example | Refazynist is a Refreshable, Lazy and Animated List
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
      title: 'Refazynist Card Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RefazynistDismissibleDemo(title: 'Refazynist Card Demo'),
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

  int lazyCount = 2; // It's for lazy loading limit
  String sharedPreferencesName = 'dismissible_demo'; // It's for cache. Storing in Shared Preferences

  Widget _getCard (dynamic item, int index) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black38,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              title: Text('$item'),
            ),
            AspectRatio(
              aspectRatio: 300 / 200,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fitWidth,
                      alignment: FractionalOffset.center,
                      image: NetworkImage('https://picsum.photos/seed/$item/300/300'),
                    )
                ),
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.start,
              children: [
                FlatButton(
                  onPressed: () {
                    refazynistKey.currentState!.removeItem(index);
                  },
                  child: const Text('Delete'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext bContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Refazynist(
          key: refazynistKey,
          sharedPreferencesName: sharedPreferencesName,

          sequentialInsert: true,
          sequentialRemove: false,

          insertDuration: Duration(milliseconds: 150),
          removeDuration: Duration(milliseconds: 150),

          onInit: () async {
            return <dynamic>['Init item 1', 'Init item 2'];
          },



          //
          // Refazynist: It's for refresh

          onRefresh: () async {
            lazyCount = 2;

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
            if (type == RefazynistCallType.all) {
              return FadeTransition(
                opacity: animation,
                child: _getCard(item, index),
              );
            } else {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: _getCard(item, index),
                ),
              );
            }
          },

          //
          // Refazynist: removed ItemBuilder (need for Flutter's Animated List)

          removedItemBuilder: (item, ibContext, index, animation, type) {
            if (type == RefazynistCallType.all) {
              return FadeTransition(
                opacity: animation,
                child: _getCard(item, index),
              );
            } else {
              return SizeTransition(
                axis: Axis.vertical,
                sizeFactor: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: _getCard(item, index),
                ),
              );
            }

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

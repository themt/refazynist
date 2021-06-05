/*
 *
 * Refazynist is a Refreshable, Lazy and Animated List
 * Writen by Murat TAMCI aka THEMT.CO | http://themt.co
 * 2021/06/04 / v0.0.1
 *
 */

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RefazynistErrorWidget = Widget Function (BuildContext ibContext, AsyncSnapshot snapshot);
typedef RefazynistEmptyBuilder = Widget Function (BuildContext ibContext);
typedef RefazynistLoaderBuilder = Widget Function (BuildContext ibContext, Animation<double> ibAnimation);
typedef RefazynistOnLazy = Future<List<dynamic>> Function ();
typedef RefazynistItemBuilder = Widget Function (dynamic item, BuildContext ibContext, int ibIndex, Animation<double> ibAnimation, RefazynistCallType type);
typedef RefazynistRemovedItemBuilder = Widget Function (dynamic item, BuildContext ibContext, int ibIndex, Animation<double> ibAnimation, RefazynistCallType type);

/// Used for configure how [itemBuilder] or [removeItemBuilder] can be triggered
enum RefazynistCallType {
  /// The builder triggered can be single added
  item,

  /// The builder triggered can be mass added
  all,
}

/// Refazynist is a Refreshable, Lazy and Animated List
///
class Refazynist extends StatefulWidget {

  /// Creates a Refazynist
  ///
  /// The [onInit], [itemBuilder], [removedItemBuilder],
  /// [onLazy], [onRefresh], [sharedPreferencesName] arguments must be
  /// non-null.
  Refazynist({required this.onInit, required this.itemBuilder, required this.removedItemBuilder, required this.onLazy, required this.onRefresh, required this.sharedPreferencesName, this.emptyBuilder, this.loaderBuilder, this.insertDuration = const Duration(milliseconds: 500), this.removeDuration = const Duration(milliseconds: 500), this.sequentialInsert = false, this.sequentialRemove = false, Key? key}) : super(key: key);

  /// A name that's name for cache. Used for [SharedPreferences]
  String sharedPreferencesName = 'manage';

  /// A function that's called builder when list is empty
  RefazynistEmptyBuilder? emptyBuilder = (c) {
    return Center (
      child: Text ('Empty'),
    );
  };

  /// itemBuilder for rendering on Animated List
  RefazynistItemBuilder itemBuilder;

  /// itemBuilder for rendering on Animated List when item removed
  RefazynistRemovedItemBuilder removedItemBuilder;

  /// A function that's called when lazy load is required
  RefazynistOnLazy onLazy;

  /// A function that's called when swap to refresh
  RefazynistOnLazy onRefresh;

  /// A function that's called when first run
  RefazynistOnLazy onInit;

  /// A function that's called when loader rendering when lazy load required
  RefazynistLoaderBuilder? loaderBuilder;

  /// Used for how to be item inserting, sequential or same-time
  bool sequentialInsert = false;

  /// Used for how to be item removing, sequential or same-time
  bool sequentialRemove = false;

  /// Duration for animation when item inserted to list
  Duration insertDuration;

  /// Duration for animation when item removed from list
  Duration removeDuration;

  @override
  RefazynistState createState() => RefazynistState();
}

class _RefazynistItemParam {
  RefazynistCallType callType = RefazynistCallType.all;

  _RefazynistItemParam ({this.callType = RefazynistCallType.all});
}

class RefazynistState extends State<Refazynist> {

  GlobalKey<AnimatedListState> _animatedListKey = GlobalKey();
  List<dynamic> _items = <dynamic>[];
  List<_RefazynistItemParam> _params = <_RefazynistItemParam>[];

  /// A string that's store cursor in SharedPreferences
  String cursor = '';

  bool _end = false;
  Widget? _frontWidget;
  late Widget _animatedListWidget;
  
  void setTheState () {
    setState(() {

    });
  }

  /// Get length of list
  int length () {
    return _items.length;
  }

  /// Remove an item by [index]
  /// [duration] used can be animation
  /// [disappear] user can be just remove it quickly, without animation
  Future<void> removeItem (int index, {Duration? duration, bool disappear = false}) async {

    if (index >= 0 && index < _items.length) {
      int oldLen = _items.length;
      await _removeItem(index, RefazynistCallType.item, duration: duration, disappear: disappear);
      oldLen--;
      if (_frontWidget == null && oldLen == 0) {
        _frontWidget = widget.emptyBuilder!(context);
        setState(() {

        });
      }
      _setSharedPreferences();
    }
  }

  /// Insert an item by [item] at [index]
  /// callType used can be a type for itemBuilder or removeBuilder
  Future<void> insertItem (int index, dynamic item, {RefazynistCallType callType = RefazynistCallType.item}) async {
    _insertItem(index, item, callType: callType);
    _frontWidget = null;
    setState(() {

    });
    _setSharedPreferences();
  }

  /// Insert all items in [itemList] at [index]
  /// callType used can be a type for itemBuilder or removeBuilder
  Future<void> insertAllItem (int index, List<dynamic> itemList, {RefazynistCallType callType = RefazynistCallType.item}) async {
    _insertAllItem(index, itemList, callType: callType);
    _frontWidget = null;
    setState(() {

    });
    _setSharedPreferences();
  }

  Future<void> _setSharedPreferences () async {
    if (widget.sharedPreferencesName == '') return;

    SharedPreferences _prefs = await SharedPreferences.getInstance();

    await _prefs.setString(widget.sharedPreferencesName, jsonEncode({'cursor': cursor, '_end': !_loaderShowing, 'list': _items}));
  }

  Future<bool> _getSharedPreferences () async {

    if (widget.sharedPreferencesName == '') return false;

    SharedPreferences _prefs = await SharedPreferences.getInstance();

    String? spString = _prefs.getString(widget.sharedPreferencesName);

    if (spString == '') return false;

    if (spString != null) {
      Map<dynamic, dynamic> sp = jsonDecode(spString);

      if (sp.containsKey('cursor')) {
        cursor = sp['cursor'];
      }

      if (sp.containsKey('_end')) {
        _end = sp['_end'];
        if (_end) removeLoader();
        else addLoader();
      }

      if (sp.containsKey('list')) {
        List<dynamic> spList = sp['list'];

        if (spList.length > 0) {
          _insertAllItem(0, spList);
        }

        return true;
      }
    }

    return false;
  }

  Future<void> _refresh () async {

    if (!_play) return Future.value();

    List<dynamic> refreshList = await widget.onRefresh();

    if (refreshList.length > 0) {
      await clear(sequentialRemove: widget.sequentialRemove);

      _insertAllItem(_items.length, refreshList, sequentialInsert: widget.sequentialInsert, callType: RefazynistCallType.all);

      addLoader();
    }

    if (_items.length > 0) {
      _frontWidget = null;
    } else {
      _frontWidget = widget.emptyBuilder!(context);
    }

    setState(() {

    });

    return Future.value(null);
  }
  
  @override
  void initState() {
    super.initState();

    _play = true;
    _loaderShowing = false;

    _animatedListWidget = AnimatedList(
      initialItemCount: _items.length + (_loaderShowing ? 1 : 0),
      key: _animatedListKey,
      itemBuilder: _itemBuilder,
    );

    _frontWidget = Center(
      child: CircularProgressIndicator(),
    );

    _onInit();
  }

  /// Clear the all item on list
  ///
  /// [sequentialRemove] used for remove process, true for ordered-time, false for same-time
  Future<void> clear ({bool sequentialRemove = false}) async {
    _clearRunning = true;

    removeLoader();

    int oldLen = _items.length;

    if (sequentialRemove) {
      for (int i=0; i<oldLen; i++) {
        await _removeItem(0, RefazynistCallType.all);
      }
    } else {
      for (int i=0; i<oldLen; i++) {
        _removeItem(0, RefazynistCallType.all);
      }
    }


    _setSharedPreferences();

    await Future.delayed(widget.removeDuration);

    if (_items.length > 0) {
      _frontWidget = null;
    } else {
      _frontWidget = widget.emptyBuilder!(context);
    }

    setState(() {

    });

    _clearRunning = false;
  }

  Future<void> _insertItem (index, dynamic item, {RefazynistCallType callType = RefazynistCallType.item}) async {
    assert (index >= 0);

    _items.insert(index, item);
    _params.insert(index, _RefazynistItemParam());
    _params[index].callType = callType;

    _animatedListKey.currentState!.insertItem(index, duration: widget.insertDuration);

    await Future.delayed(widget.insertDuration);

    return;
  }

  Future<void> _insertAllItem (int index, List<dynamic> list_items, {bool sequentialInsert = false, RefazynistCallType callType = RefazynistCallType.item}) async {
    if (sequentialInsert) {
      for (int i=0; i<list_items.length; i++) {
        await _insertItem(index+i, list_items[i], callType: callType);
      }
    } else {
      for (int i=0; i<list_items.length; i++) {
        _insertItem(index+i, list_items[i], callType: callType);
      }
    }
  }

  Future<dynamic> _removeItem (int index, RefazynistCallType callType, {Duration? duration, bool disappear = false}) async {
    assert (index >= 0);
    assert (index < _items.length);

    _params.removeAt(index);
    dynamic item = _items.removeAt(index);
    _animatedListKey.currentState!.removeItem(index, (context, animation) {
      if (disappear)
        return Container();
      else
        return widget.removedItemBuilder(item, context, index, animation, callType);
    }, duration: disappear ? Duration(seconds: 0) : duration??widget.removeDuration);

    if (disappear == false) await Future.delayed(duration??widget.removeDuration);



    return item;
  }

  /// Add loader on the end on list for indicate lazy load is working
  Future<void> addLoader () async {
    _loaderShowing = true;
    _onLazyRunning = false;
    if (_animatedListKey.currentState != null) {
      _animatedListKey.currentState!.insertItem(_items.length, duration: widget.insertDuration);
    }
  }

  /// Remove loader on the end on list when lazy load in progress
  Future<void> removeLoader () async {
    if (_loaderShowing) {
      _animatedListKey.currentState!.removeItem(_items.length, (riContext, animation) {
        return FadeTransition(
          opacity: animation,
          child: _getLoader(riContext, animation),
        );
      }, duration: widget.removeDuration);

      await Future.delayed(widget.removeDuration);

      _loaderShowing = false;
    }

  }

  Widget _getLoader (BuildContext ibContext, Animation<double> ibAnimation) {
    if (widget.loaderBuilder != null) {
      return widget.loaderBuilder!(ibContext, ibAnimation);
    }

    return Center(
      child: FadeTransition(
        opacity: ibAnimation,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        )),
    );
  }

  bool _loaderShowing = false;
  bool _onLazyRunning = false;
  bool _clearRunning = false;
  bool _play = false;

  Widget _itemBuilder (BuildContext ibContext, int index, Animation<double> ibAnimation) {

    if (_loaderShowing && index >= _items.length) {

      // lazynin çağrılması için o an çalışmıyor olması gerek
      // ek olarak temizleme yapılmıyor olmalı. temizlerken eklemek saçma olur

      if (_play && _onLazyRunning == false && _clearRunning == false) {
        _onLazyRunning = true;

        Future<List<dynamic>> futureLazyList = widget.onLazy ();

        futureLazyList.then ((List<dynamic> lazyList) {

          if (!_play) return;
          if (_clearRunning) return; // temizlenme istendiyse ekleme yapmak anlamsız.

          if (lazyList.length == 0) {
            removeLoader().then((value) {
              _setSharedPreferences();
            });
          } else {
            _insertAllItem(_items.length, lazyList, sequentialInsert: widget.sequentialInsert, callType: RefazynistCallType.all);
            _setSharedPreferences();
          }


          _onLazyRunning = false;
        });
      }

      return _getLoader(ibContext, ibAnimation);
    }

    if (index < _items.length) {
      return widget.itemBuilder (_items[index], ibContext, index, ibAnimation, _params[index].callType);
    }


    return Center(
      child: Text ("Overflow #$index"),
    );
  }

  Future<bool> _onInit () async {
    //print ('_onInit');

    if (!_play) return false;

    _loaderShowing = false;

    bool spResult = await _getSharedPreferences(); // kayıtlı veri varsa çek
    //bool spResult = false;

    // kayıtlı veri yoksa netten al
    if (!spResult) {
      List<dynamic> list = await widget.onInit();

      if (list.length > 0) {
        //_items.addAll(list);
        _insertAllItem(0, list, sequentialInsert: widget.sequentialInsert, callType: RefazynistCallType.all);

        await _setSharedPreferences();

      }
    }


    if (_items.length > 0) {
      _frontWidget = null;
    } else {
      _frontWidget = widget.emptyBuilder!(context);
    }

    setState(() {

    });

    return true;
  }

  @override
  Widget build(BuildContext context) {

    if (_frontWidget != null) {
      return RefreshIndicator(
          child: Stack(
            children: [
              Opacity(
                opacity: 0,
                child: _animatedListWidget,
              ),
              _frontWidget!,
            ],
          ),
          onRefresh: _refresh
      );
    } else {
      return RefreshIndicator(
          child: _animatedListWidget,
          onRefresh: _refresh
      );
    }

  }
}
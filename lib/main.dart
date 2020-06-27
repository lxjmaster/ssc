import 'package:flutter/material.dart';
import 'package:ssc/utils.dart';
import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FlutterEasyLoading(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "时时彩",
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Timer _timer; // 定时器
  List data = List<Widget>(); // 渲染好的widget数组
  List localtext = List<String>();  // 开奖数据,每个元素代表一行数据
  Map changedata = new Map(); // 保存需要标红的开奖数据
  FocusNode _horizontalFocusNode; // 横输入框焦点
  FocusNode _verticalFocusNode; // 纵输入框焦点
  TextEditingController _horizontalController;  // 横输入框控制器
  TextEditingController _verticalController;  // 纵输入框控制器
  ScrollController _myScrollController; // 下拉控制器
  var _futureBuilderFuture;
  List _datas = List<String>();

  List range(int start, int end) {
    List _range = [];
    for(int i=start; i<end; i++) {
      _range.add(i);
    }
    return _range;
  }

  List parseRule(List rule) {
    // 解析输入的号码
    List<String> newrule = [];
    for(String r in rule) {
      if(newrule.indexOf(r) == -1) {
        newrule.add(r);
        var reverse = r.split("").reversed.join();
        // 反转也算
        if(newrule.indexOf(reverse) == -1) {
          newrule.add(reverse);
        }
      }
    }
    // 返回原号码,和原号码反转
    return newrule;
  }


  parseData(List horizontalrule, List verticalrule) {
    changedata.clear();
    int count = 0;
    List one = [];
    List two = [];
    List three = [];
    List four = [];
    List five = [];
    for(String i in localtext) {
      // i代表单期开奖数据
      // 去除空格,将开奖数据格式转换为2019062001605132
      String text = i.splitMapJoin((new RegExp(r'\d')),
        onMatch:    (m) => '${m.group(0)}',
        onNonMatch: (n) => ''
      );
      var stext = text.substring(11); // 开奖号码
      var linetext = stext.split(""); // 转换为数组
      for(int j=0; j<stext.length; j++) {
        // 将开奖号(根据位置)分别存入5个数组保存
        switch(j) {
          case 0:
            one.add(linetext[j]);
            break;
          case 1:
            two.add(linetext[j]);
            break;
          case 2:
            three.add(linetext[j]);
            break;
          case 3:
            four.add(linetext[j]);
            break;
          case 4:
            five.add(linetext[j]);
            break;
          default:
            break;
        }
      }
      for(String r in horizontalrule) {
        // 遍历横规则(包含反转规则)
        int a = stext.indexOf(r); // 判断开奖号码是否符合横规则
        if(a != -1) { // 符合横规则
          if(changedata[count] != null){  // 该行已有标红开奖
            changedata[count].addAll(range(a, a+r.length)); // 往后继续添加
          }else {
            changedata[count] = range(a, a+r.length); // 直接添加标红开奖数据
          }
        }
      }
      count += 1; // 行号+1,进入下一行
    }
    List verticallist = [one, two, three, four, five];  // 纵,元素下标就是列数
    for(String r in verticalrule) {
      // 遍历纵规则
      RegExp reg = RegExp(r);
      for(int v=0; v<verticallist.length; v++) {
        Iterable<Match> matches = reg.allMatches(verticallist[v].join("")); // 正则匹配第一列所有符合规则的数据
        for(Match m in matches) {
          // 遍历符合的每一项
          List myrange = range(m.start, m.end);
          for(int index in myrange) {
            if(changedata[index] != null) {
              if(!changedata[index].contains(v)) { // 修改数据种某行某列不存在
                changedata[index].add(v); // 加进去
              }//否则不做处理
            } else {
              changedata[index] = [v];
            }
          }
        }
      }
    }
  }

  @override
  void initState() {
    
    _horizontalFocusNode = FocusNode();
    _verticalFocusNode = FocusNode();
    _horizontalController = TextEditingController();
    _verticalController = TextEditingController();
    _myScrollController = ScrollController();
    // 初始化
    myinit();
    // readfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EasyLoading.show(status: "加载数据...");
    });

    // print(getKjTime());
    startCountdownTimer(10, _timer);

    // TODO: implement initState
    super.initState();

    _futureBuilderFuture = readfile();

  }

  Future<int> getKjTime() async {
    int time;
    try {
      http.Response res = await http.get("https://cqssc.17500.cn/tools/getedtime.html");
      if(res.body != null) {
        final body = json.decode(res.body.toString());
        final data1 = body["data1"];
        final data2 = body["data2"];
        final data3 = body["data3"];
        if(data3.length > 0) {
          final data3_time = data3["time"];
          time = data3_time;
        } else if(data2.length > 0) {
          final data2_time = data2["time"];
          time = data2_time;
        } else if(data1.length > 0) {
          final data1_time = data1["time"];
          time = data1_time;
        }
      }
    } catch(exception) {
      return 60 * 10 * 1000;
    }
    return time;
  }

  startCountdownTimer(int _countdownTime, Timer _timer) {
    const oneSec = const Duration(seconds: 1);

    _timer = Timer.periodic(oneSec, (timer) async {
      if(_countdownTime < 1) {
        getData();
        Future.delayed(const Duration(seconds:5), () {
          setState(() {
            data.clear();
            readfile();
          });
        });
        reload();
        // search();
        int a = await getKjTime();
        _countdownTime = a ~/ 1000 + 70;
        // search()
      } else {
          _countdownTime -= 1;
          // print(_countdownTime);
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("时时彩")
      ),
      body: FutureBuilder(
        future: _futureBuilderFuture,
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if(snapshot.data !=null && snapshot.data.length > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              EasyLoading.dismiss();
            });
            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(top: 20.0),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 10.0, bottom: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 30.0,
                                  maxWidth: 280.0
                                ),
                                child: TextField(
                                  focusNode: _horizontalFocusNode,
                                  controller: _horizontalController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(5.0),
                                    border: OutlineInputBorder(),
                                    icon: Text("搜索横:"),
                                  ),
                                  style: TextStyle(fontSize: 12.0),
                                ),
                              ),
                              Padding(padding: EdgeInsets.only(top: 5.0)),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 30.0,
                                  maxWidth: 280.0
                                ),
                                child: TextField(
                                  focusNode: _verticalFocusNode,
                                  controller: _verticalController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(5.0),
                                    border: OutlineInputBorder(),
                                    icon: Text("搜索纵:"),
                                  ),
                                  style: TextStyle(fontSize: 12.0),
                                ),
                              ),
                            ]
                          ),
                          Expanded(
                            // margin: EdgeInsets.only(left: 20.0),
                            child: OutlineButton(
                              child: Text("搜索"),
                              onPressed: () => search(),
                            )
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: DraggableScrollbar.rrect(
                        controller: _myScrollController,
                        child: ListView.builder(
                          controller: _myScrollController,
                          itemCount: data.length,
                          itemExtent: 18.0,
                          itemBuilder: (BuildContext context, int index) {
                            return data[index];
                          }
                        ),
                      )
                    )
                  ],
                ),
              ),
            );
          } else {
            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(top: 20.0),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 10.0, bottom: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 30.0,
                                  maxWidth: 280.0
                                ),
                                child: TextField(
                                  focusNode: _horizontalFocusNode,
                                  controller: _horizontalController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(5.0),
                                    border: OutlineInputBorder(),
                                    icon: Text("搜索横:"),
                                  ),
                                  style: TextStyle(fontSize: 12.0),
                                ),
                              ),
                              Padding(padding: EdgeInsets.only(top: 5.0)),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: 30.0,
                                  maxWidth: 280.0
                                ),
                                child: TextField(
                                  focusNode: _verticalFocusNode,
                                  controller: _verticalController,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(5.0),
                                    border: OutlineInputBorder(),
                                    icon: Text("搜索纵:"),
                                  ),
                                  style: TextStyle(fontSize: 12.0),
                                ),
                              ),
                            ]
                          ),
                          Expanded(
                            // margin: EdgeInsets.only(left: 20.0),
                            child: OutlineButton(
                              child: Text("搜索"),
                              onPressed: (){},
                            )
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: DraggableScrollbar.rrect(
                        controller: _myScrollController,
                        child: ListView.builder(
                          controller: _myScrollController,
                          itemCount: data.length,
                          itemExtent: 18.0,
                          itemBuilder: (BuildContext context, int index) {
                            return data[index];
                          }
                        ),
                      )
                    )
                  ],
                ),
              )
            );
          }
        },
      )
    );
  }

  search() {
    _horizontalFocusNode.unfocus();
    _verticalFocusNode.unfocus();
    Future.delayed(const Duration(seconds: 1), () {
      if(_horizontalController.text.isNotEmpty || _verticalController.text.isNotEmpty) {
        EasyLoading.show(status: "搜索...");
        parseData(
          parseRule(_horizontalController.text.split(",")),
          parseRule(_verticalController.text.split(","))
        );
        for (int i=0; i<data.length; i++) {
          if(changedata[i] != null && changedata[i].length > 0) {
            List<Widget> changewidget = [
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text(
                  data[i].children[0].child.data,
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              )
            ];
            for(int index=0; index<5; index++) {
              if(changedata[i].contains(index)) {
                changewidget.add(
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[index+1].child.data,
                      style: TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.underline
                      ),
                    ),
                  )
                );
              } else {
                changewidget.add(
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[index+1].child.data
                    ),
                  )
                );
              }
            }
            setState(() {
              data[i] = Row(
                children: changewidget,
              );
            });
          } else {
            setState(() {
              data[i] = Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[0].child.data,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[1].child.data,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[2].child.data,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[3].child.data,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[4].child.data,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Text(
                      data[i].children[5].child.data,
                    ),
                  ),
                ],
              );
            });
          }
        }
      } else {
        // readfile().whenComplete(reload());
      }
      if(_horizontalController.text.isNotEmpty && _verticalController.text.isEmpty) {
        changedata.forEach((key, value) {
          if(key > 15 && value.length >= 3) {
            var d = localtext.sublist(key-15, key+16);
            var data = d.join("\n");
            _datas.add(data);
          }
        });
        writeData(_datas.join("\n${'='*20}\n"));
      }else if(_horizontalController.text.isEmpty && _verticalController.text.isNotEmpty) {
        print(changedata);
        changedata.forEach((key, value) {
          if(key > 10 && value.length > 0) {
            print("${key}-${value}");
          }
        });
      }
    });
  }

  reload() async {
    getData();
    File file = await getLocalFile();
    List text = await file.readAsLines();
    // data.clear();
    for(int i=0; i<text.length; i++) {
      var texts = text[i].split(" ");
      setState(() {
        try {
          data[i] = 
            Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Text("${texts[0]}"),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Text("${texts[1]}"),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Text("${texts[2]}"),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Text("${texts[3]}"),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Text("${texts[4]}"),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Text("${texts[5]}"),
                ),
              ],
            );
        } catch (exception) {

        }
      });
    }
  }
  

  Future<List> readfile() async {
    data.clear();
    File file = await getLocalFile();
    List text = await file.readAsLines();
    // data.clear();
    localtext = text;
    for(int i=0; i<text.length; i++) {
      var item = text[i];
      var texts = item.split(" ");
      try {
        data.add(
          Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("${texts[0]}"),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("${texts[1]}"),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("${texts[2]}"),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("${texts[3]}"),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("${texts[4]}"),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("${texts[5]}"),
              ),
            ],
          )
        ); 
      } catch(exception) {

      }
    }
    return data;
  }

}




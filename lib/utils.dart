import 'package:connectivity/connectivity.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;


myinit() async {
  await getLocalFile();
  bool _is_connectes = await isConnected();
  if(_is_connectes) {
    getData();
  }
}

String getData() {
  String url = "https://cqssc.17500.cn/data/cqssc_10000.txt";
  HttpContorler.get(url, (data) {
    writeFile(data);
  }, null, null);
}

// check the connect
Future<bool> isConnected() async {
  try {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  } catch(error) {
    print(error);
    return false;
  }
}

class HttpContorler {
  static void get(String url, Function callback,
  Map<String, String> params, Function errorcallback) async {
    if(params != null && params.isNotEmpty) {
      StringBuffer sb = new StringBuffer("?");
      params.forEach((String key, String value) {
        sb.write("$key" + "=" + "$value" + "&");
      });
      String paramStr = sb.toString();
      paramStr = paramStr.substring(0, paramStr.length - 1);
      url += paramStr;
    }
    try {
      http.Response res = await http.get(url);
      if(callback != null) {
        callback(res.body);
      }
    } catch(exception) {
      if(errorcallback != null) {
        errorcallback(exception);
      }
    }
  }
}

// check file exists
Future<bool> fileIsExists(File file) async {
  return file.exists();
}

// 开奖数据文件,不存在则创建,存在返回文件路径
Future<File> getLocalFile() async {
     // 获取文档目录的路径
    Directory appStoDir = await getExternalStorageDirectory();
    String dir = appStoDir.path;
    String filepath = '$dir/10000.txt';
    final file = new File(filepath);
    // file.create();
    if(!await file.exists()) {
      file.create();
    }
    return file;
}

void writeFile(content) async {
  File file = await getLocalFile();
  file.writeAsString(content);
}

// 保存开奖走势的文件
Future<File> getDataFile() async {
    Directory appStoDir = await getExternalStorageDirectory();
    String dir = appStoDir.path;
    String filepath = '$dir/data.txt';
    final file = new File(filepath);
    if(!await file.exists()) {
      file.create();
    }
    return file;
}

void writeData(contents) async {
  File file = await getDataFile();
  file.writeAsString(contents);
}
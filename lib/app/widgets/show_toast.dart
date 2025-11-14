import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ShowToast {
  String msg;
  Toast? toastLength;
  ToastGravity? toastGravity;
  int? timeTillShow;
  Color? bgColor, textColor;
  double? fontSize;

  ShowToast({required this.msg, this.toastLength, this.toastGravity,this.timeTillShow, this.bgColor, this.textColor, this.fontSize}) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength,
        gravity: toastGravity,
        timeInSecForIosWeb: timeTillShow ?? 1,
        backgroundColor: bgColor,
        textColor: textColor,
        fontSize: fontSize
    );
  }

  static void setMsg(String msg){
    Fluttertoast.showToast(msg: msg);
  }
}

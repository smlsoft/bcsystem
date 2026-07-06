import 'package:dedecashier/db/shift_helper.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/util/printer.dart';
import 'package:dedecashier/widgets/numpad.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Mode (1=เปิดกะ+เงินทอน, 2=ปิดกะ+ส่งเงิน, 3=เติมเงินทอน, 4=นำเงินออก)

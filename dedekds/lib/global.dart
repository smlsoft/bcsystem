import 'dart:convert';

import 'package:dedekds/model/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

double flutterTtsVolume = 1.0;
double flutterTtsPitch = 1.0;
double flutterTtsRate = 0.6;
late FlutterTts flutterTts;
bool ipPosTerminalFixed = false;
String ipAddress = "";
String ipPosTerminalAddress = "";
String userLanguage = "th";
String posTerminalDeviceId = "";
String posTerminalDeviceName = "";
String posTerminalDeviceIpAddress = "";
int posTerminalDevicePort = 4040;
bool posTerminalConnected = false;
String posKitchenId = "";
String posKitchenName = "";
bool posScanTerminal = false;
List<int> cookingTimeSecond = [20 * 60, 30 * 60, 40 * 60];
final moneyFormat = NumberFormat("##,##0.##");
bool orderSendToPrinter = false;
bool orderTextToSpeech = false;
PrinterLocalStrongDataModel printerConnectData = PrinterLocalStrongDataModel();
List<String> orderTextToSpeechList = [];
DateTime orderTextToSpeechLastTime = DateTime.now();
List<PosSaleChannelModel> posSaleChannelLists = [];

enum PrintColumnAlign { left, right, center }

enum PrinterTypeEnum { thermal, dot, laser, inkjet }

enum PrinterConnectEnum { ip, bluetooth, usb, windows, sunmi1 }

class OrderTextToSpeechModel {
  DateTime orderTime = DateTime.now();
  String orderGuid = "";
  String orderText = "";
}

double printerWidthByPixel() {
  if (printerConnectData.paperSize == 1) {
    return 384;
  } else {
    return 576;
  }
}

Future<void> loadServerData() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    posTerminalDeviceId = prefs.getString("pos_device_id") ?? "";
    posKitchenId = prefs.getString("pos_kitchen_id") ?? "";
    posKitchenName = prefs.getString("pos_kitchen_name") ?? "";
    orderSendToPrinter = prefs.getBool("order_send_to_printer") ?? false;
    orderTextToSpeech = prefs.getBool("order_text_to_speech") ?? false;
    printerConnectData = PrinterLocalStrongDataModel.fromJson(
        jsonDecode(prefs.getString("pos_printer") ?? "{}"));
  } catch (e) {
    posTerminalDeviceId = "";
  }
  posTerminalDeviceIpAddress = "";
}

Future<void> saveServerData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("pos_device_id", posTerminalDeviceId);
  await prefs.setString("pos_kitchen_id", posKitchenId);
  await prefs.setString("pos_kitchen_name", posKitchenName);
  await prefs.setBool("order_send_to_printer", orderSendToPrinter);
  await prefs.setBool("order_text_to_speech", orderTextToSpeech);
  await prefs.setString(
      "pos_printer", const JsonEncoder().convert(printerConnectData.toJson()));
}

List<LanguageNameModel> languageJsonDecode(String jsonNames) {
  return jsonDecode(jsonNames).map<LanguageNameModel>((item) {
    return LanguageNameModel.fromJson(item);
  }).toList();
}

String getNameFromJsonLanguage(String jsonNames, String languageCode) {
  List<LanguageNameModel> names = languageJsonDecode(jsonNames);
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return "*";
}

String getNameFromLanguage(List<LanguageNameModel> names, String languageCode) {
  for (var item in names) {
    if (item.code == languageCode) {
      return item.name;
    }
  }
  return "*";
}

String language(String code) {
  return code;
}

String getDeliveryName({required code}) {
  var result = code;
  for (var data in posSaleChannelLists) {
    if (data.code == code) {
      result = data.name;
      break;
    }
  }
  return result;
}

Future<void> speak(String word) async {
  await flutterTts.setVolume(flutterTtsVolume);
  await flutterTts.setSpeechRate(flutterTtsRate);
  await flutterTts.setPitch(flutterTtsPitch);
  await flutterTts.setLanguage("th-TH");

  if (word.isNotEmpty) {
    await flutterTts.speak(word);
  }
}

Future<void> initTts() async {
  flutterTts = FlutterTts();

  _setAwaitOptions();

  _getDefaultEngine();
  _getDefaultVoice();

  await flutterTts.setLanguage("th-TH");
  await flutterTts.setPitch(flutterTtsPitch);
  await flutterTts.setSpeechRate(flutterTtsRate);
  await flutterTts.setVolume(flutterTtsVolume);
  await flutterTts.speak("เริ่มต้นการใช้งาน ขอให้พนักงานสนุกกับการทำงาน");
}

Future _setAwaitOptions() async {
  await flutterTts.awaitSpeakCompletion(true);
}

Future _getDefaultEngine() async {
  var engine = await flutterTts.getDefaultEngine;
  if (engine != null) {
    if (kDebugMode) {
      print(engine);
    }
  }
}

Future _getDefaultVoice() async {
  var voice = await flutterTts.getDefaultVoice;
  if (voice != null) {
    if (kDebugMode) {
      print(voice);
    }
  }
}

List<String> warningList = [
  "โอ้โห! อาหารไม่มาสักที ลูกค้าเริ่มกินโต๊ะแล้วนะ",
  "ด่วนจี๋! ลูกค้ากำลังร้องเพลงลูกทุ่งอีสาน เสียงดังลั่นร้าน",
  "แจ้งด่วน! ลูกค้าเอาผ้าเช็ดปากมาทอเป็นผ้าถุงระหว่างรอ",
  "รีบจัดการด่วน! ลูกค้าออกไปหาหมอดูเพื่อสะเดาะเคราะห์อาหารช้า",
  "สายฟ้าฟาด! ลูกค้ากำลังสอนแมวในร้านให้เต้นบัลเล่ต์",
  "รีบส่งอาหารมา! ลูกค้าเริ่มปั้นรูปปั้นจากเกลือบนโต๊ะแล้วนะ",
  "ขอเตือน! ลูกค้ากำลังเขียนตำราวิธีรักษาโรคหิวด้วยน้ำจิ้มในถ้วย",
  "รีบแก้ไขด่วน! ลูกค้าเอาส้มตำมาสร้างแบบจำลองภูเขาไฟฟูจิ",
  "เอาจริงเหรอ? ลูกค้าเริ่มสานตะกร้าจากเส้นก๋วยเตี๋ยวในจาน",
  "แจ้งด่วนที่สุด! ลูกค้ากำลังเปิดคอร์สสอน 'วิธีนั่งรออาหารให้ผอมเหมือนไม้เสียบลูกชิ้น'",
  "แย่แล้ว! ลูกค้าเริ่มเดินขายลูกอมในร้านเพื่อหาเงินซื้ออาหาร",
  "ด่วนจี๊ดๆ! ลูกค้ากำลังเอาตะเกียบมาต่อเป็นขาตั้งกล้องถ่ายทำสารคดี 'ชีวิตของคนหิวโหย'",
  "บอกด้วยนะ! ลูกค้าเริ่มเลี้ยงผึ้งในแก้วน้ำเปล่าเพื่อเอาน้ำผึ้งมากิน",
  "รีบมาเร็วๆ! ลูกค้ากำลังสร้างเครื่องย่อส่วนเวลาจากเศษอาหารบนโต๊ะ",
  "เอาจริงๆ นะเนี่ย! ลูกค้าเริ่มเขียนนิยายเรื่อง 'เจ้าหญิงนิทรา 100 ปีรออาหาร'",
  "แจ้งเตือนนะ! ลูกค้ากำลังฝึกวิชาเวทมนตร์เพื่อเสกข้าวออกจากอากาศ",
  "ตายแล้ว! ลูกค้าเอากระดาษทิชชู่มาพับเป็นชุดนางในวัง",
  "ด่วนที่สุดในโลกใบนี้! ลูกค้าเริ่มแกะสลักพระพุทธรูปจากก้อนน้ำแข็งในแก้ว",
  "บอกแล้วไม่เชื่อ! ลูกค้ากำลังเขียนตำนาน 'ผีกระสือกินอาหารช้า' ด้วยซอสบนโต๊ะ",
  "รีบมาด่วนเลย! ลูกค้าเริ่มสร้างแบบจำลองพระราชวังบางปะอินจากเม็ดพริกไทย",
  "เอาจริงๆ นะ! ลูกค้ากำลังฝึกม้าเทียมเก้าอี้ให้วิ่งไปส่งอาหารในครัว",
  "แจ้งเตือนนะจ๊ะ! ลูกค้าเริ่มเขียนบทละครเวทีเรื่อง 'สาวใต้รอผัวกับหนุ่มอีสานรออาหาร'",
  "ไม่เชื่อก็ต้องเชื่อ! ลูกค้ากำลังสอนแมลงวันให้บินไปสั่งอาหารในครัว",
  "ด่วนจ้า! ลูกค้าเริ่มแกะสลักดอกกุหลาบจากแครอทในสลัด",
  "รีบมาด่วนเลย! ลูกค้ากำลังเขียนเพลงอกหักเพราะอาหารมาช้าเกินรอ",
  "เอาจริงๆ นะเนี่ย! ลูกค้าเริ่มทอผ้าไหมจากเส้นผักในสลัด",
  "แจ้งด่วนที่สุดในใต้หล้า! ลูกค้ากำลังสร้างหุ่นยนต์จากช้อนส้อมเพื่อไปตามอาหาร",
  "ไม่น่าเชื่อสายตาตัวเอง! ลูกค้าเริ่มเลี้ยงหนอนไหมในถ้วยน้ำจิ้มเพื่อทำผ้าไหม",
  "รีบส่งคนมาดูด่วน! ลูกค้ากำลังสร้างแบบจำลองภูเขาทองจากเกลือบนโต๊ะ",
  "เอาจริงดิ! ลูกค้าเริ่มเขียนตำราพิชัยสงครามการรบกับความหิว",
  "แจ้งเหตุด่วน! ลูกค้ากำลังฝึกนกพิราบให้บินไปส่งจดหมายร้องเรียนถึงเชฟ",
  "ด่วนที่สุดในประวัติศาสตร์! ลูกค้าเริ่มขุดคลองเจ้าพระยาจำลองบนโต๊ะด้วยส้อม",
  "บอกมาไม่ได้ยิน! ลูกค้ากำลังเขียนบทเพลงลิเกเรื่อง 'ตำนานรักของคนรออาหาร'",
  "รีบส่งอาหารนะ! ลูกค้ากำลังท่องบทสวดมนต์ 'ขออาหารเร็วไว' เพื่อความสงบของใจ",
  "ด่วนจี๋! ลูกค้ากำลังบรรยายธรรมมะ 'การรอคอยคือการฝึกความอดทน' ให้เพื่อนโต๊ะข้างๆ ฟัง",
  "ไม่เชื่อก็ต้องเชื่อ! ลูกค้ากำลังสมาธิขั้นสูงหวังให้อาหารเสร็จเร็วขึ้น",
  "รีบมาเร็ว! ลูกค้ากำลังสอนนั่งสมาธิ 'พิจารณาความว่างเปล่าบนโต๊ะอาหาร'",
  "แย่แล้ว! ลูกค้ากำลังเทศนาเรื่อง 'ความหิวเป็นทุกข์' ให้พนักงานฟัง",
  "ด่วนมาก! ลูกค้ากำลังเปิดคอร์สธรรมมะ 'การปล่อยวางจากการรออาหาร'",
  "ไม่น่าเชื่อ! ลูกค้ากำลังเขียนหนังสือ 'ศิลปะแห่งการรอคอยแบบไร้ทุกข์'",
  "รีบมาด่วน! ลูกค้ากำลังบรรยายธรรมมะ 'อาหารช้า เป็นการฝึกใจให้สงบ'",
  "แย่แล้ว! ลูกค้ากำลังสอนเด็กในร้านเรื่อง 'ความหิวคือบททดสอบของชีวิต'",
  "ด่วนจี๊ดๆ! ลูกค้ากำลังฝึก 'สติปัฏฐาน 4' เพื่อคุมสติไม่ให้หิวเกินไป",
  "บอกแล้วนะ! ลูกค้ากำลังนั่งสมาธิ 'ขอพลังความอดทนมาสู้กับความหิว'",
  "ไม่น่าเชื่อ! ลูกค้ากำลังเทศน์เรื่อง 'การรออาหารอย่างสงบเสงี่ยม'",
  "รีบมาเร็ว! ลูกค้ากำลังบรรยายเรื่อง 'การปล่อยวางจากความหิว' ให้โต๊ะข้างๆ ฟัง",
  "รีบมาเถอะ! ลูกค้ากำลังบรรยายเรื่อง 'ความหิวเป็นธรรมชาติ แต่เราคือผู้ควบคุมมัน'",
  "ด่วนจี๋! ลูกค้ากำลังเทศน์สอนพนักงาน 'อาหารที่ช้า คือบททดสอบของความเมตตา'",
  "ไม่น่าเชื่อ! ลูกค้ากำลังเขียนบทความ 'ความสุขเกิดจากการรอคอยที่ไม่หิว'",
  "รีบมาด่วน! ลูกค้ากำลังวางแผนทำสมาธิในท่านั่งรออาหารอย่างสงบ",
  "แย่แล้ว! ลูกค้ากำลังแจกใบปลิวสอนธรรมะ 'รออาหารอย่างไรให้มีสติ'",
  "บอกแล้วนะ! ลูกค้ากำลังทำแผนภูมิ 'วิธีรับมือกับความหิวที่ไม่คาดคิด'",
  "รีบมาเร็ว! ลูกค้ากำลังสอนเด็กในร้านเรื่อง 'ความอดทนคือคุณธรรมสูงสุด'",
  "ด่วนจ้า! ลูกค้ากำลังเขียนคาถาปลุกใจ 'รออาหารโดยไม่ทุรนทุราย'",
  "แย่แล้ว! ลูกค้ากำลังบรรยายเรื่อง 'ศิลปะการนั่งสมาธิในร้านอาหาร'",
  "รีบมาเร็วๆ! ลูกค้ากำลังทำปริศนาธรรม 'ความหิวกับความสุขแท้จริงอยู่ที่ไหน'",
  "บอกไม่ทัน! ลูกค้ากำลังแนะนำหลักการ 'รออย่างมีสติ ไม่รีบร้อน'",
  "ด่วนที่สุด! ลูกค้ากำลังสอนวิธี 'หายใจเพื่อผ่อนคลายความหิว'",
  "ไม่น่าเชื่อ! ลูกค้ากำลังเริ่มสวดมนต์เพื่อให้จิตสงบจากการรออาหาร",
  "รีบมาเร็ว! ลูกค้ากำลังเขียนหนังสือธรรมะ 'อาหารที่รอคอย กับใจที่สงบ'",
  "ด่วนจี๊ด! ลูกค้ากำลังทำท่าฝึกจิต 'อาหารมาช้าแต่ใจไม่ทุกข์'",
  "แย่แล้ว! ลูกค้ากำลังบรรยายเรื่อง 'การรอคอยอย่างไรให้ใจเป็นสุข'",
  "บอกแล้วนะ! ลูกค้ากำลังสอนการฝึกสมาธิ 'นั่งรออย่างไรให้สงบสุข'",
  "รีบมาเร็ว! ลูกค้ากำลังท่องคาถา 'ความหิวเป็นเพียงภาพลวงตา'",
  "ด่วนที่สุด! ลูกค้ากำลังเปิดสำนักสอน 'วิธีรออาหารโดยไม่ให้จิตหวั่นไหว'",
  "ไม่น่าเชื่อ! ลูกค้ากำลังแจกคาถา 'รออาหารอย่างไรให้มีสติและสงบ'",
  "ด่วนจ้า! ลูกค้ากำลังฝึก 'อานาปานสติ' เพื่อไม่ให้คิดถึงอาหารมากเกินไป",
  "แย่แล้ว! ลูกค้ากำลังเปิดสำนักธรรมมะ 'วิธีรอคอยอาหารแบบมีสติ'",
  "รีบมาด่วน! ลูกค้ากำลังสอนเพื่อนโต๊ะข้างๆ เรื่อง 'ความหิวคือมายา'",
  "ไม่น่าเชื่อ! ลูกค้ากำลังวาดแผนที่ 'เส้นทางหลุดพ้นจากความหิว'",
  "ด่วนที่สุด! ลูกค้ากำลังจัดอบรม 'ศิลปะแห่งการรอคอยอย่างมีเมตตา'",
  "รีบมาเร็วที่สุด! ลูกค้ากำลังเขียนคาถาเรียกอาหารเร็ว",
  "แปลกแต่จริง! ลูกค้ากำลังฝึกโยคะ 'ท่าผ่อนคลายความหิว'",
  "รีบมาด่วนที่สุดเลย! ลูกค้าเริ่มสร้างเครื่องมือค้นหาอาหารในตำนานจากไม้จิ้มฟัน",
  "เอาจริงๆ เหรอเนี่ย! ลูกค้ากำลังฝึกช้างน้อยให้เต้นรำเรียกอาหาร",
  "แจ้งเตือนฉุกเฉิน! ลูกค้าเริ่มเขียนตำนานผีปอบกินอาหารช้าด้วยซอสบนโต๊ะ",
  "ด่วนจี๊ดๆ! ลูกค้ากำลังสร้างเครื่องย่นเวลาจากเศษผักในจาน",
  "รีบมาเร็วๆ นะ! ลูกค้าเริ่มสานไซดักปลาจากหลอดกาแฟเพื่อจับพ่อครัวที่ทำอาหารช้า",
  "ด่วนที่สุด! ลูกค้ากำลังปั้นรูปวัดพระแก้วจากก้อนน้ำแข็งในแก้วน้ำ",
  "รีบมาเร็ว! ลูกค้าเริ่มซ้อมร้องเพลงชาติรออาหารมาถึง",
  "ไม่น่าเชื่อ! ลูกค้ากำลังสร้างเรือดำน้ำจำลองจากทิชชู่เปียกบนโต๊ะ",
  "ด่วนจ้า! ลูกค้ากำลังแกะสลักหน้าผาโมอายจากเนื้อหมูในจาน",
  "บอกแล้วนะ! ลูกค้ากำลังปั้นรูปหลวงพ่อโตจากเส้นหมี่กึ่งสำเร็จรูป",
  "ไม่น่าเชื่อ! ลูกค้าเอาหลอดกาแฟมาสร้างเครือข่ายโทรศัพท์ในร้าน",
  "รีบมาเร็ว! ลูกค้ากำลังเลี้ยงปลากัดในน้ำแก้วเพื่อรออาหาร",
  "แปลกแต่จริง! ลูกค้ากำลังทอผ้าจากเส้นบะหมี่ในจาน",
  "ด่วนมาก! ลูกค้าเริ่มฝึกโยคะขั้นสูงระหว่างรออาหาร",
  "แย่แล้ว! ลูกค้ากำลังแกะสลักต้นไม้จากก้อนน้ำแข็งในแก้ว",
  "รีบหน่อย! ลูกค้ากำลังปั้นรูปเจดีย์จากเม็ดข้าวที่เหลือในจาน",
  "ไม่น่าเชื่อ! ลูกค้าเริ่มสอนเด็กในร้านเรื่องประวัติศาสตร์อาหารไทย",
  "ด่วนจี๊ด! ลูกค้ากำลังพับกระดาษทิชชู่เป็นรูปสัตว์ระหว่างรออาหาร",
  "รีบมาด่วน! ลูกค้ากำลังซ้อมเป่าขลุ่ยเพื่อเรียกอาหาร",
  "โอ้โห! ลูกค้ากำลังตั้งโรงละครหุ่นจากตะเกียบและช้อนส้อม",
  "แย่แล้ว! ลูกค้าเริ่มแกะสลักรูปหมาจากมันฝรั่งทอด",
  "ด่วนที่สุด! ลูกค้ากำลังสร้างเมืองจำลองจากเม็ดพริกบนโต๊ะ",
  "บอกไม่เชื่อ! ลูกค้ากำลังสร้างนาฬิกาจากเส้นข้าวซอยในจาน",
  "รีบมาเร็วที่สุด! ลูกค้ากำลังวาดแผนที่โลกจากซอสบนโต๊ะ",
  "ไม่น่าเชื่อ! ลูกค้ากำลังเขียนบทกวีเกี่ยวกับอาหารช้าที่ร้าน",
  "เอาจริงละนะ! ลูกค้ากำลังเขียนบทละครเรื่อง 'แม่การะเกดรออาหาร' บนผ้าเช็ดปาก"
];

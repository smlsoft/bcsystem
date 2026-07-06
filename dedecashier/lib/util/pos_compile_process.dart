import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_process.dart';

Future<PosProcessResultModel> posCompileProcess({required String holdCode, required int docMode, required String detailDiscountFormula, required bool cashRoundAmount, required bool discountFoodOnly, required String customermode}) async {
  PosProcessResultModel processResult = PosProcessResultModel();
  {
    // คำนวณของ Terminal หลัก
    PosProcess posProcess = PosProcess();
    int holdIndex = global.findPosHoldProcessResultIndex(holdCode);
    if (holdIndex != -1) {
      global.posHoldProcessResult[global.findPosHoldProcessResultIndex(holdCode)].posProcess =
          await posProcess.process(holdCode: holdCode, docMode: docMode, detailDiscountFormula: detailDiscountFormula, discountFormula: "", discountFoodOnly: discountFoodOnly, cashRoundAmount: cashRoundAmount);
      posProcess.sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(holdCode)].posProcess);
      processResult = posProcess.result;
    }
  }
  {
    // คำนวณของ Client
    for (int index = 0; index < global.posRemoteDeviceList.length; index++) {
      if (global.posRemoteDeviceList[index].processSuccess == false) {
        String getHoldCode = global.posRemoteDeviceList[index].holdCodeActive!;
        int getDocMode = global.posRemoteDeviceList[index].docModeActive!;
        if (holdCode != getHoldCode) {
          int holdIndex = global.findPosHoldProcessResultIndex(getHoldCode);
          if (holdIndex != -1) {
            PosProcess posProcess = PosProcess();
            global.posHoldProcessResult[global.findPosHoldProcessResultIndex(getHoldCode)].posProcess =
                await posProcess.process(holdCode: getHoldCode, docMode: getDocMode, detailDiscountFormula: "", discountFormula: "", discountFoodOnly: discountFoodOnly, cashRoundAmount: cashRoundAmount);
            posProcess.sumCategoryCount(value: global.posHoldProcessResult[global.findPosHoldProcessResultIndex(getHoldCode)].posProcess);
          }
        }
        global.posRemoteDeviceList[index].processSuccess = true;
      }
    }
  }
  // ส่งข้อมูลไปยังจอแสดงผลลูกค้า
  global.activeCustomerDisplayScreen = customermode;

  global.sendProcessToCustomerDisplay(mode: customermode);

  global.sendProcessToRemote();

  return processResult;
}

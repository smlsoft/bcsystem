class PrinterDeviceModel {
  String fullName;
  String productName;
  String deviceName;
  String deviceId;
  String manufacturer;
  String vendorId;
  String productId;
  String ipAddress;
  int ipPort;
  int connectType;
  int printerType;
  // 1 = 58mm, 2 = 80mm
  int paperSize;

  PrinterDeviceModel(
      {this.fullName = "",
      this.productName = "",
      this.deviceName = "",
      this.deviceId = "",
      this.manufacturer = "",
      this.productId = "",
      this.vendorId = "",
      this.ipAddress = "",
      this.ipPort = 0,
      this.paperSize = 0,
      this.printerType = 0,
      this.connectType = 0});
}

import 'package:smlaicloud/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:smlaicloud/model/cart_model.dart';
import 'package:smlaicloud/model/location_model.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/model/warehouse_model.dart';
import 'package:smlaicloud/utils/cart_websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:intl/intl.dart';

class CartListSearchScreen extends StatefulWidget {
  final Function(List<TransactionDetailModel>, String cartId)? onCartSelected;

  const CartListSearchScreen({
    super.key,
    this.onCartSelected,
  });

  @override
  _CartListSearchScreenState createState() => _CartListSearchScreenState();
}

class _CartListSearchScreenState extends State<CartListSearchScreen> {
  // ใช้บริการ WebSocket แทนการสร้างใหม่
  final CartWebSocketService _cartService = CartWebSocketService();

  List<CartModel> carts = [];
  bool isLoading = true;
  String? clientId;

  late List<TransactionDetailModel> details = [];
  List<CartItem> cartItems = [];
  WarehouseModel? _currentWarehouse;
  LocationModel? _currentLocation;
  WarehouseModel? _currentDestWarehouse;
  LocationModel? _currentDestLocation;
  String cartName = '';
  String cartId = "";

  ScrollController listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // ตั้งค่า callback สำหรับ CartWebSocketService
    _cartService.initialize(
      onCartListReceived: _handleCartListReceived,
      onCartDetailsReceived: _handleCartDetailsReceived,
      onClientIdReceived: _handleClientIdReceived,
      onConnectionChanged: _handleConnectionChanged,
      onError: _handleError,
    );

    // เชื่อมต่อกับ WebSocket
    _connectToServer();

    // เพิ่ม listener สำหรับ scroll
    listScrollController.addListener(onScrollList);
  }

  @override
  void dispose() {
    listScrollController.dispose();
    super.dispose();
  }

  // Callbacks สำหรับ CartWebSocketService
  void _handleCartListReceived(List<CartModel> receivedCarts) {
    if (mounted) {
      setState(() {
        carts = receivedCarts;
        isLoading = false;
      });
    }
  }

  void _handleCartDetailsReceived(String receivedCartName, String receivedCartId, Map<String, dynamic> itemDetailsMap, WarehouseModel currentWarehouse, LocationModel currentLocation,
      WarehouseModel currentDestWarehouse, LocationModel currentDestLocation) {
    if (mounted) {
      setState(() {
        cartName = receivedCartName;
        cartId = receivedCartId;
        _currentWarehouse = currentWarehouse;
        _currentLocation = currentLocation;
        _currentDestWarehouse = currentDestWarehouse;
        _currentDestLocation = currentDestLocation;

        // แปลง map เป็น list ของ cart items
        cartItems = itemDetailsMap.values.map((json) => CartItem.fromJson(json as Map<String, dynamic>)).toList();
      });

      // สร้าง list barcode จากข้อมูล cart details
      List<String> barcodes = itemDetailsMap.values.map((item) => (item as Map<String, dynamic>)['barcode']?.toString() ?? '').where((barcode) => barcode.isNotEmpty).toList();

      // ส่ง event ไปยัง bloc
      context.read<ProductBarcodeBloc>().add(ProductBarcodeGetByBarcodeList(barcodes: barcodes));
    }
  }

  void _handleClientIdReceived(String receivedClientId) {
    if (mounted) {
      setState(() {
        clientId = receivedClientId;
      });
    }
  }

  void _handleConnectionChanged(bool connected) {
    if (mounted) {
      setState(() {
        isLoading = !connected;
      });
    }
  }

  void _handleError(String errorMessage) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _connectToServer() async {
    bool connected = await _cartService.connect(context);
    if (connected) {
      _requestCartList();
    }
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      // เพิ่มฟังก์ชันโหลดข้อมูลเพิ่มเติมหากต้องการ pagination
    }
  }

  void _requestCartList() {
    setState(() => isLoading = true);
    _cartService.requestCartList(global.getShopId());
  }

  Widget _buildCartItem(CartModel cart) {
    final totalQuantity = cart.statistics!.totalQuantity;
    final uniqueItems = cart.statistics!.uniqueItems;
    final cartTransFlag = cart.cartTransFlag;
    final cartName = cart.cartName;
    final cartStatus = cart.cartStatus;
    final createAt = DateFormat('dd/MM/yyyy').format(DateTime.parse(cart.createdAt!));

    return GestureDetector(
      onTap: () async {
        if (widget.onCartSelected != null) {
          _cartService.requestCartDetails(cart.cartId!, global.getShopId());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(width: 1.0, color: Colors.grey),
          ),
        ),
        padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 - Main information (single line per column)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cart Name Column
                Expanded(
                  flex: 5,
                  child: Text(
                    cartName!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Type Column
                Expanded(
                  flex: 4,
                  child: Text(
                    global.getTransFlagText(cartTransFlag!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getTransFlagColor(cartTransFlag),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Origin Location Column
                Expanded(
                  flex: 7,
                  child: Text(
                    'คลัง: ${global.activeLangName(cart.warehouse?.names ?? [])}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Destination Location Column
                Expanded(
                  flex: 7,
                  child: cartTransFlag == 72 && cart.destWarehouse != null
                      ? Text(
                          'คลัง: ${global.activeLangName(cart.destWarehouse?.names ?? [])}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox(),
                ),

                // Quantity Column
                Expanded(
                  flex: 3,
                  child: Text(
                    '$uniqueItems รายการ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            // Row 2 - Additional information (separate columns)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cart Date Column
                  Expanded(
                    flex: 5,
                    child: Text(
                      createAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  // Cart ID Column
                  Expanded(
                    flex: 4,
                    child: Text(
                      cart.cartId!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                    ),
                  ),

                  // Origin Location Detail
                  Expanded(
                    flex: 7,
                    child: cart.location?.names != null
                        ? Text(
                            'พื้นที่: ${global.activeLangName(cart.location?.names ?? [])}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox(),
                  ),

                  // Destination Location Detail
                  Expanded(
                    flex: 7,
                    child: (cartTransFlag == 72 && cart.destLocation?.names != null)
                        ? Text(
                            'พื้นที่: ${global.activeLangName(cart.destLocation?.names ?? [])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox(),
                  ),

                  // Total Pieces Column
                  Expanded(
                    flex: 3,
                    child: Text(
                      '$totalQuantity ชิ้น',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransFlagColor(int cartTransFlag) {
    switch (cartTransFlag) {
      case 56:
        return Colors.orange;
      case 58:
        return Colors.purple;
      case 66:
        return Colors.green;
      case 72:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDisconnectedScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        title: const Text('ระบบตะกร้าสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ websocket ได้', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _connectToServer,
              child: const Text('ลองเชื่อมต่ออีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_cartService.isSocketConnected()) {
      return _buildDisconnectedScreen();
    }

    return BlocListener<ProductBarcodeBloc, ProductBarcodeState>(
      listener: (context, state) {
        if (state is ProductBarcodeGetByBarcodeListSuccess) {
          final formattedDate = DateTime.now().toUtc().toIso8601String();
          details = []; // เคลียร์ details เก่า

          // ใช้ cartItems เป็นหลักในการวนลูป
          for (var cartItem in cartItems) {
            // หา product barcode ที่ตรงกับ cartItem
            final productBarcode = state.productBarcodes.firstWhere(
              (pb) => pb.barcode == cartItem.barcode,
            );

            details.add(
              TransactionDetailModel(
                docref: cartName,
                docdatetime: formattedDate,
                docrefdatetime: formattedDate,
                itemguid: productBarcode.guidfixed,
                barcode: cartItem.barcode,
                itemcode: productBarcode.itemcode ?? "",
                itemnames: productBarcode.names,
                unitcode: cartItem.itemunitcode,
                qty: cartItem.quantity,
                price: 0,
                discount: '',
                sumofcost: 0,
                sumamount: 0,
                remark: '',
                linenumber: 0,
                whcode: _currentWarehouse!.code,
                whnames: _currentWarehouse!.names,
                shelfcode: '',
                locationcode: _currentLocation!.code,
                locationnames: _currentLocation!.names,
                totalvaluevat: 0,
                totalqty: 0,
                standvalue: productBarcode.standvalue!,
                dividevalue: productBarcode.dividevalue!,
                multiunit: true,
                unitnames: cartItem.itemunitnames,
                calcflag: 1,
                vattype: 0,
                averagecost: 0,
                sumamountexcludevat: 0,
                discountamount: 0,
                ispos: 0,
                laststatus: 0,
                itemtype: 0,
                inquirytype: 0,
                priceexcludevat: 0,
                taxtype: productBarcode.taxtype!,
                vatcal: productBarcode.vatcal,
                towhcode: _currentDestWarehouse!.code,
                towhnames: _currentDestWarehouse!.names,
                tolocationcode: _currentDestLocation!.code,
                tolocationnames: _currentDestLocation!.names,
                refbarcodes: productBarcode.refbarcodes,
                manufacturerguid: productBarcode.manufacturerguid,
                description: cartItem.description,
                imageuri: cartItem.imageuri,
              ),
            );
          }

          if (widget.onCartSelected != null) {
            widget.onCartSelected!(details, cartId);
          }
          Navigator.of(context).pop();
        } else if (state is ProductBarcodeGetByBarcodeListFailed) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถดึงข้อมูลได้ ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: global.theme.appBarColor,
          title: const Text('ตะกร้าสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _requestCartList,
              tooltip: 'รีเฟรชข้อมูล',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search container
            Container(
              padding: const EdgeInsets.all(5),
              color: global.theme.appBarColor,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(top: 10, bottom: 10),
                          border: InputBorder.none,
                          hintText: 'ค้นหา',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Table header
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              decoration: BoxDecoration(
                  color: global.theme.columnHeaderColor,
                  border: const Border(
                    bottom: BorderSide(width: 1.0, color: Colors.grey),
                  )),
              child: Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'ชื่อตะกร้า',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(
                    flex: 4,
                    child: Text(
                      'ประเภท',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(
                    flex: 7,
                    child: Text(
                      'ต้นทาง',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(
                    flex: 7,
                    child: Text(
                      'ปลายทาง',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'จำนวน',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // List or loading indicator
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : RefreshIndicator(
                      color: Colors.blue,
                      backgroundColor: Colors.white,
                      strokeWidth: 3.0,
                      onRefresh: () async {
                        _requestCartList();
                      },
                      child: carts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: carts.length,
                              controller: listScrollController,
                              itemBuilder: (context, index) {
                                return _buildCartItem(carts[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบรายการตะกร้า',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _requestCartList,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.blue,
                    size: 16,
                  ),
                  label: const Text(
                    'รีเฟรชข้อมูล',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

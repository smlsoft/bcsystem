import 'package:bloc/bloc.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:equatable/equatable.dart';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/sync/model/sync_inventory_model.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiRepository _inventoryRepository;

  InventoryBloc({required ApiRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository,
        super(InventoryInitial()) {
    on<ListInventoryLoad>(_onListInventoryLoad);
    on<ListInventoryById>(_onGetInventoryId);
  }
  void _onListInventoryLoad(ListInventoryLoad event, Emitter<InventoryState> emit) async {
    emit(InventoryInProgress());

    try {
      final result = await _inventoryRepository.getInventoryFetchUpdate(perPage: event.perPage, page: event.page, time: event.time);

      if (result.success) {
        List<SyncProductBarcodeModel> newItemBarcode = (result.data["new"] as List).map((newItem) => SyncProductBarcodeModel.fromJson(newItem)).toList();
        List<SyncProductBarcodeModel> removeItemBarcode = (result.data["remove"] as List).map((removeItem) => SyncProductBarcodeModel.fromJson(removeItem)).toList();
        serviceLocator<Log>().debug(newItemBarcode);
        serviceLocator<Log>().debug(removeItemBarcode);

        emit(InventoryLoadSuccess(newItem: newItemBarcode, removeItem: removeItemBarcode, page: result.page));
      } else {
        emit(const InventoryLoadFailed(message: 'Inventory Not Found'));
      }
    } catch (e) {
      emit(InventoryLoadFailed(message: e.toString()));
    }
  }

  void _onGetInventoryId(ListInventoryById event, Emitter<InventoryState> emit) async {
    emit(InventorySearchInProgress());
    try {
      final result = await _inventoryRepository.getInventoryId(event.id);

      if (result.success) {
        SyncProductBarcodeModel inventory = SyncProductBarcodeModel.fromJson(result.data);
        serviceLocator<Log>().debug(inventory);
        emit(InventorySearchLoadSuccess(inventory: inventory));
      } else {
        emit(const InventorySearchLoadFailed(message: 'Product Not Found'));
      }
    } catch (e) {
      emit(InventorySearchLoadFailed(message: e.toString()));
    }
  }
}

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class ListInventoryLoad extends InventoryEvent {
  final int page;
  final int perPage;
  final String time;

  const ListInventoryLoad({required this.page, required this.perPage, required this.time});

  @override
  List<Object> get props => [];
}

class ListInventoryById extends InventoryEvent {
  final String id;

  const ListInventoryById({required this.id});

  @override
  List<Object> get props => [];
}

class InventorySaved extends InventoryEvent {
  final SyncProductBarcodeModel inventory;

  const InventorySaved({
    required this.inventory,
  });

  @override
  List<Object> get props => [inventory];
}

class InventoryUpdate extends InventoryEvent {
  final SyncProductBarcodeModel inventory;

  const InventoryUpdate({
    required this.inventory,
  });

  @override
  List<Object> get props => [inventory];
}

class InventoryDelete extends InventoryEvent {
  final String id;

  const InventoryDelete({
    required this.id,
  });

  @override
  List<Object> get props => [id];
}

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

//Load

class InventoryInitial extends InventoryState {}

class InventoryInProgress extends InventoryState {}

class InventoryLoadSuccess extends InventoryState {
  final List<SyncProductBarcodeModel> newItem;
  final List<SyncProductBarcodeModel> removeItem;
  final Pages? page;

  const InventoryLoadSuccess({required this.newItem, required this.removeItem, required this.page});

  InventoryLoadSuccess copyWith({
    List<SyncProductBarcodeModel>? newItem,
    List<SyncProductBarcodeModel>? removeItem,
    final Pages? page,
  }) =>
      InventoryLoadSuccess(
        newItem: newItem ?? this.newItem,
        removeItem: removeItem ?? this.removeItem,
        page: page ?? this.page,
      );

  @override
  List<Object> get props => [newItem, removeItem];
}

class InventoryLoadFailed extends InventoryState {
  final String message;
  const InventoryLoadFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

//Search

class InventorySearchInProgress extends InventoryState {}

class InventorySearchLoadSuccess extends InventoryState {
  final SyncProductBarcodeModel inventory;

  const InventorySearchLoadSuccess({
    required this.inventory,
  });

  @override
  List<Object> get props => [inventory];
}

class InventorySearchLoadFailed extends InventoryState {
  final String message;
  const InventorySearchLoadFailed({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

//save
class InventoryFormInitial extends InventoryState {}

class InventoryFormSaveInProgress extends InventoryState {}

class InventoryFormSaveSuccess extends InventoryState {}

class InventoryFormSaveFailure extends InventoryState {
  final String message;
  const InventoryFormSaveFailure({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

// upgrade
class InventoryUpdateInitial extends InventoryState {}

class InventoryUpdateInProgress extends InventoryState {}

class InventoryUpdateSuccess extends InventoryState {}

class InventoryUpdateFailure extends InventoryState {
  final String message;
  const InventoryUpdateFailure({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

// Delete
class InventoryDeleteInitial extends InventoryState {}

class InventoryDeleteInProgress extends InventoryState {}

class InventoryDeleteSuccess extends InventoryState {}

class InventoryDeleteFailure extends InventoryState {
  final String message;
  const InventoryDeleteFailure({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

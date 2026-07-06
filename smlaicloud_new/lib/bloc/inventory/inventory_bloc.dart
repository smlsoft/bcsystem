import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smlaicloud/repositories/client.dart';
import 'package:smlaicloud/repositories/inventory_repository.dart';
import 'package:smlaicloud/model/inventory_model.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _inventoryRepository;

  InventoryBloc({required InventoryRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository,
        super(InventoryInitial()) {
    on<ListInventoryLoad>(_onListInventoryLoad);
    on<ListInventoryById>(_onGetInventoryId);
    on<InventorySaved>(_onInventorySaved);
    on<InventoryUpdate>(_onInventoryUpdate);
    on<InventoryDelete>(_onInventoryDelete);
  }
  void _onListInventoryLoad(ListInventoryLoad event, Emitter<InventoryState> emit) async {
    InventoryLoadSuccess inventoryLoadSuccess;
    List<InventoryModel> _previousInventory = [];

    if (state is InventoryLoadSuccess) {
      inventoryLoadSuccess = (state as InventoryLoadSuccess).copyWith();
      _previousInventory = inventoryLoadSuccess.inventory;
    }

    emit(InventoryInProgress());

    try {
      final _result = await _inventoryRepository.getInventoryList(perPage: event.perPage, page: event.page, search: event.search);

      if (_result.success) {
        if (event.nextPage) {
          List<InventoryModel> _inventory = (_result.data as List).map((inventory) => InventoryModel.fromJson(inventory)).toList();
          // // print(_inventory);
          emit(InventoryLoadSuccess(inventory: _inventory, page: _result.page));
        } else {
          List<InventoryModel> _inventory = (_result.data as List).map((inventory) => InventoryModel.fromJson(inventory)).toList();
          // // print(_inventory);
          _previousInventory.addAll(_inventory);
          emit(InventoryLoadSuccess(inventory: _previousInventory, page: _result.page));
        }
      } else {
        emit(InventoryLoadFailed(message: 'Invtory Not Found'));
      }
    } catch (e) {
      emit(InventoryLoadFailed(message: e.toString()));
    }
  }

  void _onGetInventoryId(ListInventoryById event, Emitter<InventoryState> emit) async {
    emit(InventorySearchInProgress());
    try {
      final _result = await _inventoryRepository.getInventoryId(event.id);

      if (_result.success) {
        InventoryModel _inventory = InventoryModel.fromJson(_result.data);
        // // print(_inventory);
        emit(InventorySearchLoadSuccess(inventory: _inventory));
      } else {
        emit(InventorySearchLoadFailed(message: 'Product Not Found'));
      }
    } catch (e) {
      emit(InventorySearchLoadFailed(message: e.toString()));
    }
  }

  void _onInventorySaved(InventorySaved event, Emitter<InventoryState> emit) async {
    emit(InventoryFormSaveInProgress());
    try {
      // // print(event.inventory.toString());

      await _inventoryRepository.saveInventory(event.inventory);

      emit(InventoryFormSaveSuccess());
    } catch (e) {
      emit(InventoryFormSaveFailure(message: e.toString()));
    }
  }

  void _onInventoryUpdate(InventoryUpdate event, Emitter<InventoryState> emit) async {
    emit(InventoryUpdateInProgress());
    try {
      // // print(event.inventory.toString());

      await _inventoryRepository.updateInventory(event.inventory);

      emit(InventoryUpdateSuccess());
    } catch (e) {
      emit(InventoryUpdateFailure(message: e.toString()));
    }
  }

  void _onInventoryDelete(InventoryDelete event, Emitter<InventoryState> emit) async {
    emit(InventoryDeleteInProgress());
    try {
      // // print(event.inventory.toString());

      await _inventoryRepository.deleteInventory(event.id);

      emit(InventoryDeleteSuccess());
    } catch (e) {
      emit(InventoryDeleteFailure(message: e.toString()));
    }
  }
}

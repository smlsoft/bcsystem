// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_summary_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SalesSummaryEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesSummaryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SalesSummaryEvent()';
}


}

/// @nodoc
class $SalesSummaryEventCopyWith<$Res>  {
$SalesSummaryEventCopyWith(SalesSummaryEvent _, $Res Function(SalesSummaryEvent) __);
}


/// Adds pattern-matching-related methods to [SalesSummaryEvent].
extension SalesSummaryEventPatterns on SalesSummaryEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadSalesSummary value)?  loadSalesSummary,TResult Function( FilterSalesByDate value)?  filterByDate,TResult Function( FilterSalesByShift value)?  filterByShift,TResult Function( ClearSalesFilters value)?  clearFilters,TResult Function( LoadShiftReports value)?  loadShiftReports,TResult Function( LoadMoneyTransferReports value)?  loadMoneyTransferReports,TResult Function( LoadPaymentReports value)?  loadPaymentReports,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadSalesSummary() when loadSalesSummary != null:
return loadSalesSummary(_that);case FilterSalesByDate() when filterByDate != null:
return filterByDate(_that);case FilterSalesByShift() when filterByShift != null:
return filterByShift(_that);case ClearSalesFilters() when clearFilters != null:
return clearFilters(_that);case LoadShiftReports() when loadShiftReports != null:
return loadShiftReports(_that);case LoadMoneyTransferReports() when loadMoneyTransferReports != null:
return loadMoneyTransferReports(_that);case LoadPaymentReports() when loadPaymentReports != null:
return loadPaymentReports(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadSalesSummary value)  loadSalesSummary,required TResult Function( FilterSalesByDate value)  filterByDate,required TResult Function( FilterSalesByShift value)  filterByShift,required TResult Function( ClearSalesFilters value)  clearFilters,required TResult Function( LoadShiftReports value)  loadShiftReports,required TResult Function( LoadMoneyTransferReports value)  loadMoneyTransferReports,required TResult Function( LoadPaymentReports value)  loadPaymentReports,}){
final _that = this;
switch (_that) {
case LoadSalesSummary():
return loadSalesSummary(_that);case FilterSalesByDate():
return filterByDate(_that);case FilterSalesByShift():
return filterByShift(_that);case ClearSalesFilters():
return clearFilters(_that);case LoadShiftReports():
return loadShiftReports(_that);case LoadMoneyTransferReports():
return loadMoneyTransferReports(_that);case LoadPaymentReports():
return loadPaymentReports(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadSalesSummary value)?  loadSalesSummary,TResult? Function( FilterSalesByDate value)?  filterByDate,TResult? Function( FilterSalesByShift value)?  filterByShift,TResult? Function( ClearSalesFilters value)?  clearFilters,TResult? Function( LoadShiftReports value)?  loadShiftReports,TResult? Function( LoadMoneyTransferReports value)?  loadMoneyTransferReports,TResult? Function( LoadPaymentReports value)?  loadPaymentReports,}){
final _that = this;
switch (_that) {
case LoadSalesSummary() when loadSalesSummary != null:
return loadSalesSummary(_that);case FilterSalesByDate() when filterByDate != null:
return filterByDate(_that);case FilterSalesByShift() when filterByShift != null:
return filterByShift(_that);case ClearSalesFilters() when clearFilters != null:
return clearFilters(_that);case LoadShiftReports() when loadShiftReports != null:
return loadShiftReports(_that);case LoadMoneyTransferReports() when loadMoneyTransferReports != null:
return loadMoneyTransferReports(_that);case LoadPaymentReports() when loadPaymentReports != null:
return loadPaymentReports(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateTime? startDate,  DateTime? endDate,  String? shiftId)?  loadSalesSummary,TResult Function( DateTime startDate,  DateTime endDate)?  filterByDate,TResult Function( String shiftId)?  filterByShift,TResult Function()?  clearFilters,TResult Function( DateTime? startDate,  DateTime? endDate)?  loadShiftReports,TResult Function( DateTime? startDate,  DateTime? endDate)?  loadMoneyTransferReports,TResult Function( DateTime? startDate,  DateTime? endDate)?  loadPaymentReports,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadSalesSummary() when loadSalesSummary != null:
return loadSalesSummary(_that.startDate,_that.endDate,_that.shiftId);case FilterSalesByDate() when filterByDate != null:
return filterByDate(_that.startDate,_that.endDate);case FilterSalesByShift() when filterByShift != null:
return filterByShift(_that.shiftId);case ClearSalesFilters() when clearFilters != null:
return clearFilters();case LoadShiftReports() when loadShiftReports != null:
return loadShiftReports(_that.startDate,_that.endDate);case LoadMoneyTransferReports() when loadMoneyTransferReports != null:
return loadMoneyTransferReports(_that.startDate,_that.endDate);case LoadPaymentReports() when loadPaymentReports != null:
return loadPaymentReports(_that.startDate,_that.endDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateTime? startDate,  DateTime? endDate,  String? shiftId)  loadSalesSummary,required TResult Function( DateTime startDate,  DateTime endDate)  filterByDate,required TResult Function( String shiftId)  filterByShift,required TResult Function()  clearFilters,required TResult Function( DateTime? startDate,  DateTime? endDate)  loadShiftReports,required TResult Function( DateTime? startDate,  DateTime? endDate)  loadMoneyTransferReports,required TResult Function( DateTime? startDate,  DateTime? endDate)  loadPaymentReports,}) {final _that = this;
switch (_that) {
case LoadSalesSummary():
return loadSalesSummary(_that.startDate,_that.endDate,_that.shiftId);case FilterSalesByDate():
return filterByDate(_that.startDate,_that.endDate);case FilterSalesByShift():
return filterByShift(_that.shiftId);case ClearSalesFilters():
return clearFilters();case LoadShiftReports():
return loadShiftReports(_that.startDate,_that.endDate);case LoadMoneyTransferReports():
return loadMoneyTransferReports(_that.startDate,_that.endDate);case LoadPaymentReports():
return loadPaymentReports(_that.startDate,_that.endDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateTime? startDate,  DateTime? endDate,  String? shiftId)?  loadSalesSummary,TResult? Function( DateTime startDate,  DateTime endDate)?  filterByDate,TResult? Function( String shiftId)?  filterByShift,TResult? Function()?  clearFilters,TResult? Function( DateTime? startDate,  DateTime? endDate)?  loadShiftReports,TResult? Function( DateTime? startDate,  DateTime? endDate)?  loadMoneyTransferReports,TResult? Function( DateTime? startDate,  DateTime? endDate)?  loadPaymentReports,}) {final _that = this;
switch (_that) {
case LoadSalesSummary() when loadSalesSummary != null:
return loadSalesSummary(_that.startDate,_that.endDate,_that.shiftId);case FilterSalesByDate() when filterByDate != null:
return filterByDate(_that.startDate,_that.endDate);case FilterSalesByShift() when filterByShift != null:
return filterByShift(_that.shiftId);case ClearSalesFilters() when clearFilters != null:
return clearFilters();case LoadShiftReports() when loadShiftReports != null:
return loadShiftReports(_that.startDate,_that.endDate);case LoadMoneyTransferReports() when loadMoneyTransferReports != null:
return loadMoneyTransferReports(_that.startDate,_that.endDate);case LoadPaymentReports() when loadPaymentReports != null:
return loadPaymentReports(_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc


class LoadSalesSummary implements SalesSummaryEvent {
  const LoadSalesSummary({this.startDate, this.endDate, this.shiftId});
  

 final  DateTime? startDate;
 final  DateTime? endDate;
 final  String? shiftId;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadSalesSummaryCopyWith<LoadSalesSummary> get copyWith => _$LoadSalesSummaryCopyWithImpl<LoadSalesSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadSalesSummary&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,shiftId);

@override
String toString() {
  return 'SalesSummaryEvent.loadSalesSummary(startDate: $startDate, endDate: $endDate, shiftId: $shiftId)';
}


}

/// @nodoc
abstract mixin class $LoadSalesSummaryCopyWith<$Res> implements $SalesSummaryEventCopyWith<$Res> {
  factory $LoadSalesSummaryCopyWith(LoadSalesSummary value, $Res Function(LoadSalesSummary) _then) = _$LoadSalesSummaryCopyWithImpl;
@useResult
$Res call({
 DateTime? startDate, DateTime? endDate, String? shiftId
});




}
/// @nodoc
class _$LoadSalesSummaryCopyWithImpl<$Res>
    implements $LoadSalesSummaryCopyWith<$Res> {
  _$LoadSalesSummaryCopyWithImpl(this._self, this._then);

  final LoadSalesSummary _self;
  final $Res Function(LoadSalesSummary) _then;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? shiftId = freezed,}) {
  return _then(LoadSalesSummary(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,shiftId: freezed == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class FilterSalesByDate implements SalesSummaryEvent {
  const FilterSalesByDate({required this.startDate, required this.endDate});
  

 final  DateTime startDate;
 final  DateTime endDate;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterSalesByDateCopyWith<FilterSalesByDate> get copyWith => _$FilterSalesByDateCopyWithImpl<FilterSalesByDate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterSalesByDate&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'SalesSummaryEvent.filterByDate(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $FilterSalesByDateCopyWith<$Res> implements $SalesSummaryEventCopyWith<$Res> {
  factory $FilterSalesByDateCopyWith(FilterSalesByDate value, $Res Function(FilterSalesByDate) _then) = _$FilterSalesByDateCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, DateTime endDate
});




}
/// @nodoc
class _$FilterSalesByDateCopyWithImpl<$Res>
    implements $FilterSalesByDateCopyWith<$Res> {
  _$FilterSalesByDateCopyWithImpl(this._self, this._then);

  final FilterSalesByDate _self;
  final $Res Function(FilterSalesByDate) _then;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,}) {
  return _then(FilterSalesByDate(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class FilterSalesByShift implements SalesSummaryEvent {
  const FilterSalesByShift({required this.shiftId});
  

 final  String shiftId;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterSalesByShiftCopyWith<FilterSalesByShift> get copyWith => _$FilterSalesByShiftCopyWithImpl<FilterSalesByShift>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterSalesByShift&&(identical(other.shiftId, shiftId) || other.shiftId == shiftId));
}


@override
int get hashCode => Object.hash(runtimeType,shiftId);

@override
String toString() {
  return 'SalesSummaryEvent.filterByShift(shiftId: $shiftId)';
}


}

/// @nodoc
abstract mixin class $FilterSalesByShiftCopyWith<$Res> implements $SalesSummaryEventCopyWith<$Res> {
  factory $FilterSalesByShiftCopyWith(FilterSalesByShift value, $Res Function(FilterSalesByShift) _then) = _$FilterSalesByShiftCopyWithImpl;
@useResult
$Res call({
 String shiftId
});




}
/// @nodoc
class _$FilterSalesByShiftCopyWithImpl<$Res>
    implements $FilterSalesByShiftCopyWith<$Res> {
  _$FilterSalesByShiftCopyWithImpl(this._self, this._then);

  final FilterSalesByShift _self;
  final $Res Function(FilterSalesByShift) _then;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shiftId = null,}) {
  return _then(FilterSalesByShift(
shiftId: null == shiftId ? _self.shiftId : shiftId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ClearSalesFilters implements SalesSummaryEvent {
  const ClearSalesFilters();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClearSalesFilters);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SalesSummaryEvent.clearFilters()';
}


}




/// @nodoc


class LoadShiftReports implements SalesSummaryEvent {
  const LoadShiftReports({this.startDate, this.endDate});
  

 final  DateTime? startDate;
 final  DateTime? endDate;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadShiftReportsCopyWith<LoadShiftReports> get copyWith => _$LoadShiftReportsCopyWithImpl<LoadShiftReports>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadShiftReports&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'SalesSummaryEvent.loadShiftReports(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $LoadShiftReportsCopyWith<$Res> implements $SalesSummaryEventCopyWith<$Res> {
  factory $LoadShiftReportsCopyWith(LoadShiftReports value, $Res Function(LoadShiftReports) _then) = _$LoadShiftReportsCopyWithImpl;
@useResult
$Res call({
 DateTime? startDate, DateTime? endDate
});




}
/// @nodoc
class _$LoadShiftReportsCopyWithImpl<$Res>
    implements $LoadShiftReportsCopyWith<$Res> {
  _$LoadShiftReportsCopyWithImpl(this._self, this._then);

  final LoadShiftReports _self;
  final $Res Function(LoadShiftReports) _then;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(LoadShiftReports(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class LoadMoneyTransferReports implements SalesSummaryEvent {
  const LoadMoneyTransferReports({this.startDate, this.endDate});
  

 final  DateTime? startDate;
 final  DateTime? endDate;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadMoneyTransferReportsCopyWith<LoadMoneyTransferReports> get copyWith => _$LoadMoneyTransferReportsCopyWithImpl<LoadMoneyTransferReports>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadMoneyTransferReports&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'SalesSummaryEvent.loadMoneyTransferReports(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $LoadMoneyTransferReportsCopyWith<$Res> implements $SalesSummaryEventCopyWith<$Res> {
  factory $LoadMoneyTransferReportsCopyWith(LoadMoneyTransferReports value, $Res Function(LoadMoneyTransferReports) _then) = _$LoadMoneyTransferReportsCopyWithImpl;
@useResult
$Res call({
 DateTime? startDate, DateTime? endDate
});




}
/// @nodoc
class _$LoadMoneyTransferReportsCopyWithImpl<$Res>
    implements $LoadMoneyTransferReportsCopyWith<$Res> {
  _$LoadMoneyTransferReportsCopyWithImpl(this._self, this._then);

  final LoadMoneyTransferReports _self;
  final $Res Function(LoadMoneyTransferReports) _then;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(LoadMoneyTransferReports(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class LoadPaymentReports implements SalesSummaryEvent {
  const LoadPaymentReports({this.startDate, this.endDate});
  

 final  DateTime? startDate;
 final  DateTime? endDate;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadPaymentReportsCopyWith<LoadPaymentReports> get copyWith => _$LoadPaymentReportsCopyWithImpl<LoadPaymentReports>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadPaymentReports&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'SalesSummaryEvent.loadPaymentReports(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $LoadPaymentReportsCopyWith<$Res> implements $SalesSummaryEventCopyWith<$Res> {
  factory $LoadPaymentReportsCopyWith(LoadPaymentReports value, $Res Function(LoadPaymentReports) _then) = _$LoadPaymentReportsCopyWithImpl;
@useResult
$Res call({
 DateTime? startDate, DateTime? endDate
});




}
/// @nodoc
class _$LoadPaymentReportsCopyWithImpl<$Res>
    implements $LoadPaymentReportsCopyWith<$Res> {
  _$LoadPaymentReportsCopyWithImpl(this._self, this._then);

  final LoadPaymentReports _self;
  final $Res Function(LoadPaymentReports) _then;

/// Create a copy of SalesSummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(LoadPaymentReports(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$SalesSummaryState {

// === Shared Filters ===
 DateTime? get startDate; DateTime? get endDate; String? get selectedShiftId; String? get errorMessage;// === Tab 1: Sales Report ===
 List<BillObjectBoxStruct> get salesData; List<ShiftObjectBoxStruct> get shifts; Map<String, ShiftObjectBoxStruct> get shiftCloseMap; double get totalAmount; int get totalTransactions; bool get isLoadingSalesReport; bool get isSalesReportLoaded;// === Tab 2: Shift Reports ===
 List<ShiftReportModel> get shiftReports; bool get isLoadingShiftReports; bool get isShiftReportsLoaded;// === Tab 3: Money Transfer ===
 List<ShiftObjectBoxStruct> get moneyTransferReports; bool get isLoadingMoneyTransfer; bool get isMoneyTransferLoaded;// === Tab 4: Payment Reports ===
 List<BillObjectBoxStruct> get salesTransactions; bool get isLoadingPaymentReports; bool get isPaymentReportsLoaded;
/// Create a copy of SalesSummaryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesSummaryStateCopyWith<SalesSummaryState> get copyWith => _$SalesSummaryStateCopyWithImpl<SalesSummaryState>(this as SalesSummaryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesSummaryState&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.selectedShiftId, selectedShiftId) || other.selectedShiftId == selectedShiftId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.salesData, salesData)&&const DeepCollectionEquality().equals(other.shifts, shifts)&&const DeepCollectionEquality().equals(other.shiftCloseMap, shiftCloseMap)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.totalTransactions, totalTransactions) || other.totalTransactions == totalTransactions)&&(identical(other.isLoadingSalesReport, isLoadingSalesReport) || other.isLoadingSalesReport == isLoadingSalesReport)&&(identical(other.isSalesReportLoaded, isSalesReportLoaded) || other.isSalesReportLoaded == isSalesReportLoaded)&&const DeepCollectionEquality().equals(other.shiftReports, shiftReports)&&(identical(other.isLoadingShiftReports, isLoadingShiftReports) || other.isLoadingShiftReports == isLoadingShiftReports)&&(identical(other.isShiftReportsLoaded, isShiftReportsLoaded) || other.isShiftReportsLoaded == isShiftReportsLoaded)&&const DeepCollectionEquality().equals(other.moneyTransferReports, moneyTransferReports)&&(identical(other.isLoadingMoneyTransfer, isLoadingMoneyTransfer) || other.isLoadingMoneyTransfer == isLoadingMoneyTransfer)&&(identical(other.isMoneyTransferLoaded, isMoneyTransferLoaded) || other.isMoneyTransferLoaded == isMoneyTransferLoaded)&&const DeepCollectionEquality().equals(other.salesTransactions, salesTransactions)&&(identical(other.isLoadingPaymentReports, isLoadingPaymentReports) || other.isLoadingPaymentReports == isLoadingPaymentReports)&&(identical(other.isPaymentReportsLoaded, isPaymentReportsLoaded) || other.isPaymentReportsLoaded == isPaymentReportsLoaded));
}


@override
int get hashCode => Object.hashAll([runtimeType,startDate,endDate,selectedShiftId,errorMessage,const DeepCollectionEquality().hash(salesData),const DeepCollectionEquality().hash(shifts),const DeepCollectionEquality().hash(shiftCloseMap),totalAmount,totalTransactions,isLoadingSalesReport,isSalesReportLoaded,const DeepCollectionEquality().hash(shiftReports),isLoadingShiftReports,isShiftReportsLoaded,const DeepCollectionEquality().hash(moneyTransferReports),isLoadingMoneyTransfer,isMoneyTransferLoaded,const DeepCollectionEquality().hash(salesTransactions),isLoadingPaymentReports,isPaymentReportsLoaded]);

@override
String toString() {
  return 'SalesSummaryState(startDate: $startDate, endDate: $endDate, selectedShiftId: $selectedShiftId, errorMessage: $errorMessage, salesData: $salesData, shifts: $shifts, shiftCloseMap: $shiftCloseMap, totalAmount: $totalAmount, totalTransactions: $totalTransactions, isLoadingSalesReport: $isLoadingSalesReport, isSalesReportLoaded: $isSalesReportLoaded, shiftReports: $shiftReports, isLoadingShiftReports: $isLoadingShiftReports, isShiftReportsLoaded: $isShiftReportsLoaded, moneyTransferReports: $moneyTransferReports, isLoadingMoneyTransfer: $isLoadingMoneyTransfer, isMoneyTransferLoaded: $isMoneyTransferLoaded, salesTransactions: $salesTransactions, isLoadingPaymentReports: $isLoadingPaymentReports, isPaymentReportsLoaded: $isPaymentReportsLoaded)';
}


}

/// @nodoc
abstract mixin class $SalesSummaryStateCopyWith<$Res>  {
  factory $SalesSummaryStateCopyWith(SalesSummaryState value, $Res Function(SalesSummaryState) _then) = _$SalesSummaryStateCopyWithImpl;
@useResult
$Res call({
 DateTime? startDate, DateTime? endDate, String? selectedShiftId, String? errorMessage, List<BillObjectBoxStruct> salesData, List<ShiftObjectBoxStruct> shifts, Map<String, ShiftObjectBoxStruct> shiftCloseMap, double totalAmount, int totalTransactions, bool isLoadingSalesReport, bool isSalesReportLoaded, List<ShiftReportModel> shiftReports, bool isLoadingShiftReports, bool isShiftReportsLoaded, List<ShiftObjectBoxStruct> moneyTransferReports, bool isLoadingMoneyTransfer, bool isMoneyTransferLoaded, List<BillObjectBoxStruct> salesTransactions, bool isLoadingPaymentReports, bool isPaymentReportsLoaded
});




}
/// @nodoc
class _$SalesSummaryStateCopyWithImpl<$Res>
    implements $SalesSummaryStateCopyWith<$Res> {
  _$SalesSummaryStateCopyWithImpl(this._self, this._then);

  final SalesSummaryState _self;
  final $Res Function(SalesSummaryState) _then;

/// Create a copy of SalesSummaryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? selectedShiftId = freezed,Object? errorMessage = freezed,Object? salesData = null,Object? shifts = null,Object? shiftCloseMap = null,Object? totalAmount = null,Object? totalTransactions = null,Object? isLoadingSalesReport = null,Object? isSalesReportLoaded = null,Object? shiftReports = null,Object? isLoadingShiftReports = null,Object? isShiftReportsLoaded = null,Object? moneyTransferReports = null,Object? isLoadingMoneyTransfer = null,Object? isMoneyTransferLoaded = null,Object? salesTransactions = null,Object? isLoadingPaymentReports = null,Object? isPaymentReportsLoaded = null,}) {
  return _then(_self.copyWith(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedShiftId: freezed == selectedShiftId ? _self.selectedShiftId : selectedShiftId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,salesData: null == salesData ? _self.salesData : salesData // ignore: cast_nullable_to_non_nullable
as List<BillObjectBoxStruct>,shifts: null == shifts ? _self.shifts : shifts // ignore: cast_nullable_to_non_nullable
as List<ShiftObjectBoxStruct>,shiftCloseMap: null == shiftCloseMap ? _self.shiftCloseMap : shiftCloseMap // ignore: cast_nullable_to_non_nullable
as Map<String, ShiftObjectBoxStruct>,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,totalTransactions: null == totalTransactions ? _self.totalTransactions : totalTransactions // ignore: cast_nullable_to_non_nullable
as int,isLoadingSalesReport: null == isLoadingSalesReport ? _self.isLoadingSalesReport : isLoadingSalesReport // ignore: cast_nullable_to_non_nullable
as bool,isSalesReportLoaded: null == isSalesReportLoaded ? _self.isSalesReportLoaded : isSalesReportLoaded // ignore: cast_nullable_to_non_nullable
as bool,shiftReports: null == shiftReports ? _self.shiftReports : shiftReports // ignore: cast_nullable_to_non_nullable
as List<ShiftReportModel>,isLoadingShiftReports: null == isLoadingShiftReports ? _self.isLoadingShiftReports : isLoadingShiftReports // ignore: cast_nullable_to_non_nullable
as bool,isShiftReportsLoaded: null == isShiftReportsLoaded ? _self.isShiftReportsLoaded : isShiftReportsLoaded // ignore: cast_nullable_to_non_nullable
as bool,moneyTransferReports: null == moneyTransferReports ? _self.moneyTransferReports : moneyTransferReports // ignore: cast_nullable_to_non_nullable
as List<ShiftObjectBoxStruct>,isLoadingMoneyTransfer: null == isLoadingMoneyTransfer ? _self.isLoadingMoneyTransfer : isLoadingMoneyTransfer // ignore: cast_nullable_to_non_nullable
as bool,isMoneyTransferLoaded: null == isMoneyTransferLoaded ? _self.isMoneyTransferLoaded : isMoneyTransferLoaded // ignore: cast_nullable_to_non_nullable
as bool,salesTransactions: null == salesTransactions ? _self.salesTransactions : salesTransactions // ignore: cast_nullable_to_non_nullable
as List<BillObjectBoxStruct>,isLoadingPaymentReports: null == isLoadingPaymentReports ? _self.isLoadingPaymentReports : isLoadingPaymentReports // ignore: cast_nullable_to_non_nullable
as bool,isPaymentReportsLoaded: null == isPaymentReportsLoaded ? _self.isPaymentReportsLoaded : isPaymentReportsLoaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesSummaryState].
extension SalesSummaryStatePatterns on SalesSummaryState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesSummaryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesSummaryState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesSummaryState value)  $default,){
final _that = this;
switch (_that) {
case _SalesSummaryState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesSummaryState value)?  $default,){
final _that = this;
switch (_that) {
case _SalesSummaryState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? startDate,  DateTime? endDate,  String? selectedShiftId,  String? errorMessage,  List<BillObjectBoxStruct> salesData,  List<ShiftObjectBoxStruct> shifts,  Map<String, ShiftObjectBoxStruct> shiftCloseMap,  double totalAmount,  int totalTransactions,  bool isLoadingSalesReport,  bool isSalesReportLoaded,  List<ShiftReportModel> shiftReports,  bool isLoadingShiftReports,  bool isShiftReportsLoaded,  List<ShiftObjectBoxStruct> moneyTransferReports,  bool isLoadingMoneyTransfer,  bool isMoneyTransferLoaded,  List<BillObjectBoxStruct> salesTransactions,  bool isLoadingPaymentReports,  bool isPaymentReportsLoaded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesSummaryState() when $default != null:
return $default(_that.startDate,_that.endDate,_that.selectedShiftId,_that.errorMessage,_that.salesData,_that.shifts,_that.shiftCloseMap,_that.totalAmount,_that.totalTransactions,_that.isLoadingSalesReport,_that.isSalesReportLoaded,_that.shiftReports,_that.isLoadingShiftReports,_that.isShiftReportsLoaded,_that.moneyTransferReports,_that.isLoadingMoneyTransfer,_that.isMoneyTransferLoaded,_that.salesTransactions,_that.isLoadingPaymentReports,_that.isPaymentReportsLoaded);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? startDate,  DateTime? endDate,  String? selectedShiftId,  String? errorMessage,  List<BillObjectBoxStruct> salesData,  List<ShiftObjectBoxStruct> shifts,  Map<String, ShiftObjectBoxStruct> shiftCloseMap,  double totalAmount,  int totalTransactions,  bool isLoadingSalesReport,  bool isSalesReportLoaded,  List<ShiftReportModel> shiftReports,  bool isLoadingShiftReports,  bool isShiftReportsLoaded,  List<ShiftObjectBoxStruct> moneyTransferReports,  bool isLoadingMoneyTransfer,  bool isMoneyTransferLoaded,  List<BillObjectBoxStruct> salesTransactions,  bool isLoadingPaymentReports,  bool isPaymentReportsLoaded)  $default,) {final _that = this;
switch (_that) {
case _SalesSummaryState():
return $default(_that.startDate,_that.endDate,_that.selectedShiftId,_that.errorMessage,_that.salesData,_that.shifts,_that.shiftCloseMap,_that.totalAmount,_that.totalTransactions,_that.isLoadingSalesReport,_that.isSalesReportLoaded,_that.shiftReports,_that.isLoadingShiftReports,_that.isShiftReportsLoaded,_that.moneyTransferReports,_that.isLoadingMoneyTransfer,_that.isMoneyTransferLoaded,_that.salesTransactions,_that.isLoadingPaymentReports,_that.isPaymentReportsLoaded);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? startDate,  DateTime? endDate,  String? selectedShiftId,  String? errorMessage,  List<BillObjectBoxStruct> salesData,  List<ShiftObjectBoxStruct> shifts,  Map<String, ShiftObjectBoxStruct> shiftCloseMap,  double totalAmount,  int totalTransactions,  bool isLoadingSalesReport,  bool isSalesReportLoaded,  List<ShiftReportModel> shiftReports,  bool isLoadingShiftReports,  bool isShiftReportsLoaded,  List<ShiftObjectBoxStruct> moneyTransferReports,  bool isLoadingMoneyTransfer,  bool isMoneyTransferLoaded,  List<BillObjectBoxStruct> salesTransactions,  bool isLoadingPaymentReports,  bool isPaymentReportsLoaded)?  $default,) {final _that = this;
switch (_that) {
case _SalesSummaryState() when $default != null:
return $default(_that.startDate,_that.endDate,_that.selectedShiftId,_that.errorMessage,_that.salesData,_that.shifts,_that.shiftCloseMap,_that.totalAmount,_that.totalTransactions,_that.isLoadingSalesReport,_that.isSalesReportLoaded,_that.shiftReports,_that.isLoadingShiftReports,_that.isShiftReportsLoaded,_that.moneyTransferReports,_that.isLoadingMoneyTransfer,_that.isMoneyTransferLoaded,_that.salesTransactions,_that.isLoadingPaymentReports,_that.isPaymentReportsLoaded);case _:
  return null;

}
}

}

/// @nodoc


class _SalesSummaryState implements SalesSummaryState {
  const _SalesSummaryState({this.startDate, this.endDate, this.selectedShiftId, this.errorMessage, final  List<BillObjectBoxStruct> salesData = const [], final  List<ShiftObjectBoxStruct> shifts = const [], final  Map<String, ShiftObjectBoxStruct> shiftCloseMap = const {}, this.totalAmount = 0, this.totalTransactions = 0, this.isLoadingSalesReport = false, this.isSalesReportLoaded = false, final  List<ShiftReportModel> shiftReports = const [], this.isLoadingShiftReports = false, this.isShiftReportsLoaded = false, final  List<ShiftObjectBoxStruct> moneyTransferReports = const [], this.isLoadingMoneyTransfer = false, this.isMoneyTransferLoaded = false, final  List<BillObjectBoxStruct> salesTransactions = const [], this.isLoadingPaymentReports = false, this.isPaymentReportsLoaded = false}): _salesData = salesData,_shifts = shifts,_shiftCloseMap = shiftCloseMap,_shiftReports = shiftReports,_moneyTransferReports = moneyTransferReports,_salesTransactions = salesTransactions;
  

// === Shared Filters ===
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String? selectedShiftId;
@override final  String? errorMessage;
// === Tab 1: Sales Report ===
 final  List<BillObjectBoxStruct> _salesData;
// === Tab 1: Sales Report ===
@override@JsonKey() List<BillObjectBoxStruct> get salesData {
  if (_salesData is EqualUnmodifiableListView) return _salesData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_salesData);
}

 final  List<ShiftObjectBoxStruct> _shifts;
@override@JsonKey() List<ShiftObjectBoxStruct> get shifts {
  if (_shifts is EqualUnmodifiableListView) return _shifts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shifts);
}

 final  Map<String, ShiftObjectBoxStruct> _shiftCloseMap;
@override@JsonKey() Map<String, ShiftObjectBoxStruct> get shiftCloseMap {
  if (_shiftCloseMap is EqualUnmodifiableMapView) return _shiftCloseMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_shiftCloseMap);
}

@override@JsonKey() final  double totalAmount;
@override@JsonKey() final  int totalTransactions;
@override@JsonKey() final  bool isLoadingSalesReport;
@override@JsonKey() final  bool isSalesReportLoaded;
// === Tab 2: Shift Reports ===
 final  List<ShiftReportModel> _shiftReports;
// === Tab 2: Shift Reports ===
@override@JsonKey() List<ShiftReportModel> get shiftReports {
  if (_shiftReports is EqualUnmodifiableListView) return _shiftReports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shiftReports);
}

@override@JsonKey() final  bool isLoadingShiftReports;
@override@JsonKey() final  bool isShiftReportsLoaded;
// === Tab 3: Money Transfer ===
 final  List<ShiftObjectBoxStruct> _moneyTransferReports;
// === Tab 3: Money Transfer ===
@override@JsonKey() List<ShiftObjectBoxStruct> get moneyTransferReports {
  if (_moneyTransferReports is EqualUnmodifiableListView) return _moneyTransferReports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moneyTransferReports);
}

@override@JsonKey() final  bool isLoadingMoneyTransfer;
@override@JsonKey() final  bool isMoneyTransferLoaded;
// === Tab 4: Payment Reports ===
 final  List<BillObjectBoxStruct> _salesTransactions;
// === Tab 4: Payment Reports ===
@override@JsonKey() List<BillObjectBoxStruct> get salesTransactions {
  if (_salesTransactions is EqualUnmodifiableListView) return _salesTransactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_salesTransactions);
}

@override@JsonKey() final  bool isLoadingPaymentReports;
@override@JsonKey() final  bool isPaymentReportsLoaded;

/// Create a copy of SalesSummaryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesSummaryStateCopyWith<_SalesSummaryState> get copyWith => __$SalesSummaryStateCopyWithImpl<_SalesSummaryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesSummaryState&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.selectedShiftId, selectedShiftId) || other.selectedShiftId == selectedShiftId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._salesData, _salesData)&&const DeepCollectionEquality().equals(other._shifts, _shifts)&&const DeepCollectionEquality().equals(other._shiftCloseMap, _shiftCloseMap)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.totalTransactions, totalTransactions) || other.totalTransactions == totalTransactions)&&(identical(other.isLoadingSalesReport, isLoadingSalesReport) || other.isLoadingSalesReport == isLoadingSalesReport)&&(identical(other.isSalesReportLoaded, isSalesReportLoaded) || other.isSalesReportLoaded == isSalesReportLoaded)&&const DeepCollectionEquality().equals(other._shiftReports, _shiftReports)&&(identical(other.isLoadingShiftReports, isLoadingShiftReports) || other.isLoadingShiftReports == isLoadingShiftReports)&&(identical(other.isShiftReportsLoaded, isShiftReportsLoaded) || other.isShiftReportsLoaded == isShiftReportsLoaded)&&const DeepCollectionEquality().equals(other._moneyTransferReports, _moneyTransferReports)&&(identical(other.isLoadingMoneyTransfer, isLoadingMoneyTransfer) || other.isLoadingMoneyTransfer == isLoadingMoneyTransfer)&&(identical(other.isMoneyTransferLoaded, isMoneyTransferLoaded) || other.isMoneyTransferLoaded == isMoneyTransferLoaded)&&const DeepCollectionEquality().equals(other._salesTransactions, _salesTransactions)&&(identical(other.isLoadingPaymentReports, isLoadingPaymentReports) || other.isLoadingPaymentReports == isLoadingPaymentReports)&&(identical(other.isPaymentReportsLoaded, isPaymentReportsLoaded) || other.isPaymentReportsLoaded == isPaymentReportsLoaded));
}


@override
int get hashCode => Object.hashAll([runtimeType,startDate,endDate,selectedShiftId,errorMessage,const DeepCollectionEquality().hash(_salesData),const DeepCollectionEquality().hash(_shifts),const DeepCollectionEquality().hash(_shiftCloseMap),totalAmount,totalTransactions,isLoadingSalesReport,isSalesReportLoaded,const DeepCollectionEquality().hash(_shiftReports),isLoadingShiftReports,isShiftReportsLoaded,const DeepCollectionEquality().hash(_moneyTransferReports),isLoadingMoneyTransfer,isMoneyTransferLoaded,const DeepCollectionEquality().hash(_salesTransactions),isLoadingPaymentReports,isPaymentReportsLoaded]);

@override
String toString() {
  return 'SalesSummaryState(startDate: $startDate, endDate: $endDate, selectedShiftId: $selectedShiftId, errorMessage: $errorMessage, salesData: $salesData, shifts: $shifts, shiftCloseMap: $shiftCloseMap, totalAmount: $totalAmount, totalTransactions: $totalTransactions, isLoadingSalesReport: $isLoadingSalesReport, isSalesReportLoaded: $isSalesReportLoaded, shiftReports: $shiftReports, isLoadingShiftReports: $isLoadingShiftReports, isShiftReportsLoaded: $isShiftReportsLoaded, moneyTransferReports: $moneyTransferReports, isLoadingMoneyTransfer: $isLoadingMoneyTransfer, isMoneyTransferLoaded: $isMoneyTransferLoaded, salesTransactions: $salesTransactions, isLoadingPaymentReports: $isLoadingPaymentReports, isPaymentReportsLoaded: $isPaymentReportsLoaded)';
}


}

/// @nodoc
abstract mixin class _$SalesSummaryStateCopyWith<$Res> implements $SalesSummaryStateCopyWith<$Res> {
  factory _$SalesSummaryStateCopyWith(_SalesSummaryState value, $Res Function(_SalesSummaryState) _then) = __$SalesSummaryStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime? startDate, DateTime? endDate, String? selectedShiftId, String? errorMessage, List<BillObjectBoxStruct> salesData, List<ShiftObjectBoxStruct> shifts, Map<String, ShiftObjectBoxStruct> shiftCloseMap, double totalAmount, int totalTransactions, bool isLoadingSalesReport, bool isSalesReportLoaded, List<ShiftReportModel> shiftReports, bool isLoadingShiftReports, bool isShiftReportsLoaded, List<ShiftObjectBoxStruct> moneyTransferReports, bool isLoadingMoneyTransfer, bool isMoneyTransferLoaded, List<BillObjectBoxStruct> salesTransactions, bool isLoadingPaymentReports, bool isPaymentReportsLoaded
});




}
/// @nodoc
class __$SalesSummaryStateCopyWithImpl<$Res>
    implements _$SalesSummaryStateCopyWith<$Res> {
  __$SalesSummaryStateCopyWithImpl(this._self, this._then);

  final _SalesSummaryState _self;
  final $Res Function(_SalesSummaryState) _then;

/// Create a copy of SalesSummaryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? selectedShiftId = freezed,Object? errorMessage = freezed,Object? salesData = null,Object? shifts = null,Object? shiftCloseMap = null,Object? totalAmount = null,Object? totalTransactions = null,Object? isLoadingSalesReport = null,Object? isSalesReportLoaded = null,Object? shiftReports = null,Object? isLoadingShiftReports = null,Object? isShiftReportsLoaded = null,Object? moneyTransferReports = null,Object? isLoadingMoneyTransfer = null,Object? isMoneyTransferLoaded = null,Object? salesTransactions = null,Object? isLoadingPaymentReports = null,Object? isPaymentReportsLoaded = null,}) {
  return _then(_SalesSummaryState(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedShiftId: freezed == selectedShiftId ? _self.selectedShiftId : selectedShiftId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,salesData: null == salesData ? _self._salesData : salesData // ignore: cast_nullable_to_non_nullable
as List<BillObjectBoxStruct>,shifts: null == shifts ? _self._shifts : shifts // ignore: cast_nullable_to_non_nullable
as List<ShiftObjectBoxStruct>,shiftCloseMap: null == shiftCloseMap ? _self._shiftCloseMap : shiftCloseMap // ignore: cast_nullable_to_non_nullable
as Map<String, ShiftObjectBoxStruct>,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,totalTransactions: null == totalTransactions ? _self.totalTransactions : totalTransactions // ignore: cast_nullable_to_non_nullable
as int,isLoadingSalesReport: null == isLoadingSalesReport ? _self.isLoadingSalesReport : isLoadingSalesReport // ignore: cast_nullable_to_non_nullable
as bool,isSalesReportLoaded: null == isSalesReportLoaded ? _self.isSalesReportLoaded : isSalesReportLoaded // ignore: cast_nullable_to_non_nullable
as bool,shiftReports: null == shiftReports ? _self._shiftReports : shiftReports // ignore: cast_nullable_to_non_nullable
as List<ShiftReportModel>,isLoadingShiftReports: null == isLoadingShiftReports ? _self.isLoadingShiftReports : isLoadingShiftReports // ignore: cast_nullable_to_non_nullable
as bool,isShiftReportsLoaded: null == isShiftReportsLoaded ? _self.isShiftReportsLoaded : isShiftReportsLoaded // ignore: cast_nullable_to_non_nullable
as bool,moneyTransferReports: null == moneyTransferReports ? _self._moneyTransferReports : moneyTransferReports // ignore: cast_nullable_to_non_nullable
as List<ShiftObjectBoxStruct>,isLoadingMoneyTransfer: null == isLoadingMoneyTransfer ? _self.isLoadingMoneyTransfer : isLoadingMoneyTransfer // ignore: cast_nullable_to_non_nullable
as bool,isMoneyTransferLoaded: null == isMoneyTransferLoaded ? _self.isMoneyTransferLoaded : isMoneyTransferLoaded // ignore: cast_nullable_to_non_nullable
as bool,salesTransactions: null == salesTransactions ? _self._salesTransactions : salesTransactions // ignore: cast_nullable_to_non_nullable
as List<BillObjectBoxStruct>,isLoadingPaymentReports: null == isLoadingPaymentReports ? _self.isLoadingPaymentReports : isLoadingPaymentReports // ignore: cast_nullable_to_non_nullable
as bool,isPaymentReportsLoaded: null == isPaymentReportsLoaded ? _self.isPaymentReportsLoaded : isPaymentReportsLoaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

part of 'order_template_setting_bloc.dart';

abstract class OrderTemplateSettingEvent extends Equatable {
  const OrderTemplateSettingEvent();

  @override
  List<Object> get props => [];
}

class OrderTemplateSettingGet extends OrderTemplateSettingEvent {
  final String guid;

  const OrderTemplateSettingGet({required this.guid});

  @override
  List<Object> get props => [guid];
}

class OrderTemplateSettingLoadList extends OrderTemplateSettingEvent {
  final int limit;
  final int offset;
  final String search;

  const OrderTemplateSettingLoadList({required this.offset, required this.limit, required this.search});

  @override
  List<Object> get props => [];
}

class OrderTemplateSettingDelete extends OrderTemplateSettingEvent {
  final String guid;

  const OrderTemplateSettingDelete({
    required this.guid,
  });

  @override
  List<Object> get props => [guid];
}

class OrderTemplateSettingDeleteMany extends OrderTemplateSettingEvent {
  final List<String> guid;

  const OrderTemplateSettingDeleteMany({
    required this.guid,
  });

  @override
  List<Object> get props => [guid];
}

class OrderTemplateSettingSave extends OrderTemplateSettingEvent {
  final OrderTemplateSettingModel orderTemplateSetting;

  const OrderTemplateSettingSave({
    required this.orderTemplateSetting,
  });

  @override
  List<Object> get props => [orderTemplateSetting];
}

class OrderTemplateSettingUpdate extends OrderTemplateSettingEvent {
  final String guid;
  final OrderTemplateSettingModel orderTemplateSetting;

  const OrderTemplateSettingUpdate({
    required this.guid,
    required this.orderTemplateSetting,
  });

  @override
  List<Object> get props => [orderTemplateSetting];
}

import 'package:flutter_frontend/models/contact_model.dart'; // For RelationField

class SalesOrderModel {
  final int id;
  final String? name;
  final RelationField? partnerId;
  final String? dateOrder;
  final double? amountTotal;
  final String? state;
  final String? invoiceStatus;

  SalesOrderModel({
    required this.id,
    this.name,
    this.partnerId,
    this.dateOrder,
    this.amountTotal,
    this.state,
    this.invoiceStatus,
  });

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      partnerId: json['partner_id'] != null
          ? RelationField.fromJson(json['partner_id'] as Map<String, dynamic>)
          : null,
      dateOrder: json['date_order'] as String?,
      amountTotal: (json['amount_total'] as num?)?.toDouble(),
      state: json['state'] as String?,
      invoiceStatus: json['invoice_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (partnerId != null) 'partner_id': partnerId!.toJson(),
      if (dateOrder != null) 'date_order': dateOrder,
      if (amountTotal != null) 'amount_total': amountTotal,
      if (state != null) 'state': state,
      if (invoiceStatus != null) 'invoice_status': invoiceStatus,
    };
  }
}

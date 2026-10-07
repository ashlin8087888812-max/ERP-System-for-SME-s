import 'package:flutter_frontend/models/contact_model.dart';

class InvoiceModel {
  final int id;
  final String? name;
  final RelationField? partnerId;
  final String? invoiceDate;
  final double? amountTotal;
  final String? state;
  final String? paymentState;
  final String? moveType;

  InvoiceModel({
    required this.id,
    this.name,
    this.partnerId,
    this.invoiceDate,
    this.amountTotal,
    this.state,
    this.paymentState,
    this.moveType,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      partnerId: json['partner_id'] != null
          ? RelationField.fromJson(json['partner_id'] as Map<String, dynamic>)
          : null,
      invoiceDate: json['invoice_date'] as String?,
      amountTotal: (json['amount_total'] as num?)?.toDouble(),
      state: json['state'] as String?,
      paymentState: json['payment_state'] as String?,
      moveType: json['move_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (partnerId != null) 'partner_id': partnerId!.toJson(),
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (amountTotal != null) 'amount_total': amountTotal,
      if (state != null) 'state': state,
      if (paymentState != null) 'payment_state': paymentState,
      if (moveType != null) 'move_type': moveType,
    };
  }
}

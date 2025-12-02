/// Represents a relation field from Odoo (Many2one/Many2many)
class RelationField {
  final int id;
  final String? name;
  
  RelationField({required this.id, this.name});
  
  factory RelationField.fromJson(Map<String, dynamic> json) {
    return RelationField(
      id: json['id'] as int,
      name: json['name'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {'id': id, if (name != null) 'name': name};
}

/// Contact model with comprehensive Odoo fields
class ContactModel {
  // Core Identity
  final int id;
  final String? name;
  final String? displayName;
  
  // Contact Type
  final bool isCompany;
  final String? type;
  
  // Contact Info
  final String? email;
  final String? phone;
  final String? mobile;
  final String? website;
  
  // Relationships (normalized from backend)
  final RelationField? parentId;
  final List<RelationField> childIds;
  final List<RelationField> categoryId;
  
  // Address
  final String? street;
  final String? street2;
  final String? city;
  final String? zip;
  final RelationField? stateId;
  final RelationField? countryId;
  
  // Business Info
  final String? function;
  final String? vat;
  final String? companyName;
  
  // Images
  final String? image128;
  final String? image1920;
  
  // Meta (read-only)
  final bool active;
  final String? comment;
  final String? createDate;
  final String? writeDate;
  final RelationField? createUid;
  final RelationField? writeUid;
  
  ContactModel({
    required this.id,
    this.name,
    this.displayName,
    this.isCompany = false,
    this.type,
    this.email,
    this.phone,
    this.mobile,
    this.website,
    this.parentId,
    this.childIds = const [],
    this.categoryId = const [],
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.stateId,
    this.countryId,
    this.function,
    this.vat,
    this.companyName,
    this.image128,
    this.image1920,
    this.active = true,
    this.comment,
    this.createDate,
    this.writeDate,
    this.createUid,
    this.writeUid,
  });
  
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      displayName: json['display_name'] as String?,
      isCompany: json['is_company'] as bool? ?? false,
      type: json['type'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      website: json['website'] as String?,
      parentId: json['parent_id'] != null 
        ? RelationField.fromJson(json['parent_id'] as Map<String, dynamic>) 
        : null,
      childIds: (json['child_ids'] as List<dynamic>?)
        ?.map((e) => RelationField.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
      categoryId: (json['category_id'] as List<dynamic>?)
        ?.map((e) => RelationField.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
      street: json['street'] as String?,
      street2: json['street2'] as String?,
      city: json['city'] as String?,
      zip: json['zip'] as String?,
      stateId: json['state_id'] != null
        ? RelationField.fromJson(json['state_id'] as Map<String, dynamic>)
        : null,
      countryId: json['country_id'] != null
        ? RelationField.fromJson(json['country_id'] as Map<String, dynamic>)
        : null,
      function: json['function'] as String?,
      vat: json['vat'] as String?,
      companyName: json['company_name'] as String?,
      image128: json['image_128'] as String?,
      image1920: json['image_1920'] as String?,
      active: json['active'] as bool? ?? true,
      comment: json['comment'] as String?,
      createDate: json['create_date'] as String?,
      writeDate: json['write_date'] as String?,
      createUid: json['create_uid'] != null
        ? RelationField.fromJson(json['create_uid'] as Map<String, dynamic>)
        : null,
      writeUid: json['write_uid'] != null
        ? RelationField.fromJson(json['write_uid'] as Map<String, dynamic>)
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      'is_company': isCompany,
      if (type != null) 'type': type,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (website != null) 'website': website,
      if (parentId != null) 'parent_id': parentId!.toJson(),
      if (childIds.isNotEmpty) 'child_ids': childIds.map((e) => e.toJson()).toList(),
      if (categoryId.isNotEmpty) 'category_id': categoryId.map((e) => e.toJson()).toList(),
      if (street != null) 'street': street,
      if (street2 != null) 'street2': street2,
      if (city != null) 'city': city,
      if (zip != null) 'zip': zip,
      if (stateId != null) 'state_id': stateId!.toJson(),
      if (countryId != null) 'country_id': countryId!.toJson(),
      if (function != null) 'function': function,
      if (vat != null) 'vat': vat,
      if (companyName != null) 'company_name': companyName,
      if (image128 != null) 'image_128': image128,
      if (image1920 != null) 'image_1920': image1920,
      'active': active,
      if (comment != null) 'comment': comment,
    };
  }
  
  /// For creating new contacts (excludes read-only fields, sends only IDs for relations)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name ?? '',
      'is_company': isCompany,
      if (type != null) 'type': type,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (website != null) 'website': website,
      if (parentId != null) 'parent_id': parentId!.id,
      if (categoryId.isNotEmpty) 'category_id': categoryId.map((e) => e.id).toList(),
      if (street != null) 'street': street,
      if (street2 != null) 'street2': street2,
      if (city != null) 'city': city,
      if (zip != null) 'zip': zip,
      if (stateId != null) 'state_id': stateId!.id,
      if (countryId != null) 'country_id': countryId!.id,
      if (function != null) 'function': function,
      if (vat != null) 'vat': vat,
      if (companyName != null) 'company_name': companyName,
      if (image1920 != null) 'image_1920': image1920,
      if (comment != null) 'comment': comment,
    };
  }
  
  /// For updating contacts (all fields optional, sends only IDs for relations)
  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (mobile != null) data['mobile'] = mobile;
    if (website != null) data['website'] = website;
    if (parentId != null) data['parent_id'] = parentId!.id;
    if (categoryId.isNotEmpty) data['category_id'] = categoryId.map((e) => e.id).toList();
    if (street != null) data['street'] = street;
    if (street2 != null) data['street2'] = street2;
    if (city != null) data['city'] = city;
    if (zip != null) data['zip'] = zip;
    if (stateId != null) data['state_id'] = stateId!.id;
    if (countryId != null) data['country_id'] = countryId!.id;
    if (function != null) data['function'] = function;
    if (vat != null) data['vat'] = vat;
    if (companyName != null) data['company_name'] = companyName;
    if (image1920 != null) data['image_1920'] = image1920;
    if (comment != null) data['comment'] = comment;
    data['active'] = active;
    return data;
  }
}

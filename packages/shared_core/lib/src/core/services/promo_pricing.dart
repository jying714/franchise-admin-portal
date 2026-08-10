import '../models/order.dart';
import '../models/promo.dart';

class PromoEvaluation {
  final bool ok;
  final String? reason;
  final double discountAmount;
  final double deliveryFeeAfter;
  final String summary;

  const PromoEvaluation({
    required this.ok,
    this.reason,
    required this.discountAmount,
    required this.deliveryFeeAfter,
    required this.summary,
  });

  factory PromoEvaluation.fail(String reason, {required double deliveryFee}) {
    return PromoEvaluation(
      ok: false,
      reason: reason,
      discountAmount: 0,
      deliveryFeeAfter: deliveryFee,
      summary: reason,
    );
  }
}

class PromoPricing {
  PromoPricing._();

  static PromoEvaluation evaluate({
    required Promo promo,
    required List<OrderItem> lines,
    required double subtotal,
    required double deliveryFee,
    DateTime? now,
    String channel = 'mobile',
  }) {
    final at = now ?? DateTime.now();
    final fee = deliveryFee < 0 ? 0.0 : deliveryFee;

    if (!promo.isLiveAt(at)) {
      return PromoEvaluation.fail('Promo is not active or outside its dates',
          deliveryFee: fee);
    }
    if (!promo.isAvailableOnChannel(channel)) {
      return PromoEvaluation.fail('Promo not available on this channel',
          deliveryFee: fee);
    }
    if (promo.minOrderValue > 0 && subtotal < promo.minOrderValue) {
      return PromoEvaluation.fail(
        'Minimum order \$${promo.minOrderValue.toStringAsFixed(2)}',
        deliveryFee: fee,
      );
    }

    final activeLines = lines.where((l) => l.isActive).toList();

    switch (PromoType.normalize(promo.type)) {
      case PromoType.percent:
      case PromoType.amount:
        return _cartOff(promo, activeLines, subtotal, fee);
      case PromoType.itemPercent:
      case PromoType.itemAmount:
        return _itemOff(promo, activeLines, subtotal, fee);
      case PromoType.bogo:
        return _bogo(promo, activeLines, subtotal, fee);
      case PromoType.freeItem:
        return _freeItem(promo, activeLines, subtotal, fee);
      case PromoType.delivery:
        return _delivery(promo, subtotal, fee);
      default:
        return PromoEvaluation.fail('Unsupported promo type', deliveryFee: fee);
    }
  }

  static double _roundMoney(double v) => (v * 100).roundToDouble() / 100.0;

  static bool _lineQualifies(Promo promo, OrderItem line) {
    if (!line.isActive) return false;
    final id = line.menuItemId;
    if (promo.excludeMenuItemIds.contains(id)) return false;

    final itemScope = promo.effectiveMenuItemIds;
    final catScope = promo.qualifyCategoryIds;
    // Category scope needs menu metadata at call site later; for now if only
    // category ids are set and no item ids, allow all non-excluded (engine
    // refined when Admin wires category→item). Prefer item scope when present.
    if (itemScope.isNotEmpty && !itemScope.contains(id)) {
      return false;
    }

    final sizes = promo.qualifySizeLabels
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (sizes.isNotEmpty) {
      final lineSize = _sizeOf(line).toLowerCase();
      if (lineSize.isEmpty || !sizes.contains(lineSize)) return false;
    }

    final minT = promo.qualifyMinToppings;
    final maxT = promo.qualifyMaxToppings;
    if (minT != null || maxT != null) {
      final n = _toppingCount(line);
      if (minT != null && n < minT) return false;
      if (maxT != null && n > maxT) return false;
    }
    return true;
  }

  static String _sizeOf(OrderItem line) {
    final s = (line.size ?? '').trim();
    if (s.isNotEmpty) return s;
    final c = line.customizations;
    for (final key in ['size', 'Size', 'SIZE', 'pizzaSize']) {
      final v = c[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  static int _toppingCount(OrderItem line) {
    final c = line.customizations;
    for (final key in [
      'toppings',
      'Toppings',
      'topping',
      'selectedToppings',
      'extras',
    ]) {
      final v = c[key];
      if (v is List) return v.length;
      if (v is Map) return v.length;
    }
    // Count list-valued customization entries as a fallback.
    var n = 0;
    for (final e in c.entries) {
      final k = e.key.toLowerCase();
      if (k.contains('topping') && e.value is List) {
        n += (e.value as List).length;
      }
    }
    return n;
  }

  static double _scopedSubtotal(Promo promo, List<OrderItem> lines) {
    final scoped = lines.where((l) => _lineQualifies(promo, l));
    var sum = 0.0;
    for (final l in scoped) {
      sum += l.effectiveLineTotal;
    }
    return sum;
  }

  static PromoEvaluation _cartOff(
    Promo promo,
    List<OrderItem> lines,
    double subtotal,
    double fee,
  ) {
    final hasScope = promo.effectiveMenuItemIds.isNotEmpty ||
        promo.qualifySizeLabels.isNotEmpty ||
        promo.qualifyMinToppings != null ||
        promo.qualifyCategoryIds.isNotEmpty;

    final base = hasScope ? _scopedSubtotal(promo, lines) : subtotal;
    if (base <= 0) {
      return PromoEvaluation.fail('No qualifying items in cart',
          deliveryFee: fee);
    }

    double raw;
    if (promo.isPercent) {
      raw = base * (promo.discount.clamp(0.0, 100.0) / 100.0);
    } else {
      raw = promo.discount;
    }
    if (raw > base) raw = base;
    final amt = _roundMoney(raw);
    if (amt <= 0) {
      return PromoEvaluation.fail('Discount is zero', deliveryFee: fee);
    }
    return PromoEvaluation(
      ok: true,
      discountAmount: amt,
      deliveryFeeAfter: fee,
      summary: promo.isPercent
          ? '${promo.discount.toStringAsFixed(0)}% off (−\$${amt.toStringAsFixed(2)})'
          : '\$${amt.toStringAsFixed(2)} off',
    );
  }

  static PromoEvaluation _itemOff(
    Promo promo,
    List<OrderItem> lines,
    double subtotal,
    double fee,
  ) {
    final base = _scopedSubtotal(promo, lines);
    if (base <= 0) {
      return PromoEvaluation.fail('No qualifying items in cart',
          deliveryFee: fee);
    }
    double raw;
    if (promo.isItemPercent) {
      raw = base * (promo.discount.clamp(0.0, 100.0) / 100.0);
    } else {
      raw = promo.discount;
    }
    if (raw > base) raw = base;
    final amt = _roundMoney(raw);
    if (amt <= 0) {
      return PromoEvaluation.fail('Discount is zero', deliveryFee: fee);
    }
    return PromoEvaluation(
      ok: true,
      discountAmount: amt,
      deliveryFeeAfter: fee,
      summary: promo.isItemPercent
          ? '${promo.discount.toStringAsFixed(0)}% off items (−\$${amt.toStringAsFixed(2)})'
          : '\$${amt.toStringAsFixed(2)} off items',
    );
  }

  static PromoEvaluation _bogo(
    Promo promo,
    List<OrderItem> lines,
    double subtotal,
    double fee,
  ) {
    final buy = promo.bogoBuyQty.clamp(1, 99);
    final get = promo.bogoGetQty.clamp(1, 99);
    final pct = promo.bogoGetDiscountPct.clamp(0.0, 100.0);
    final setSize = buy + get;

    // Expand to unit slots (one price per quantity unit).
    final slots = <_UnitSlot>[];
    for (final line in lines) {
      if (!_lineQualifies(promo, line)) continue;
      final unit = line.quantity > 0 ? (line.price) : 0.0;
      for (var i = 0; i < line.quantity; i++) {
        slots.add(_UnitSlot(
          menuItemId: line.menuItemId,
          unitPrice: unit,
        ));
      }
    }
    if (slots.length < setSize) {
      return PromoEvaluation.fail(
        'Add more qualifying items for this deal',
        deliveryFee: fee,
      );
    }

    final apply = BogoApplyTo.normalize(promo.bogoApplyTo);
    if (apply == BogoApplyTo.mostExpensive) {
      slots.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
    } else if (apply == BogoApplyTo.sameItem) {
      // Group by item; process each group with cheapest-within-group.
      slots.sort((a, b) {
        final byId = a.menuItemId.compareTo(b.menuItemId);
        if (byId != 0) return byId;
        return a.unitPrice.compareTo(b.unitPrice);
      });
    } else {
      slots.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
    }

    var discount = 0.0;
    if (apply == BogoApplyTo.sameItem) {
      final byItem = <String, List<_UnitSlot>>{};
      for (final s in slots) {
        byItem.putIfAbsent(s.menuItemId, () => <_UnitSlot>[]).add(s);
      }
      for (final group in byItem.values) {
        group.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        discount += _bogoDiscountOnSorted(group, buy, get, pct);
      }
    } else {
      // cheapest / most_expensive: after sort, take get units from end (cheapest
      // list: discount cheapest get units; expensive list: first get are highest).
      discount += _bogoDiscountOnSorted(slots, buy, get, pct);
    }

    final amt = _roundMoney(discount);
    if (amt <= 0) {
      return PromoEvaluation.fail('Deal did not produce a discount',
          deliveryFee: fee);
    }
    return PromoEvaluation(
      ok: true,
      discountAmount: amt,
      deliveryFeeAfter: fee,
      summary:
          'Buy $buy get $get at ${pct.toStringAsFixed(0)}% off (−\$${amt.toStringAsFixed(2)})',
    );
  }

  /// [sorted] cheapest-first: charge buy full, discount get from the cheap end.
  static double _bogoDiscountOnSorted(
    List<_UnitSlot> sorted,
    int buy,
    int get,
    double pct,
  ) {
    final setSize = buy + get;
    final sets = sorted.length ~/ setSize;
    if (sets <= 0) return 0.0;
    var discount = 0.0;
    // Take the cheapest `get * sets` units among those allocated to deals.
    // Allocate first `sets * setSize` units; within each set of setSize,
    // the lowest `get` prices (already sorted ascending) are discounted.
    for (var s = 0; s < sets; s++) {
      final start = s * setSize;
      final setUnits = sorted.sublist(start, start + setSize);
      // setUnits already global-sorted; first `get` are cheapest in this slice
      // only if whole list was cheapest-first. For most_expensive-first list,
      // discount the last `get` in the slice (cheaper within expensive ordering).
      final getUnits = setUnits.length >= get
          ? setUnits.sublist(setUnits.length - get)
          : setUnits;
      for (final u in getUnits) {
        discount += u.unitPrice * (pct / 100.0);
      }
    }
    return discount;
  }

  static PromoEvaluation _freeItem(
    Promo promo,
    List<OrderItem> lines,
    double subtotal,
    double fee,
  ) {
    final freeId = promo.freeMenuItemId?.trim() ?? '';
    if (freeId.isEmpty) {
      return PromoEvaluation.fail('Free item not configured', deliveryFee: fee);
    }
    OrderItem? match;
    for (final l in lines) {
      if (l.isActive && l.menuItemId == freeId) {
        match = l;
        break;
      }
    }
    if (match == null) {
      return PromoEvaluation.fail('Add the free item to your cart',
          deliveryFee: fee);
    }
    var amt = match.price;
    if (match.quantity > 1) {
      // One free unit only.
      amt = match.price;
    }
    final cap = promo.freeItemMaxPrice;
    if (cap != null && cap > 0 && amt > cap) amt = cap;
    amt = _roundMoney(amt);
    if (amt <= 0) {
      return PromoEvaluation.fail('Free item discount is zero',
          deliveryFee: fee);
    }
    return PromoEvaluation(
      ok: true,
      discountAmount: amt,
      deliveryFeeAfter: fee,
      summary: 'Free item (−\$${amt.toStringAsFixed(2)})',
    );
  }

  static PromoEvaluation _delivery(
    Promo promo,
    double subtotal,
    double fee,
  ) {
    if (fee <= 0) {
      return PromoEvaluation.fail('No delivery fee on this order',
          deliveryFee: fee);
    }
    final mode = DeliveryDiscountType.normalize(promo.deliveryDiscountType);
    double after = fee;
    double asDiscount = 0;
    switch (mode) {
      case DeliveryDiscountType.amount:
        final cut = promo.deliveryDiscountValue > 0
            ? promo.deliveryDiscountValue
            : promo.discount;
        after = (fee - cut).clamp(0.0, fee);
        asDiscount = _roundMoney(fee - after);
        break;
      case DeliveryDiscountType.percent:
        final pct = (promo.deliveryDiscountValue > 0
                ? promo.deliveryDiscountValue
                : promo.discount)
            .clamp(0.0, 100.0);
        after = _roundMoney(fee * (1 - pct / 100.0));
        asDiscount = _roundMoney(fee - after);
        break;
      case DeliveryDiscountType.free:
      default:
        after = 0;
        asDiscount = _roundMoney(fee);
        break;
    }
    return PromoEvaluation(
      ok: true,
      // Prefer lowering delivery fee; discountAmount documents savings for UI.
      discountAmount: 0,
      deliveryFeeAfter: after,
      summary: after <= 0
          ? 'Free delivery'
          : 'Delivery \$${after.toStringAsFixed(2)} (saved \$${asDiscount.toStringAsFixed(2)})',
    );
  }
}

class _UnitSlot {
  final String menuItemId;
  final double unitPrice;

  _UnitSlot({required this.menuItemId, required this.unitPrice});
}

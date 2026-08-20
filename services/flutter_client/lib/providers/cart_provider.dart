import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.productId == product.productId);

    if (existingIndex == -1) {
      state = state.copyWith(items: [...state.items, CartItem(product: product)]);
      return;
    }

    final updatedItems = [...state.items];
    final existing = updatedItems[existingIndex];
    updatedItems[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    state = state.copyWith(items: updatedItems);
  }

  void increment(String productId) {
    final updatedItems = [...state.items];
    final index = updatedItems.indexWhere((item) => item.product.productId == productId);
    if (index == -1) {
      return;
    }
    updatedItems[index] = updatedItems[index].copyWith(quantity: updatedItems[index].quantity + 1);
    state = state.copyWith(items: updatedItems);
  }

  void decrement(String productId) {
    final index = state.items.indexWhere((item) => item.product.productId == productId);
    if (index == -1) {
      return;
    }

    final existing = state.items[index];
    if (existing.quantity <= 1) {
      final updatedItems = [...state.items]..removeAt(index);
      state = state.copyWith(items: updatedItems);
      return;
    }

    final updatedItems = [...state.items];
    updatedItems[index] = existing.copyWith(quantity: existing.quantity - 1);
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    final updatedItems = state.items.where((item) => item.product.productId != productId).toList();
    state = state.copyWith(items: updatedItems);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

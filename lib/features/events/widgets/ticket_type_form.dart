import 'package:flutter/material.dart';

class TicketType {
  String name;
  double price;
  int quantity;

  TicketType({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class TicketTypeForm extends StatelessWidget {
  final int index;
  final TicketType ticket;
  final bool canDelete;
  final Function(int) onDelete;
  final Function(String) onNameChanged;
  final Function(double) onPriceChanged;
  final Function(int) onQuantityChanged;

  const TicketTypeForm({
    super.key,
    required this.index,
    required this.ticket,
    required this.canDelete,
    required this.onDelete,
    required this.onNameChanged,
    required this.onPriceChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket Type ${index + 1}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Ticket Name',
              hintText: 'e.g., VIP, General',
              border: OutlineInputBorder(),
            ),
            initialValue: ticket.name,
            onChanged: onNameChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter ticket name';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'Enter price',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  initialValue: ticket.price.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => onPriceChanged(double.tryParse(value) ?? 0.0),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Available tickets',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: ticket.quantity.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => onQuantityChanged(int.tryParse(value) ?? 0),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
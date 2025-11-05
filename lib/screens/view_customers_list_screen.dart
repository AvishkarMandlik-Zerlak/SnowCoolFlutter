
// import 'package:flutter/material.dart';
// import 'package:snow_trading_cool/screens/view_customer_screen.dart';
// import '../services/customer_api.dart';

// class ViewCustomersListScreen extends StatefulWidget {
//   const ViewCustomersListScreen({super.key});

//   @override
//   State<ViewCustomersListScreen> createState() => _ViewCustomersListScreenState();
// }

// class _ViewCustomersListScreenState extends State<ViewCustomersListScreen> {
//   List<CustomerDTO> _allCustomers = [
//     CustomerDTO(id: 1, name: 'John Doe', contactNumber: '1234567890', email: 'john.doe@example.com', address: '123 Main St'),
//     CustomerDTO(id: 2, name: 'Jane Smith', contactNumber: '0987654321', email: 'jane.smith@example.com', address: '456 Oak Ave'),
//     CustomerDTO(id: 3, name: 'Peter Jones', contactNumber: '1122334455', email: 'peter.jones@example.com', address: '789 Pine Ln'),
//     CustomerDTO(id: 4, name: 'Alice Brown', contactNumber: '5544332211', email: 'alice.brown@example.com', address: '101 Elm Rd'),
//   ];
//   List<CustomerDTO> _filteredCustomers = [];
//   final _searchController = TextEditingController();

//   void _filterCustomers(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredCustomers = _allCustomers;
//       } else {
//         _filteredCustomers = _allCustomers
//             .where((customer) =>
//                 customer.name.toLowerCase().contains(query.toLowerCase()) ||
//                 customer.contactNumber.contains(query))
//             .toList();
//       }
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     _filteredCustomers = _allCustomers; // Show all customers initially
//     _searchController.addListener(() {
//       _filterCustomers(_searchController.text);
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('View Customers'),
//         backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search for customers...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//               ),
//               onChanged: _filterCustomers,
//             ),
//           ),
//           Expanded(
//             child: _filteredCustomers.isEmpty
//                 ? const Center(child: Text('No customers found.'))
//                 : ListView.builder(
//                     itemCount: _filteredCustomers.length,
//                     itemBuilder: (context, index) {
//                       final customer = _filteredCustomers[index];
//                       return ListTile(
//                         title: Text(customer.name),
//                         subtitle: Text(customer.contactNumber),
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (_) => ViewCustomerScreen(
//                                 customerId: customer.id.toString(),
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {

  var paymentIntent = {};
  var item = 4;
  var totalAmount = 0;
  
  @override
  void initState() {
    totalAmount = item * 125;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, title: const Text('Proceed to payment'),
        actions: [
          IconButton(
            onPressed: () => addNewProduct(), 
            icon: const Icon(Icons.add)
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: item,
              itemBuilder: (context, index){
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        color: Colors.primaries[Random().nextInt(Colors.primaries.length)]
                      ),
                      const SizedBox(width: 20.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Product Name'),
                          SizedBox(height: 20.0),
                          Text('125')
                        ],
                      )
                    ],
                  ),
                );
              }
            ),
          ),
          const Divider(height: 1.0,thickness: 1.0,color: Colors.grey),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount'),
                    Text(totalAmount.toString())
                  ],
                ),
                const SizedBox(height: 15.0),
                SizedBox(
                  width: double.maxFinite,
                  child: ElevatedButton(
                    onPressed: () => makePayment(), 
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))
                    ),
                    child: const Text('Pay'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => makePayment(),
      //   child: const Icon(Icons.download),
      // ),
    );
  }

  void addNewProduct() {
    item+=1;
    totalAmount = 125 * item;
    update();
  }

  void update() => setState(() {});

  ///Make Payment Function
  Future<void> makePayment() async {
    try {
      //STEP 1: Create Payment Intent
      paymentIntent = await createPaymentIntent(totalAmount, 'INR');
      //STEP 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'], //Gotten from payment intent
          style: ThemeMode.light,
          merchantDisplayName: 'Ikay'
        )
      ).then((value) {});
      //STEP 3: Display Payment sheet
      displayPaymentSheet();
    } catch (err) {
      throw Exception(err);
    }
  }


  String calculateAmount(int amount){
    var convertAmount = amount * 100;
    return convertAmount.toString();
  }

  ///Create Payment Intent
  createPaymentIntent(int amount, String currency) async {
    try {
      //Request body
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
      };

      //Make post request to Stripe
      var response = await post(Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer sk_test_51I8QqEDfDl7qjSXOwm41JErAlflWOrpSoqx6rJS2PXAgxRwHNMOE5TOnhoyyBTeW4IrOm1NniG8JOWfjSaWuzcC000h6Y3VX8i',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }


  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        //clear payment intent after successful payment
        paymentIntent = {};
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on StripeException catch(e){
      debugPrint('Error is:--->$e');
    } catch (e) {
      debugPrint('$e');
    }
  }

}
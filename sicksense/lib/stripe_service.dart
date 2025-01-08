import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sick_sense_mobile/consts.dart';

// class StripeService {
//   StripeService._();

//   static final StripeService instance = StripeService._();

//   Future<void> makePayment() async {
//     try {
//       String? paymentIntentClientSecret = await _createPaymentIntent(
//         100,
//         "usd",
//       );
//       if (paymentIntentClientSecret == null) return;
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: paymentIntentClientSecret,
//           merchantDisplayName: "Hussain Mustafa",
//         ),
//       );
//       await _processPayment();
//     } catch (e) {
//       print(e);
//     }
//   }

//   Future<String?> _createPaymentIntent(int amount, String currency) async {
//     try {
//       final Dio dio = Dio();
//       Map<String, dynamic> data = {
//         "amount": _calculateAmount(
//           amount,
//         ),
//         "currency": currency,
//       };
//       var response = await dio.post(
//         "https://api.stripe.com/v1/payment_intents",
//         data: data,
//         options: Options(
//           contentType: Headers.formUrlEncodedContentType,
//           headers: {
//             "Authorization": "Bearer $stripeSecretKey",
//             "Content-Type": 'application/x-www-form-urlencoded'
//           },
//         ),
//       );
//       if (response.data != null) {
//         return response.data["client_secret"];
//       }
//       return null;
//     } catch (e) {
//       print(e);
//     }
//     return null;
//   }

//   Future<void> _processPayment() async {
//     try {
//       await Stripe.instance.presentPaymentSheet();
//       await Stripe.instance.confirmPaymentSheetPayment();
//     } catch (e) {
//       print(e);
//     }
//   }

//   String _calculateAmount(int amount) {
//     final calculatedAmount = amount * 100;
//     return calculatedAmount.toString();
//   }
// }
class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  Future<void> makePayment() async {
    try {
      // Create payment intent first
      String? paymentIntentClientSecret = await _createPaymentIntent(
        100, // Amount to charge (in smallest currency unit - cents)
        "usd",
      );

      if (paymentIntentClientSecret == null) {
        throw Exception('Failed to create payment intent');
      }

      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: "Sick Sense",
          paymentIntentClientSecret: paymentIntentClientSecret,
          //style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
                //background: Colors.blue,
                ),
          ),
        ),
      );

      // Show the payment sheet and confirm payment
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      print('Payment completed successfully');
    } catch (e) {
      if (e is StripeException) {
        print('Stripe error: ${e.error.localizedMessage}');
      } else {
        print('Payment error: $e');
      }
      rethrow; // Rethrow the error so we can handle it in the UI
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        options: Options(
          headers: {
            'Authorization': 'Bearer $stripeSecretKey',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
        ),
        data: {
          'amount': _calculateAmount(amount),
          'currency': currency,
          'payment_method_types[]': 'card'
        },
      );

      return response.data['client_secret'];
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  String _calculateAmount(int amount) {
    return (amount * 100).toString(); // Convert to cents
  }
}

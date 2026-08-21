# Loyalty and discounted booking contract

The Flutter client enforces this policy:

- Award `20` points once for each appointment after it reaches `completed`.
- Redeem exactly `40` points for one `30%` discount.
- A booking may redeem either `0` or `40` points; partial and stacked redemption is invalid.
- Money values are rounded to two decimal places.

## Preview

`POST /points/preview`

```json
{
  "doctor_id": 8,
  "points_to_redeem": 40
}
```

The response must contain values equivalent to:

```json
{
  "data": {
    "loyalty_active": true,
    "patient_points_balance": 40,
    "original_price": 1000.00,
    "points_redeemed": 40,
    "discount_percentage": 30.00,
    "discount_amount": 300.00,
    "final_price": 700.00
  }
}
```

The client blocks discounted booking if any of these values are inconsistent.

## Atomic server transaction

When the clinic approves a booking, the backend must lock the appointment,
patient points row, patient wallet, and doctor wallet, then perform one database
transaction:

1. Re-read the doctor's consultation price from the database.
2. Accept only `points_to_redeem` equal to `0` or `40`.
3. If `40`, verify the patient still has at least `40` points and calculate
   `final_price = round(original_price * 0.70, 2)`.
4. If `0`, use `final_price = original_price`.
5. Verify the patient wallet covers `final_price`.
6. Debit exactly `final_price` from the patient wallet.
7. Credit exactly `final_price` to the doctor wallet.
8. If discounted, debit exactly `40` points and create the redemption ledger
   entry linked to the appointment.
9. Persist `original_price`, `discount_percentage`, `discount_amount`,
   `final_price`, and `points_redeemed` on the appointment.
10. Commit all changes together or roll everything back.

The backend must ignore client-supplied price, discount, or transfer amounts.
Only `doctor_id`, appointment date/time, and `points_to_redeem` are client
inputs. Use a unique appointment/event key for wallet and points ledger entries
so retries cannot debit, credit, or award twice.

When the appointment first reaches `completed`, award `20` points in an
idempotent transaction. On cancellation/refund, reverse the exact paid amount
and restore redeemed points according to the product's cancellation policy.

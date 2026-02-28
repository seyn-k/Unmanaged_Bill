@EndUserText.label: 'Root View for Bill Header'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_BHDR_22AD119
  as select from zbhdr_22ad119 as Header
  composition [0..*] of ZI_BITM_22AD119 as _BillItems
{
  key bill_uuid as BillUuid,
  bill_number as BillNumber,
  customer_name as CustomerName,
  billing_date as BillingDate,
  @Semantics.amount.currencyCode: 'Currency'
  total_amount as TotalAmount,
  currency as Currency,
  payment_status as PaymentStatus,
  local_last_changed_at as LocalLastChangedAt,

  _BillItems
}

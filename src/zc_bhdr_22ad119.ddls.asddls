@EndUserText.label: 'Projection View for Bill Header'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_BHDR_22AD119
  provider contract transactional_query
  as projection on ZI_BHDR_22AD119
{
  key BillUuid,
  BillNumber,
  CustomerName,
  BillingDate,
  TotalAmount,
  Currency,
  PaymentStatus,

  /* Associations */
  _BillItems : redirected to composition child ZC_BITM_22AD119
}

@EndUserText.label: 'Projection View for Bill Items'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_BITM_22AD119
  as projection on ZI_BITM_22AD119
{
  key ItemUuid,
  BillUuid,
  ItemPosition,
  ProductId,
  Quantity,
  QuantityUnit,
  UnitPrice,
  Subtotal,
  Currency,

  /* Associations */
  _BillHeader : redirected to parent ZC_BHDR_22AD119
}

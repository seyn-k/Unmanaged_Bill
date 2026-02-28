CLASS lhc_header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Header RESULT result.

    METHODS create FOR MODIFY IMPORTING entities FOR CREATE Header.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Header.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Header.
    METHODS cba_Billitems FOR MODIFY IMPORTING entities_cba FOR CREATE Header\_Billitems.
    METHODS MarkAsPaid FOR MODIFY IMPORTING keys FOR ACTION Header~MarkAsPaid RESULT result.

    METHODS lock FOR LOCK IMPORTING keys FOR LOCK Header.

    " ---> ADDED: Read method for Header
    METHODS read FOR READ IMPORTING keys FOR READ Header RESULT result.
ENDCLASS.

CLASS lhc_header IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Leave empty for now. This tells the framework "allow all actions".
  ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(ls_entity).
       DATA(ls_hdr) = CORRESPONDING zbhdr_22ad119( ls_entity MAPPING FROM ENTITY ).
       " Framework auto-generates the UUID now, so we just pass it from the entity
       ls_hdr-bill_uuid = ls_entity-BillUuid.

       zutil_22ad119=>get_instance( )->buffer_hdr( ls_hdr ).
       INSERT VALUE #( %cid = ls_entity-%cid BillUuid = ls_hdr-bill_uuid ) INTO TABLE mapped-header.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    DATA ls_hdr TYPE zbhdr_22ad119.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zbhdr_22ad119 WHERE bill_uuid = @ls_entity-BillUuid INTO @ls_hdr.
      IF ls_entity-%control-CustomerName = if_abap_behv=>mk-on. ls_hdr-customer_name = ls_entity-CustomerName. ENDIF.
      IF ls_entity-%control-PaymentStatus = if_abap_behv=>mk-on. ls_hdr-payment_status = ls_entity-PaymentStatus. ENDIF.
      zutil_22ad119=>get_instance( )->buffer_hdr( ls_hdr ).
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      zutil_22ad119=>get_instance( )->buffer_del_hdr( ls_key-BillUuid ).
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Billitems.
    DATA ls_itm TYPE zbitm_22ad119.
    LOOP AT entities_cba INTO DATA(ls_cba_entity).
      LOOP AT ls_cba_entity-%target INTO DATA(ls_target).
        ls_itm = CORRESPONDING #( ls_target MAPPING FROM ENTITY ).

        " Framework auto-generates the item UUID now
        ls_itm-item_uuid = ls_target-ItemUuid.
        ls_itm-bill_uuid = ls_cba_entity-BillUuid.

        zutil_22ad119=>get_instance( )->buffer_itm( ls_itm ).
        INSERT VALUE #( %cid = ls_target-%cid ItemUuid = ls_itm-item_uuid ) INTO TABLE mapped-item.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD MarkAsPaid.
    DATA ls_hdr TYPE zbhdr_22ad119.
    LOOP AT keys INTO DATA(ls_key).
      " Fetch the current record
      SELECT SINGLE * FROM zbhdr_22ad119 WHERE bill_uuid = @ls_key-BillUuid INTO @ls_hdr.

      " Update the status
      ls_hdr-payment_status = 'Paid'.

      " Send updated record to the buffer
      zutil_22ad119=>get_instance( )->buffer_hdr( ls_hdr ).
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    LOOP AT keys INTO DATA(ls_key).
      " Check if the record actually exists before trying to lock
      SELECT SINGLE bill_uuid FROM zbhdr_22ad119
        WHERE bill_uuid = @ls_key-BillUuid
        INTO @DATA(lv_dummy).

      IF sy-subrc <> 0.
        " Explicitly map the BillUuid instead of using %key
        APPEND VALUE #( BillUuid = ls_key-BillUuid ) TO failed-header.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " ---> ADDED: Read implementation for Header
  METHOD read.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zbhdr_22ad119 WHERE bill_uuid = @ls_key-BillUuid INTO @DATA(ls_db).
      IF sy-subrc = 0.
        INSERT CORRESPONDING #( ls_db ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Item.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Item.
    METHODS calculateSubtotal FOR DETERMINE ON MODIFY IMPORTING keys FOR Item~calculateSubtotal.
    METHODS validateQuantity FOR VALIDATE ON SAVE IMPORTING keys FOR Item~validateQuantity.

    " ---> ADDED: Read method for Item
    METHODS read FOR READ IMPORTING keys FOR READ Item RESULT result.
ENDCLASS.

CLASS lhc_item IMPLEMENTATION.
  METHOD update.
    DATA ls_itm TYPE zbitm_22ad119.
    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zbitm_22ad119 WHERE item_uuid = @ls_entity-ItemUuid INTO @ls_itm.
      IF ls_entity-%control-Quantity = if_abap_behv=>mk-on. ls_itm-quantity = ls_entity-Quantity. ENDIF.
      IF ls_entity-%control-UnitPrice = if_abap_behv=>mk-on. ls_itm-unit_price = ls_entity-UnitPrice. ENDIF.
      zutil_22ad119=>get_instance( )->buffer_itm( ls_itm ).
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      zutil_22ad119=>get_instance( )->buffer_del_itm( ls_key-ItemUuid ).
    ENDLOOP.
  ENDMETHOD.

  METHOD calculateSubtotal.
    DATA ls_itm TYPE zbitm_22ad119.
    LOOP AT keys INTO DATA(ls_key).
      " Read the item data
      SELECT SINGLE * FROM zbitm_22ad119 WHERE item_uuid = @ls_key-ItemUuid INTO @ls_itm.

      " Calculate subtotal
      ls_itm-subtotal = ls_itm-quantity * ls_itm-unit_price.

      " Push to buffer
      zutil_22ad119=>get_instance( )->buffer_itm( ls_itm ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validateQuantity.
    DATA ls_itm TYPE zbitm_22ad119.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zbitm_22ad119 WHERE item_uuid = @ls_key-ItemUuid INTO @ls_itm.

      " Check if quantity is valid
      IF ls_itm-quantity <= 0.
        " ---> FIXED: Explicitly map ItemUuid instead of %key
        APPEND VALUE #( ItemUuid = ls_key-ItemUuid ) TO failed-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " ---> ADDED: Read implementation for Item
  METHOD read.
    LOOP AT keys INTO DATA(ls_key).
      SELECT SINGLE * FROM zbitm_22ad119 WHERE item_uuid = @ls_key-ItemUuid INTO @DATA(ls_db).
      IF sy-subrc = 0.
        INSERT CORRESPONDING #( ls_db ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zbp_bhdr_22ad119 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_zbp_bhdr_22ad119 IMPLEMENTATION.
  METHOD save.
    DATA(lt_hdr) = zutil_22ad119=>get_instance( )->get_buffered_hdr( ).
    IF lt_hdr IS NOT INITIAL. MODIFY zbhdr_22ad119 FROM TABLE @lt_hdr. ENDIF.

    DATA(lt_itm) = zutil_22ad119=>get_instance( )->get_buffered_itm( ).
    IF lt_itm IS NOT INITIAL. MODIFY zbitm_22ad119 FROM TABLE @lt_itm. ENDIF.

    DATA(lt_del_hdr) = zutil_22ad119=>get_instance( )->get_del_hdr( ).
    IF lt_del_hdr IS NOT INITIAL.
      LOOP AT lt_del_hdr INTO DATA(ls_del_hdr).
        DELETE FROM zbhdr_22ad119 WHERE bill_uuid = @ls_del_hdr-bill_uuid.
        DELETE FROM zbitm_22ad119 WHERE bill_uuid = @ls_del_hdr-bill_uuid.
      ENDLOOP.
    ENDIF.

    DATA(lt_del_itm) = zutil_22ad119=>get_instance( )->get_del_itm( ).
    IF lt_del_itm IS NOT INITIAL.
      LOOP AT lt_del_itm INTO DATA(ls_del_itm).
        DELETE FROM zbitm_22ad119 WHERE item_uuid = @ls_del_itm-item_uuid.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    zutil_22ad119=>get_instance( )->clear_buffer( ).
  ENDMETHOD.
ENDCLASS.
